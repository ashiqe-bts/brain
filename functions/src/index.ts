import {createHash, randomBytes} from "node:crypto";
import {getAuth} from "firebase-admin/auth";
import {FieldPath, FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {initializeApp} from "firebase-admin/app";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {setGlobalOptions} from "firebase-functions/v2/options";
import {mergeProgressState} from "./merge.js";

initializeApp();
setGlobalOptions({region: "asia-south1", maxInstances: 10});

const db = getFirestore();
const tokenHash = (token: string): string =>
  createHash("sha256").update(token).digest("hex");

export const prepareGuestTransfer = onCall(
  {enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    const provider = request.auth?.token.firebase?.sign_in_provider;
    if (!uid || provider !== "anonymous") {
      throw new HttpsError("failed-precondition", "An anonymous session is required.");
    }
    const token = randomBytes(32).toString("base64url");
    await db.collection("guestTransfers").doc(tokenHash(token)).set({
      sourceUid: uid,
      createdAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(Date.now() + 10 * 60 * 1000),
      status: "prepared",
    });
    return {token};
  },
);

export const completeGuestTransfer = onCall(
  {enforceAppCheck: true, timeoutSeconds: 540},
  async (request) => {
    const targetUid = request.auth?.uid;
    const provider = request.auth?.token.firebase?.sign_in_provider;
    const token = request.data?.token;
    if (!targetUid || provider === "anonymous") {
      throw new HttpsError("unauthenticated", "A permanent account is required.");
    }
    if (typeof token !== "string" || token.length < 32) {
      throw new HttpsError("invalid-argument", "A valid transfer token is required.");
    }
    const transferRef = db.collection("guestTransfers").doc(tokenHash(token));
    const sourceUid = await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(transferRef);
      if (!snapshot.exists) throw new HttpsError("not-found", "Transfer expired.");
      const transfer = snapshot.data()!;
      if ((transfer.expiresAt as Timestamp).toMillis() < Date.now()) {
        throw new HttpsError("deadline-exceeded", "Transfer expired.");
      }
      if (transfer.status === "complete" && transfer.targetUid === targetUid) {
        return transfer.sourceUid as string;
      }
      if (transfer.status !== "prepared" && transfer.targetUid !== targetUid) {
        throw new HttpsError("already-exists", "Transfer already claimed.");
      }
      transaction.update(transferRef, {status: "processing", targetUid});
      return transfer.sourceUid as string;
    });

    if (sourceUid === targetUid) return {status: "complete"};
    const source = db.collection("users").doc(sourceUid);
    const target = db.collection("users").doc(targetUid);
    await copyCollection(source.collection("sessions"), target.collection("sessions"));
    await copyDaily(source.collection("daily"), target.collection("daily"));
    const [sourceState, targetState] = await Promise.all([
      source.collection("state").doc("current").get(),
      target.collection("state").doc("current").get(),
    ]);
    if (sourceState.exists || targetState.exists) {
      await target.collection("state").doc("current").set({
        ...mergeProgressState(sourceState.data() ?? {}, targetState.data() ?? {}),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    const [sourceProfile, targetProfile] = await Promise.all([source.get(), target.get()]);
    if (sourceProfile.exists) {
      await target.set({
        ...sourceProfile.data(),
        ...targetProfile.data(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    }
    await db.recursiveDelete(source);
    await getAuth().deleteUser(sourceUid).catch(() => undefined);
    await transferRef.set({status: "complete", completedAt: FieldValue.serverTimestamp()}, {merge: true});
    return {status: "complete"};
  },
);

export const deleteAccount = onCall(
  {enforceAppCheck: true, timeoutSeconds: 120},
  async (request) => {
    const uid = request.auth?.uid;
    const authTime = Number(request.auth?.token.auth_time ?? 0) * 1000;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in first.");
    if (Date.now() - authTime > 5 * 60 * 1000) {
      throw new HttpsError("failed-precondition", "Recent sign-in required.");
    }
    await db.recursiveDelete(db.collection("users").doc(uid));
    await getAuth().deleteUser(uid);
    return {status: "deleted"};
  },
);

async function copyCollection(
  source: FirebaseFirestore.CollectionReference,
  target: FirebaseFirestore.CollectionReference,
): Promise<void> {
  let lastDocument: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  do {
    let query = source.orderBy(FieldPath.documentId()).limit(400);
    if (lastDocument) query = query.startAfter(lastDocument);
    const snapshot = await query.get();
    if (snapshot.empty) return;
    const batch = db.batch();
    snapshot.docs.forEach((document) => {
      batch.set(target.doc(document.id), document.data(), {merge: true});
    });
    await batch.commit();
    lastDocument = snapshot.docs.at(-1);
  } while (lastDocument);
}

async function copyDaily(
  source: FirebaseFirestore.CollectionReference,
  target: FirebaseFirestore.CollectionReference,
): Promise<void> {
  let lastDocument: FirebaseFirestore.QueryDocumentSnapshot | undefined;
  do {
    let query = source.orderBy(FieldPath.documentId()).limit(200);
    if (lastDocument) query = query.startAfter(lastDocument);
    const snapshot = await query.get();
    if (snapshot.empty) return;
    for (const sourceDoc of snapshot.docs) {
      const targetRef = target.doc(sourceDoc.id);
      await db.runTransaction(async (transaction) => {
        const targetDoc = await transaction.get(targetRef);
        const sourceResults = sourceDoc.data().results;
        const sourceCount = Array.isArray(sourceResults) ? sourceResults.length : 0;
        const targetResults = targetDoc.data()?.results;
        const targetCount = Array.isArray(targetResults) ? targetResults.length : 0;
        if (!targetDoc.exists || sourceCount > targetCount) {
          transaction.set(targetRef, sourceDoc.data());
        }
      });
    }
    lastDocument = snapshot.docs.at(-1);
  } while (lastDocument);
}

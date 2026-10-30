import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import test, {after, before} from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {doc, getDoc, setDoc, serverTimestamp} from "firebase/firestore";

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-brainflex",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8"),
    },
  });
});

after(async () => environment.cleanup());

test("a user can write valid progress only below their own uid", async () => {
  const owner = environment.authenticatedContext("owner").firestore();
  const other = environment.authenticatedContext("other").firestore();
  const progress = doc(owner, "users/owner/state/current");
  const data = {
    schemaVersion: 1,
    onboarded: true,
    displayName: "Asha",
    xp: 10,
    level: 1,
    currentStreak: 1,
    longestStreak: 1,
    lastCompletedDate: "2026-10-06",
    workouts: 1,
    difficulties: {},
    missions: [],
    achievements: [],
    completedTutorials: [],
    draft: null,
    lastMissionDate: "2026-10-06",
    revision: 1,
    updatedAt: serverTimestamp(),
  };
  await assertSucceeds(setDoc(progress, data));
  await assertSucceeds(getDoc(progress));
  await assertFails(getDoc(doc(other, "users/owner/state/current")));
});

test("unmatched and transfer documents remain private", async () => {
  const owner = environment.authenticatedContext("owner").firestore();
  await assertFails(setDoc(doc(owner, "guestTransfers/token"), {sourceUid: "owner"}));
  await assertFails(setDoc(doc(owner, "public/value"), {open: true}));
  assert.ok(true);
});

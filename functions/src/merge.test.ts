import assert from "node:assert/strict";
import test from "node:test";
import {mergeProgressState} from "./merge.js";

test("progress merge preserves both sets and maximum participation values", () => {
  const merged = mergeProgressState(
    {displayName: "Guest", xp: 90, level: 2, achievements: ["starter"]},
    {displayName: "Account", xp: 40, level: 3, achievements: ["steady"]},
  );
  assert.equal(merged.displayName, "Account");
  assert.equal(merged.xp, 90);
  assert.equal(merged.level, 3);
  assert.deepEqual(new Set(merged.achievements as string[]), new Set(["starter", "steady"]));
});

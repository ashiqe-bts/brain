export type ProgressState = Record<string, unknown>;

const numberValue = (value: unknown): number =>
  typeof value === "number" ? value : 0;

const stringSet = (value: unknown): Set<string> =>
  new Set(Array.isArray(value) ? value.filter((item): item is string => typeof item === "string") : []);

export function mergeProgressState(
  source: ProgressState,
  target: ProgressState,
): ProgressState {
  const achievements = stringSet(target.achievements);
  stringSet(source.achievements).forEach((item) => achievements.add(item));
  const tutorials = stringSet(target.completedTutorials);
  stringSet(source.completedTutorials).forEach((item) => tutorials.add(item));
  const targetName = typeof target.displayName === "string" && target.displayName.trim() !== ""
    ? target.displayName
    : source.displayName ?? null;

  return {
    ...source,
    ...target,
    schemaVersion: 1,
    displayName: targetName,
    onboarded: Boolean(source.onboarded) || Boolean(target.onboarded),
    xp: Math.max(numberValue(source.xp), numberValue(target.xp)),
    level: Math.max(numberValue(source.level), numberValue(target.level)),
    achievements: [...achievements],
    completedTutorials: [...tutorials],
  };
}

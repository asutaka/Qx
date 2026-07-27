/**
 * Enum defining Open Trivia Database (OTDB) difficulty levels.
 * For TypeScript frontend/backend use.
 */
export enum TriviaDifficulty {
  ANY = "any",
  EASY = "easy",
  MEDIUM = "medium",
  HARD = "hard"
}

/**
 * Mapping of TriviaDifficulty enum to human-readable names.
 */
export const TriviaDifficultyNames: Record<TriviaDifficulty, string> = {
  [TriviaDifficulty.ANY]: "Any Difficulty",
  [TriviaDifficulty.EASY]: "Easy",
  [TriviaDifficulty.MEDIUM]: "Medium",
  [TriviaDifficulty.HARD]: "Hard"
};

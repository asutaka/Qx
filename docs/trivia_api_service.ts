import { TriviaCategory } from './trivia_category';
import { TriviaDifficulty } from './trivia_difficulty';

/**
 * Service to handle requests to Open Trivia Database (OTDB).
 * For TypeScript frontend/backend use.
 */
export class TriviaApiService {
  private static readonly BASE_URL = 'https://opentdb.com/api.php';

  /**
   * Helper method to build the target URL with query parameters.
   */
  public static buildUrl(
    amount: number,
    category: TriviaCategory,
    difficulty: TriviaDifficulty
  ): string {
    const url = new URL(this.BASE_URL);
    url.searchParams.append('amount', amount.toString());
    url.searchParams.append('type', 'multiple'); // Constant multiple choice type

    if (category !== TriviaCategory.ANY) {
      url.searchParams.append('category', category);
    }

    if (difficulty !== TriviaDifficulty.ANY) {
      url.searchParams.append('difficulty', difficulty);
    }

    return url.toString();
  }

  /**
   * Fetches trivia questions from the API.
   * Returns parsed JSON data or null if an error occurs.
   */
  public async fetchQuestions(
    amount: number,
    category: TriviaCategory,
    difficulty: TriviaDifficulty
  ): Promise<any> {
    try {
      const url = TriviaApiService.buildUrl(amount, category, difficulty);
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Exception during fetchQuestions:', error);
      return null;
    }
  }
}

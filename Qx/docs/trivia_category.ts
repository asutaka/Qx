/**
 * Enum defining Open Trivia Database (OTDB) categories.
 * For TypeScript frontend/backend use.
 */
export enum TriviaCategory {
  ANY = "any",
  GENERAL_KNOWLEDGE = "9",
  ENTERTAINMENT_BOOKS = "10",
  ENTERTAINMENT_FILM = "11",
  ENTERTAINMENT_MUSIC = "12",
  ENTERTAINMENT_MUSICALS_THEATRES = "13",
  ENTERTAINMENT_TELEVISION = "14",
  ENTERTAINMENT_VIDEO_GAMES = "15",
  ENTERTAINMENT_BOARD_GAMES = "16",
  SCIENCE_NATURE = "17",
  SCIENCE_COMPUTERS = "18",
  SCIENCE_MATHEMATICS = "19",
  MYTHOLOGY = "20",
  SPORTS = "21",
  GEOGRAPHY = "22",
  HISTORY = "23",
  POLITICS = "24",
  ART = "25",
  CELEBRITIES = "26",
  ANIMALS = "27",
  VEHICLES = "28",
  ENTERTAINMENT_COMICS = "29",
  SCIENCE_GADGETS = "30",
  ENTERTAINMENT_ANIME_MANGA = "31",
  ENTERTAINMENT_CARTOON_ANIMATIONS = "32"
}

/**
 * Mapping of TriviaCategory enum to human-readable names.
 */
export const TriviaCategoryNames: Record<TriviaCategory, string> = {
  [TriviaCategory.ANY]: "Any Category",
  [TriviaCategory.GENERAL_KNOWLEDGE]: "General Knowledge",
  [TriviaCategory.ENTERTAINMENT_BOOKS]: "Entertainment: Books",
  [TriviaCategory.ENTERTAINMENT_FILM]: "Entertainment: Film",
  [TriviaCategory.ENTERTAINMENT_MUSIC]: "Entertainment: Music",
  [TriviaCategory.ENTERTAINMENT_MUSICALS_THEATRES]: "Entertainment: Musicals & Theatres",
  [TriviaCategory.ENTERTAINMENT_TELEVISION]: "Entertainment: Television",
  [TriviaCategory.ENTERTAINMENT_VIDEO_GAMES]: "Entertainment: Video Games",
  [TriviaCategory.ENTERTAINMENT_BOARD_GAMES]: "Entertainment: Board Games",
  [TriviaCategory.SCIENCE_NATURE]: "Science & Nature",
  [TriviaCategory.SCIENCE_COMPUTERS]: "Science: Computers",
  [TriviaCategory.SCIENCE_MATHEMATICS]: "Science: Mathematics",
  [TriviaCategory.MYTHOLOGY]: "Mythology",
  [TriviaCategory.SPORTS]: "Sports",
  [TriviaCategory.GEOGRAPHY]: "Geography",
  [TriviaCategory.HISTORY]: "History",
  [TriviaCategory.POLITICS]: "Politics",
  [TriviaCategory.ART]: "Art",
  [TriviaCategory.CELEBRITIES]: "Celebrities",
  [TriviaCategory.ANIMALS]: "Animals",
  [TriviaCategory.VEHICLES]: "Vehicles",
  [TriviaCategory.ENTERTAINMENT_COMICS]: "Entertainment: Comics",
  [TriviaCategory.SCIENCE_GADGETS]: "Science: Gadgets",
  [TriviaCategory.ENTERTAINMENT_ANIME_MANGA]: "Entertainment: Japanese Anime & Manga",
  [TriviaCategory.ENTERTAINMENT_CARTOON_ANIMATIONS]: "Entertainment: Cartoon & Animations"
};

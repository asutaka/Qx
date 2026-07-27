/// Enum định nghĩa các danh mục câu hỏi của Open Trivia Database (OTDB).
/// Sử dụng cho ứng dụng di động Flutter.
enum TriviaCategory {
  any(value: 'any', displayName: 'Any Category'),
  generalKnowledge(value: '9', displayName: 'General Knowledge'),
  entertainmentBooks(value: '10', displayName: 'Entertainment: Books'),
  entertainmentFilm(value: '11', displayName: 'Entertainment: Film'),
  entertainmentMusic(value: '12', displayName: 'Entertainment: Music'),
  entertainmentMusicalsTheatres(value: '13', displayName: 'Entertainment: Musicals & Theatres'),
  entertainmentTelevision(value: '14', displayName: 'Entertainment: Television'),
  entertainmentVideoGames(value: '15', displayName: 'Entertainment: Video Games'),
  entertainmentBoardGames(value: '16', displayName: 'Entertainment: Board Games'),
  scienceNature(value: '17', displayName: 'Science & Nature'),
  scienceComputers(value: '18', displayName: 'Science: Computers'),
  scienceMathematics(value: '19', displayName: 'Science: Mathematics'),
  mythology(value: '20', displayName: 'Mythology'),
  sports(value: '21', displayName: 'Sports'),
  geography(value: '22', displayName: 'Geography'),
  history(value: '23', displayName: 'History'),
  politics(value: '24', displayName: 'Politics'),
  art(value: '25', displayName: 'Art'),
  celebrities(value: '26', displayName: 'Celebrities'),
  animals(value: '27', displayName: 'Animals'),
  vehicles(value: '28', displayName: 'Vehicles'),
  entertainmentComics(value: '29', displayName: 'Entertainment: Comics'),
  scienceGadgets(value: '30', displayName: 'Science: Gadgets'),
  entertainmentAnimeManga(value: '31', displayName: 'Entertainment: Japanese Anime & Manga'),
  entertainmentCartoonAnimations(value: '32', displayName: 'Entertainment: Cartoon & Animations');

  final String value;
  final String displayName;

  const TriviaCategory({required this.value, required this.displayName});

  /// Tìm kiếm danh mục từ giá trị API String nhận được.
  /// Trả về [TriviaCategory.any] nếu không tìm thấy.
  static TriviaCategory fromValue(String val) {
    return TriviaCategory.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TriviaCategory.any,
    );
  }
}

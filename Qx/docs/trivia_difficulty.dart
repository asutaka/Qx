/// Enum định nghĩa mức độ khó của Open Trivia Database (OTDB).
/// Sử dụng cho ứng dụng di động Flutter.
enum TriviaDifficulty {
  any(value: 'any', displayName: 'Any Difficulty'),
  easy(value: 'easy', displayName: 'Easy'),
  medium(value: 'medium', displayName: 'Medium'),
  hard(value: 'hard', displayName: 'Hard');

  final String value;
  final String displayName;

  const TriviaDifficulty({required this.value, required this.displayName});

  /// Tìm kiếm độ khó từ giá trị API String nhận được.
  /// Trả về [TriviaDifficulty.any] nếu không tìm thấy.
  static TriviaDifficulty fromValue(String val) {
    return TriviaDifficulty.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TriviaDifficulty.any,
    );
  }
}

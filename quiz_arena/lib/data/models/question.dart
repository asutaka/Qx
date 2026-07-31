class Question {
  final String questionText;
  final String correctAnswer;
  final List<String> allAnswers;
  final String category;

  Question({
    required this.questionText,
    required this.correctAnswer,
    required this.allAnswers,
    this.category = '',
  });

  /// Gán dữ liệu từ JSON API của OTDB và tự động giải mã HTML entities.
  factory Question.fromJson(Map<String, dynamic> json) {
    String decodeHtml(String input) {
      return input
          .replaceAll('&quot;', '"')
          .replaceAll('&#039;', "'")
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&deg;', '°')
          .replaceAll('&rsquo;', "'")
          .replaceAll('&lsquo;', "'")
          .replaceAll('&ldquo;', '"')
          .replaceAll('&rdquo;', '"')
          .replaceAll('&ndash;', '-')
          .replaceAll('&mdash;', '-')
          .replaceAll('&eacute;', 'é')
          .replaceAll('&aacute;', 'á')
          .replaceAll('&iacute;', 'í')
          .replaceAll('&oacute;', 'ó')
          .replaceAll('&uacute;', 'ú');
    }

    final questionText = decodeHtml(json['question'] ?? '');
    final correctAnswer = decodeHtml(json['correct_answer'] ?? '');
    final incorrectAnswers = (json['incorrect_answers'] as List<dynamic>?)
            ?.map((e) => decodeHtml(e.toString()))
            .toList() ??
        [];
    final category = json['category'] ?? '';

    // Trộn ngẫu nhiên câu trả lời đúng vào danh sách câu trả lời sai
    final allAnswers = List<String>.from(incorrectAnswers);
    allAnswers.add(correctAnswer);
    allAnswers.shuffle();

    return Question(
      questionText: questionText,
      correctAnswer: correctAnswer,
      allAnswers: allAnswers,
      category: category,
    );
  }
}

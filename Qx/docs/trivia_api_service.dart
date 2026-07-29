import 'dart:convert';
import 'package:http/http.dart' as http;
import 'trivia_category.dart';
import 'trivia_difficulty.dart';

/// Service quản lý kết nối và lấy dữ liệu từ Open Trivia Database (OTDB).
class TriviaApiService {
  static const String _baseUrl = 'https://opentdb.com/api.php';

  /// Tạo Uri hoàn chỉnh để gọi API dựa trên cấu hình truyền vào.
  static Uri buildUri({
    required int amount,
    required TriviaCategory category,
    required TriviaDifficulty difficulty,
  }) {
    final queryParameters = <String, String>{
      'amount': amount.toString(),
      'type': 'multiple', // Loại câu hỏi trắc nghiệm nhiều đáp án (bất biến)
    };

    // Nếu chọn category cụ thể (khác any), truyền tham số category số tương ứng
    if (category != TriviaCategory.any) {
      queryParameters['category'] = category.value;
    }

    // Nếu chọn độ khó cụ thể (khác any), truyền tham số difficulty tương ứng
    if (difficulty != TriviaDifficulty.any) {
      queryParameters['difficulty'] = difficulty.value;
    }

    return Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
  }

  /// Gọi API lấy dữ liệu câu hỏi.
  /// Trả về `Map<String, dynamic>` chứa cấu trúc JSON từ OTDB hoặc `null` nếu lỗi.
  Future<Map<String, dynamic>?> fetchQuestions({
    required int amount,
    required TriviaCategory category,
    required TriviaDifficulty difficulty,
  }) async {
    try {
      final uri = buildUri(
        amount: amount,
        category: category,
        difficulty: difficulty,
      );
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Error calling OTDB API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception during fetchQuestions: $e');
      return null;
    }
  }
}

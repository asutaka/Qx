import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/trivia_category.dart';
import '../models/trivia_difficulty.dart';

/// Service quản lý kết nối và lấy dữ liệu từ Open Trivia Database (OTDB) với Local Asset Fallback.
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

    if (category != TriviaCategory.any) {
      queryParameters['category'] = category.value;
    }

    if (difficulty != TriviaDifficulty.any) {
      queryParameters['difficulty'] = difficulty.value;
    }

    return Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
  }

  /// Gọi API lấy dữ liệu câu hỏi. Nối kết nối lỗi hoặc quá hạn 4s sẽ nạp từ file JSON dự phòng.
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
      
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final results = decoded['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return decoded;
        }
      }
      print('OTDB API trả về kết quả rỗng hoặc mã lỗi: ${response.statusCode}. Chuyển sang Local Fallback.');
    } catch (e) {
      print('Ngoại lệ gọi OTDB API: $e. Đang nạp ngân hàng câu hỏi local fallback...');
    }

    // Nạp câu hỏi từ file JSON local dự phòng
    return await _loadLocalFallbackQuestions();
  }

  /// Nạp danh sách câu hỏi dự phòng offline từ file JSON asset
  Future<Map<String, dynamic>?> _loadLocalFallbackQuestions() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/questions/fallback_questions.json');
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print("Lỗi nạp local fallback questions: $e");
      return null;
    }
  }
}

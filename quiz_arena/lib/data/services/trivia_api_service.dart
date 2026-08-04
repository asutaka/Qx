import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/trivia_category.dart';
import '../models/trivia_difficulty.dart';

/// Service quản lý kết nối và lấy dữ liệu câu hỏi với kiến trúc 3 Tầng Dự Phòng (Triple Fallback Architecture):
/// 1. OpenTDB API (opentdb.com)
/// 2. The Trivia API (the-trivia-api.com)
/// 3. Offline Local JSON Asset (fallback_questions.json)
class TriviaApiService {
  static const String _opentdbUrl = 'https://opentdb.com/api.php';
  static const String _theTriviaApiUrl = 'https://the-trivia-api.com/v2/questions';

  /// Tạo Uri gọi OpenTDB API
  static Uri _buildOpenTdbUri({
    required int amount,
    required TriviaCategory category,
    required TriviaDifficulty difficulty,
  }) {
    final queryParameters = <String, String>{
      'amount': amount.toString(),
      'type': 'multiple',
    };

    if (category != TriviaCategory.any) {
      queryParameters['category'] = category.value;
    }

    if (difficulty != TriviaDifficulty.any) {
      queryParameters['difficulty'] = difficulty.value;
    }

    return Uri.parse(_opentdbUrl).replace(queryParameters: queryParameters);
  }

  /// Gọi API lấy dữ liệu câu hỏi theo thứ tự ưu tiên 3 tầng
  Future<Map<String, dynamic>?> fetchQuestions({
    required int amount,
    required TriviaCategory category,
    required TriviaDifficulty difficulty,
  }) async {
    // 1. Tầng 1: OpenTDB API
    try {
      final uri = _buildOpenTdbUri(
        amount: amount,
        category: category,
        difficulty: difficulty,
      );
      
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final results = decoded['results'] as List?;
        if (results != null && results.isNotEmpty) {
          print('✅ Lấy thành công ${results.length} câu hỏi từ Tầng 1 (OpenTDB API)');
          return decoded;
        }
      }
      print('⚠️ OpenTDB API trả về kết quả rỗng. Thử chuyển sang Tầng 2 (The Trivia API)...');
    } catch (e) {
      print('⚠️ Lỗi gọi OpenTDB API ($e). Thử chuyển sang Tầng 2 (The Trivia API)...');
    }

    // 2. Tầng 2: The Trivia API
    try {
      final queryParameters = <String, String>{
        'limit': amount.toString(),
      };
      
      if (difficulty != TriviaDifficulty.any) {
        queryParameters['difficulties'] = difficulty.value;
      }

      final uri = Uri.parse(_theTriviaApiUrl).replace(queryParameters: queryParameters);
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List?;
        if (list != null && list.isNotEmpty) {
          final mappedResults = list.map((q) {
            final questionText = q['question'] is Map ? (q['question']['text'] ?? '') : q['question'].toString();
            return {
              'category': q['category'] ?? 'General Knowledge',
              'type': 'multiple',
              'difficulty': q['difficulty'] ?? 'medium',
              'question': questionText,
              'correct_answer': q['correctAnswer'] ?? '',
              'incorrect_answers': (q['incorrectAnswers'] as List?)?.map((e) => e.toString()).toList() ?? [],
            };
          }).toList();

          print('✅ Lấy thành công ${mappedResults.length} câu hỏi từ Tầng 2 (The Trivia API)');
          return {
            'response_code': 0,
            'results': mappedResults,
          };
        }
      }
      print('⚠️ The Trivia API trả về kết quả rỗng. Chuyển sang Tầng 3 (Local Offline Asset)...');
    } catch (e) {
      print('⚠️ Lỗi gọi The Trivia API ($e). Chuyển sang Tầng 3 (Local Offline Asset)...');
    }

    // 3. Tầng 3: Local Offline JSON Asset
    print('📦 Nạp câu hỏi từ Tầng 3 (Local Offline JSON Asset)...');
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

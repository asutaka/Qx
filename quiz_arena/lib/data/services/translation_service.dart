import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dịch vụ dịch thuật văn bản tự động (sử dụng API Google Translate miễn phí)
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  /// Dịch văn bản từ ngôn ngữ nguồn sang ngôn ngữ đích
  Future<String> translate(String text, {String from = 'en', String to = 'vi'}) async {
    if (text.trim().isEmpty) return text;
    
    // Xử lý các kí tự thực thể HTML nếu có (ví dụ: &quot;, &#039;)
    String cleanText = _decodeHtmlEntities(text);

    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(cleanText)}'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded != null && decoded[0] != null) {
          final parts = decoded[0] as List;
          final translatedText = parts.map((part) => part[0]).join('');
          return translatedText;
        }
      }
    } catch (e) {
      // In lỗi ra console để debug, trả về văn bản gốc làm fallback
      print("Lỗi dịch thuật: $e");
    }
    return cleanText;
  }

  /// Hàm giải mã nhanh các thực thể HTML phổ biến trả về từ Open Trivia Database
  String _decodeHtmlEntities(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&rsquo;', "'");
  }
}

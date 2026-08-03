import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Dịch vụ dịch thuật văn bản tự động (Sử dụng Google ML Kit offline trên Mobile & Web API online trên Chrome)
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  OnDeviceTranslator? _translator;
  String? _sourceLang;
  String? _targetLang;

  /// Dịch văn bản từ ngôn ngữ nguồn sang ngôn ngữ đích
  Future<String> translate(String text, {String from = 'en', String to = 'vi'}) async {
    if (text.trim().isEmpty || from == to) return text;
    
    // Xử lý các kí tự thực thể HTML nếu có (ví dụ: &quot;, &#039;)
    String cleanText = _decodeHtmlEntities(text);

    if (kIsWeb) {
      // Trên Web (Chrome) sử dụng Google Translate API online
      return _translateOnline(cleanText, from: from, to: to);
    }

    try {
      // Trên Mobile (Android/iOS) sử dụng Google ML Kit Offline
      final sourceLanguage = _mapStringToLanguage(from);
      final targetLanguage = _mapStringToLanguage(to);

      if (sourceLanguage == null || targetLanguage == null) {
        return _translateOnline(cleanText, from: from, to: to);
      }

      // Khởi tạo hoặc tái sử dụng bộ dịch nếu ngôn ngữ đích thay đổi
      if (_translator == null || _sourceLang != from || _targetLang != to) {
        await _translator?.close();
        _translator = OnDeviceTranslator(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );
        _sourceLang = from;
        _targetLang = to;
      }

      final result = await _translator!.translateText(cleanText);
      return result;
    } catch (e) {
      print("Lỗi dịch offline Google ML Kit: $e. Sử dụng online API fallback.");
      return _translateOnline(cleanText, from: from, to: to);
    }
  }

  /// Dịch online bằng Google API (dành cho Web hoặc khi chưa tải gói offline)
  Future<String> _translateOnline(String text, {String from = 'en', String to = 'vi'}) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}'
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
      print("Lỗi dịch online: $e");
    }
    return text;
  }

  /// Tải gói ngôn ngữ ngầm ở chế độ nền (Background Download)
  void downloadLanguageModelInBackground(String langCode, Function(bool) callback) {
    if (kIsWeb) {
      // Trên Web chỉ giả lập thành công sau 2 giây
      Future.delayed(const Duration(seconds: 2), () => callback(true));
      return;
    }

    Future(() async {
      try {
        final language = _mapStringToLanguage(langCode);
        if (language == null) {
          callback(false);
          return;
        }

        final modelManager = OnDeviceTranslatorModelManager();
        
        // 1. Kiểm tra và tải mô hình nguồn (Tiếng Anh)
        final isEnglishDownloaded = await modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode);
        if (!isEnglishDownloaded) {
          await modelManager.downloadModel(TranslateLanguage.english.bcpCode);
        }

        // 2. Kiểm tra và tải mô hình đích (Ví dụ: Tiếng Việt)
        if (language != TranslateLanguage.english) {
          final isTargetDownloaded = await modelManager.isModelDownloaded(language.bcpCode);
          if (!isTargetDownloaded) {
            await modelManager.downloadModel(language.bcpCode);
          }
        }
        callback(true);
      } catch (e) {
        print("Lỗi tải ngầm gói ngôn ngữ $langCode: $e");
        callback(false);
      }
    });
  }

  /// Ánh xạ từ mã chuỗi (String) sang TranslateLanguage của ML Kit (hỗ trợ toàn bộ 59 ngôn ngữ)
  TranslateLanguage? _mapStringToLanguage(String code) {
    final cleanCode = code.toLowerCase();
    for (final lang in TranslateLanguage.values) {
      if (lang.bcpCode == cleanCode || lang.name == cleanCode) {
        return lang;
      }
    }
    return null;
  }

  /// Hàm giải mã nhanh các thực thể HTML phổ biến trả về từ Open Trivia Database
  String _decodeHtmlEntities(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&hellip;', '...');
  }
}

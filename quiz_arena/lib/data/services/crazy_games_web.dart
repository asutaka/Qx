import 'dart:js_util' as js_util;
import 'dart:html' as html;

/// Triển khai thực tế trên môi trường Web
Future<String?> getCrazyGamesUserIdImpl() async {
  try {
    if (js_util.hasProperty(html.window, 'getCrazyUserId')) {
      final promise = js_util.callMethod(html.window, 'getCrazyUserId', []);
      final result = await js_util.promiseToFuture(promise);
      return result as String?;
    }
  } catch (e) {
    print("Error calling getCrazyUserId in JS: $e");
  }
  return null;
}

Future<bool> showCrazyAdImpl(String adType) async {
  try {
    if (js_util.hasProperty(html.window, 'showCrazyAd')) {
      final promise = js_util.callMethod(html.window, 'showCrazyAd', [adType]);
      final result = await js_util.promiseToFuture(promise);
      return result as bool? ?? false;
    }
  } catch (e) {
    print("Error calling showCrazyAd in JS: $e");
  }
  return true; // Trả về true nếu gặp lỗi môi trường để tránh làm kẹt game của người chơi
}

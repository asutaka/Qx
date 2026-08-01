import 'dart:js_util' as js_util;
import 'dart:html' as html;

/// Triển khai thực tế trên môi trường Web
Future<String?> getCrazyGamesUserIdImpl() async {
  try {
    // Kiểm tra xem hàm getCrazyUserId có tồn tại trong cửa sổ window JS không
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

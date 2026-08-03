import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Triển khai thực tế trên môi trường Web
Future<String?> getCrazyGamesUserIdImpl() async {
  try {
    if (globalContext.has('getCrazyUserId')) {
      final promise = globalContext.callMethod<JSPromise<JSString?>>('getCrazyUserId'.toJS);
      final result = await promise.toDart;
      return result?.toDart;
    }
  } catch (e) {
    print("Error calling getCrazyUserId in JS: $e");
  }
  return null;
}

Future<bool> showCrazyAdImpl(String adType) async {
  try {
    if (globalContext.has('showCrazyAd')) {
      final promise = globalContext.callMethod<JSPromise<JSBoolean>>('showCrazyAd'.toJS, adType.toJS);
      final result = await promise.toDart;
      return result.toDart;
    }
  } catch (e) {
    print("Error calling showCrazyAd in JS: $e");
  }
  return true; // Trả về true nếu gặp lỗi môi trường để tránh làm kẹt game của người chơi
}



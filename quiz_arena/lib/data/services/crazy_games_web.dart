import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'audio_service.dart';

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
    _ensureAudioListener();
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

void crazyGameplayStartImpl() {
  try {
    if (globalContext.has('crazyGameplayStart')) {
      globalContext.callMethod('crazyGameplayStart'.toJS);
    }
  } catch (e) {
    print("Error calling crazyGameplayStart in JS: $e");
  }
}

void crazyGameplayStopImpl() {
  try {
    if (globalContext.has('crazyGameplayStop')) {
      globalContext.callMethod('crazyGameplayStop'.toJS);
    }
  } catch (e) {
    print("Error calling crazyGameplayStop in JS: $e");
  }
}

void crazyHappyTimeImpl() {
  try {
    if (globalContext.has('crazyHappyTime')) {
      globalContext.callMethod('crazyHappyTime'.toJS);
    }
  } catch (e) {
    print("Error calling crazyHappyTime in JS: $e");
  }
}

bool _audioListenerRegistered = false;
void _ensureAudioListener() {
  if (_audioListenerRegistered) return;
  _audioListenerRegistered = true;
  try {
    globalContext.setProperty(
      'onCrazyAdStateChanged'.toJS,
      ((JSBoolean isAdActive) {
        final active = isAdActive.toDart;
        AudioService().setMuted(active);
      }).toJS,
    );
  } catch (e) {
    print("Error registering onCrazyAdStateChanged: $e");
  }
}

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Triển khai phát SFX trên Web qua JS Audio Synthesizer
void playSfxImpl(String sfxType, double volumeRatio) {
  try {
    if (globalContext.has('playQuizSfx')) {
      globalContext.callMethod(
        'playQuizSfx'.toJS,
        sfxType.toJS,
        volumeRatio.toJS,
      );
    }
  } catch (e) {
    print("Error calling playQuizSfx in JS: $e");
  }
}

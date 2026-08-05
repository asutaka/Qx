import 'audio_stub.dart' if (dart.library.html) 'audio_web.dart';

/// Dịch vụ phát âm thanh và hiệu ứng âm thanh SFX trong trò chơi
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  /// Đặt trạng thái Mute (tạm dừng toàn bộ âm thanh, dùng khi quảng cáo hiển thị)
  void setMuted(bool muted) {
    _isMuted = muted;
  }

  /// Phát hiệu ứng âm thanh theo loại và tỉ lệ âm lượng (0 đến 100)
  void playSfx(String sfxType, {int volume = 80}) {
    if (_isMuted) return;
    final ratio = (volume.clamp(0, 100)) / 100.0;
    if (ratio <= 0) return;
    playSfxImpl(sfxType, ratio);
  }

  void playCorrect({int volume = 80}) => playSfx('correct', volume: volume);
  void playWrong({int volume = 80}) => playSfx('wrong', volume: volume);
  void playClick({int volume = 80}) => playSfx('click', volume: volume);
  void playClaim({int volume = 80}) => playSfx('claim', volume: volume);
  void playVictory({int volume = 80}) => playSfx('victory', volume: volume);
  void playDefeat({int volume = 80}) => playSfx('defeat', volume: volume);
}

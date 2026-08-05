import 'crazy_games_stub.dart'
    if (dart.library.html) 'crazy_games_web.dart';

/// Dịch vụ kết nối và gọi hàm SDK từ cổng game CrazyGames
class CrazyGamesService {
  /// Lấy User ID của người dùng đã đăng nhập trên CrazyGames (chỉ chạy trên Web)
  static Future<String?> getCrazyGamesUserId() async {
    return getCrazyGamesUserIdImpl();
  }

  /// Yêu cầu hiển thị quảng cáo của CrazyGames (adType: "midroll" hoặc "rewarded")
  static Future<bool> showAd(String adType) async {
    return showCrazyAdImpl(adType);
  }

  /// Báo hiệu CrazyGames SDK khi bắt đầu chơi game (Gameplay Start)
  static void gameplayStart() {
    crazyGameplayStartImpl();
  }

  /// Báo hiệu CrazyGames SDK khi tạm dừng hoặc kết thúc ván chơi (Gameplay Stop)
  static void gameplayStop() {
    crazyGameplayStopImpl();
  }

  /// Báo hiệu CrazyGames SDK khi người chơi đạt thành tích cao / ván thắng kịch tính (Happy Time)
  static void happyTime() {
    crazyHappyTimeImpl();
  }
}

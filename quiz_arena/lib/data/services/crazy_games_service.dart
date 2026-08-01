import 'crazy_games_stub.dart'
    if (dart.library.html) 'crazy_games_web.dart';

/// Dịch vụ kết nối và gọi hàm SDK từ cổng game CrazyGames
class CrazyGamesService {
  /// Lấy User ID của người dùng đã đăng nhập trên CrazyGames (chỉ chạy trên Web)
  static Future<String?> getCrazyGamesUserId() async {
    return getCrazyGamesUserIdImpl();
  }
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import 'crazy_games_service.dart';

/// Dịch vụ đồng bộ hóa dữ liệu người chơi lên Cloud Firestore (Online State Management)
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  String? _userId;

  /// Lấy hoặc tạo mới UserId duy nhất của thiết bị được lưu cục bộ
  Future<String> getOrCreateUserId() async {
    if (_userId != null) return _userId!;

    try {
      // 1. Kiểm tra xem có ID từ CrazyGames (nếu chạy trên Web và người chơi đăng nhập)
      final crazyId = await CrazyGamesService.getCrazyGamesUserId();
      if (crazyId != null && crazyId.isNotEmpty) {
        _userId = 'crazy_$crazyId';
        return _userId!;
      }

      // 2. Fallback sang LocalStorage (SharedPreferences) như cũ
      final prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString('user_id');

      // Nếu trước đó đang lưu ID CrazyGames nhưng giờ không lấy được (do chưa đăng nhập),
      // thì buộc phải sinh hoặc lấy ID guest để chơi tiếp
      if (savedId == null || savedId.isEmpty || savedId.startsWith('crazy_')) {
        // Sinh UUID ngẫu nhiên: user_timestamp_random
        final randomNum = Random().nextInt(1000000);
        savedId = 'user_${DateTime.now().millisecondsSinceEpoch}_$randomNum';
        await prefs.setString('user_id', savedId);
      }

      _userId = savedId;
      return _userId!;
    } catch (e) {
      print("Lỗi truy xuất SharedPreferences: $e");
      // Trả về ID dự phòng tạm thời trong RAM
      return _userId ??= 'user_temp_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Tải thông tin Game State từ Firestore
  Future<LocalGameState?> loadGameState() async {
    try {
      final uId = await getOrCreateUserId();
      final firestore = FirebaseFirestore.instance;

      // 1. Tải dữ liệu của User hiện tại (CrazyGames hoặc Guest)
      final doc = await firestore
          .collection('users')
          .doc(uId)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        print("Tải thành công GameState từ Firestore cho User: $uId");
        return LocalGameState.fromMap(doc.data()!);
      }

      // 2. Nếu User hiện tại là CrazyGames mới đăng nhập (chưa có dữ liệu trên Cloud),
      // nhưng trước đó họ đã chơi dưới dạng Guest (có dữ liệu Guest trên SharedPreferences/Firestore)
      if (uId.startsWith('crazy_')) {
        final prefs = await SharedPreferences.getInstance();
        final guestId = prefs.getString('user_id');
        if (guestId != null && guestId.isNotEmpty && !guestId.startsWith('crazy_')) {
          // Lấy dữ liệu của Guest cũ
          final guestDoc = await firestore
              .collection('users')
              .doc(guestId)
              .get()
              .timeout(const Duration(seconds: 4));

          if (guestDoc.exists && guestDoc.data() != null) {
            final guestData = guestDoc.data()!;
            print("Đang đồng bộ dữ liệu Guest ($guestId) sang tài khoản CrazyGames ($uId)");

            // Sao chép dữ liệu Guest sang tài khoản CrazyGames mới
            await firestore.collection('users').doc(uId).set(guestData);

            // Xóa document Guest cũ trên Firestore để dọn dẹp
            await firestore.collection('users').doc(guestId).delete().catchError((e) => null);

            // Cập nhật SharedPreferences để trỏ hẳn sang ID CrazyGames mới
            await prefs.setString('user_id', uId);

            return LocalGameState.fromMap(guestData);
          }
        }
      }
    } catch (e) {
      print("Lỗi tải GameState từ Firestore: $e. Tiếp tục dùng local state.");
    }
    return null;
  }

  /// Lưu/Đồng bộ thông tin Game State lên Firestore
  Future<void> saveGameState(LocalGameState state) async {
    try {
      final uId = await getOrCreateUserId();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .set(state.toMap())
          .timeout(const Duration(seconds: 4));
      print("Đồng bộ thành công GameState lên Firestore cho User: $uId");
    } catch (e) {
      print("Lỗi đồng bộ GameState lên Firestore: $e");
    }
  }
}

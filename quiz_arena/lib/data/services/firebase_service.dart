import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

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
      final prefs = await SharedPreferences.getInstance();
      String? savedId = prefs.getString('user_id');

      if (savedId == null || savedId.isEmpty) {
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        print("Tải thành công GameState từ Firestore cho User: $uId");
        return LocalGameState.fromMap(doc.data()!);
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

import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/game_state.dart';
import '../core/constants/shop_items.dart';
import '../data/services/firebase_service.dart';

/// Provider quản lý toàn bộ trạng thái của game (State Management).
/// Tích hợp cơ chế tự động đồng bộ hóa lên Cloud Firestore với debounce hoãn ghi.
class GameProvider extends ChangeNotifier {
  LocalGameState _state = LocalGameState.defaultState();
  Timer? _saveDebounceTimer;
  
  LocalGameState get state => _state;

  GameProvider() {
    _initAndLoadData();
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }

  /// Tải thông tin tài khoản đã lưu trên Firestore lúc khởi chạy ứng dụng
  Future<void> _initAndLoadData() async {
    final cloudState = await FirebaseService().loadGameState();
    if (cloudState != null) {
      _state = cloudState;
      notifyListeners();
    } else {
      // Nếu chưa có tài liệu trên Cloud Firestore, khởi tạo tài liệu mới ngay lập tức
      _saveToCloud(immediate: true);
    }
  }

  /// Hàm gửi dữ liệu đồng bộ lên Firestore với cơ chế Debounce 1.5 giây
  void _saveToCloud({bool immediate = false}) {
    if (immediate) {
      _saveDebounceTimer?.cancel();
      FirebaseService().saveGameState(_state);
      return;
    }

    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      FirebaseService().saveGameState(_state);
    });
  }

  /// Cập nhật tên hiển thị người chơi.
  void updateNickname(String name) {
    if (name.trim().isNotEmpty) {
      _state = _state.copyWith(nickname: name.trim());
      notifyListeners();
      _saveToCloud();
    }
  }

  /// Cập nhật quốc tịch.
  void updateCountry(String countryCode) {
    _state = _state.copyWith(country: countryCode);
    notifyListeners();
    _saveToCloud();
  }

  /// Cập nhật âm lượng nhạc nền/hiệu ứng.
  void updateVolume(int volume) {
    _state = _state.copyWith(volume: volume.clamp(0, 100));
    notifyListeners();
    _saveToCloud();
  }

  /// Thực hiện mua một vật phẩm từ cửa hàng.
  bool buyItem(ShopItem item) {
    if (_state.gold >= item.price && !_state.ownedItems.contains(item.id)) {
      final updatedOwned = List<String>.from(_state.ownedItems)..add(item.id);
      _state = _state.copyWith(
        gold: _state.gold - item.price,
        ownedItems: updatedOwned,
      );
      notifyListeners();
      _saveToCloud();
      return true;
    }
    return false;
  }

  /// Trang bị vật phẩm đã sở hữu cho nhân vật.
  void equipItem(String itemId, String category) {
    if (!_state.ownedItems.contains(itemId)) return;

    if (category == "character") {
      _state = _state.copyWith(equippedCharacter: itemId);
    } else if (category == "hat") {
      _state = _state.copyWith(equippedHat: itemId);
    } else if (category == "shoes") {
      _state = _state.copyWith(equippedShoes: itemId);
    } else if (category == "effect") {
      _state = _state.copyWith(equippedEffect: itemId);
    } else if (category == "track") {
      _state = _state.copyWith(equippedTrack: itemId);
    }
    notifyListeners();
    _saveToCloud();
  }

  /// Nhận quà đăng nhập hàng ngày (Daily Login Reward).
  void claimDaily() {
    _state = _state.copyWith(
      gold: _state.gold + 1000,
      accumulatedGold: _state.accumulatedGold + 1000,
      lastDailyClaim: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
    _saveToCloud();
  }

  /// Nhận quà quảng cáo đếm ngược (Bonus Ad Reward).
  void claimAd() {
    _state = _state.copyWith(
      gold: _state.gold + 500,
      accumulatedGold: _state.accumulatedGold + 500,
      lastAdClaim: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
    _saveToCloud();
  }

  /// Khấu trừ vàng (ví dụ: đặt cọc hoặc thanh toán phí).
  /// Trả về true nếu thành công.
  bool deductGold(int amount) {
    if (_state.gold >= amount) {
      _state = _state.copyWith(gold: _state.gold - amount);
      notifyListeners();
      _saveToCloud();
      return true;
    }
    return false;
  }

  /// Cộng thêm vàng cho người chơi.
  void addGold(int amount) {
    if (amount <= 0) return;
    _state = _state.copyWith(
      gold: _state.gold + amount,
      accumulatedGold: _state.accumulatedGold + amount,
    );
    notifyListeners();
    _saveToCloud();
  }

  /// Tăng thêm điểm kỷ lục khi chơi Single Mode.
  void updateHighScore(int score) {
    if (score > _state.singleHighScore) {
      _state = _state.copyWith(singleHighScore: score);
      notifyListeners();
      _saveToCloud();
    }
  }

  /// Cập nhật ngôn ngữ dịch thuật mục tiêu.
  void updateTargetLanguage(String lang) {
    _state = _state.copyWith(targetLanguage: lang);
    notifyListeners();
    _saveToCloud();
  }

  /// Thêm ngôn ngữ vào danh sách gói offline đã tải.
  void downloadLanguagePackage(String lang) {
    if (!_state.downloadedLanguages.contains(lang)) {
      final updatedLangs = List<String>.from(_state.downloadedLanguages)..add(lang);
      _state = _state.copyWith(downloadedLanguages: updatedLangs);
      notifyListeners();
      _saveToCloud();
    }
  }
}

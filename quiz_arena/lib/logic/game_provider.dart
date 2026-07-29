import 'package:flutter/material.dart';
import '../data/models/game_state.dart';
import '../core/constants/shop_items.dart';

/// Provider quản lý toàn bộ trạng thái của game (State Management).
/// Kế thừa ChangeNotifier để tự động thông báo cập nhật giao diện khi dữ liệu thay đổi.
class GameProvider extends ChangeNotifier {
  LocalGameState _state = LocalGameState.defaultState();
  
  LocalGameState get state => _state;

  /// Cập nhật tên hiển thị người chơi.
  void updateNickname(String name) {
    if (name.trim().isNotEmpty) {
      _state = _state.copyWith(nickname: name.trim());
      notifyListeners();
    }
  }

  /// Cập nhật quốc tịch.
  void updateCountry(String countryCode) {
    _state = _state.copyWith(country: countryCode);
    notifyListeners();
  }

  /// Cập nhật âm lượng nhạc nền/hiệu ứng.
  void updateVolume(int volume) {
    _state = _state.copyWith(volume: volume.clamp(0, 100));
    notifyListeners();
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
    }
    notifyListeners();
  }

  /// Nhận quà đăng nhập hàng ngày (Daily Login Reward).
  void claimDaily() {
    _state = _state.copyWith(
      gold: _state.gold + 1000,
      accumulatedGold: _state.accumulatedGold + 1000,
      lastDailyClaim: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  /// Nhận quà quảng cáo đếm ngược (Bonus Ad Reward).
  void claimAd() {
    _state = _state.copyWith(
      gold: _state.gold + 500,
      accumulatedGold: _state.accumulatedGold + 500,
      lastAdClaim: DateTime.now().millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  /// Tăng thêm điểm kỷ lục khi chơi Single Mode.
  void updateHighScore(int score) {
    if (score > _state.singleHighScore) {
      _state = _state.copyWith(singleHighScore: score);
      notifyListeners();
    }
  }

  /// Cập nhật ngôn ngữ dịch thuật mục tiêu.
  void updateTargetLanguage(String lang) {
    _state = _state.copyWith(targetLanguage: lang);
    notifyListeners();
  }

  /// Thêm ngôn ngữ vào danh sách gói offline đã tải.
  void downloadLanguagePackage(String lang) {
    if (!_state.downloadedLanguages.contains(lang)) {
      final updatedLangs = List<String>.from(_state.downloadedLanguages)..add(lang);
      _state = _state.copyWith(downloadedLanguages: updatedLangs);
      notifyListeners();
    }
  }
}

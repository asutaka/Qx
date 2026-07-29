/// Lớp dữ liệu quản lý trạng thái, cài đặt, số dư ví và trang phục của người chơi.
class LocalGameState {
  final String nickname;
  final int gold;
  final int accumulatedGold;
  final int singleHighScore;
  final int volume;
  final int lastDailyClaim;
  final int lastAdClaim;
  final String targetLanguage;
  final List<String> downloadedLanguages;
  final List<String> ownedItems;
  final String equippedHat;
  final String equippedShoes;
  final String equippedEffect;
  final String equippedCharacter;
  final String country;

  LocalGameState({
    required this.nickname,
    required this.gold,
    required this.accumulatedGold,
    required this.singleHighScore,
    required this.volume,
    required this.lastDailyClaim,
    required this.lastAdClaim,
    required this.targetLanguage,
    required this.downloadedLanguages,
    required this.ownedItems,
    required this.equippedHat,
    required this.equippedShoes,
    required this.equippedEffect,
    required this.equippedCharacter,
    required this.country,
  });

  /// Tạo trạng thái mặc định ban đầu cho người chơi mới.
  factory LocalGameState.defaultState() {
    return LocalGameState(
      nickname: "Player_1",
      gold: 2000,
      accumulatedGold: 2000,
      singleHighScore: 0,
      volume: 80,
      lastDailyClaim: 0,
      lastAdClaim: 0,
      targetLanguage: "en",
      downloadedLanguages: const ["en", "vi"],
      ownedItems: const ["hat_none", "shoes_none", "effect_none", "char_khoi_nguyen_m", "char_khoi_nguyen_f"],
      equippedHat: "hat_none",
      equippedShoes: "shoes_none",
      equippedEffect: "effect_none",
      equippedCharacter: "char_khoi_nguyen_m",
      country: "vn",
    );
  }

  /// Phương thức sao chép với các thuộc tính thay đổi (immutable state update).
  LocalGameState copyWith({
    String? nickname,
    int? gold,
    int? accumulatedGold,
    int? singleHighScore,
    int? volume,
    int? lastDailyClaim,
    int? lastAdClaim,
    String? targetLanguage,
    List<String>? downloadedLanguages,
    List<String>? ownedItems,
    String? equippedHat,
    String? equippedShoes,
    String? equippedEffect,
    String? equippedCharacter,
    String? country,
  }) {
    return LocalGameState(
      nickname: nickname ?? this.nickname,
      gold: gold ?? this.gold,
      accumulatedGold: accumulatedGold ?? this.accumulatedGold,
      singleHighScore: singleHighScore ?? this.singleHighScore,
      volume: volume ?? this.volume,
      lastDailyClaim: lastDailyClaim ?? this.lastDailyClaim,
      lastAdClaim: lastAdClaim ?? this.lastAdClaim,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      downloadedLanguages: downloadedLanguages ?? this.downloadedLanguages,
      ownedItems: ownedItems ?? this.ownedItems,
      equippedHat: equippedHat ?? this.equippedHat,
      equippedShoes: equippedShoes ?? this.equippedShoes,
      equippedEffect: equippedEffect ?? this.equippedEffect,
      equippedCharacter: equippedCharacter ?? this.equippedCharacter,
      country: country ?? this.country,
    );
  }

  /// Chuyển đổi trạng thái thành Map để lưu vào SQLite database.
  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'gold': gold,
      'accumulatedGold': accumulatedGold,
      'singleHighScore': singleHighScore,
      'volume': volume,
      'lastDailyClaim': lastDailyClaim,
      'lastAdClaim': lastAdClaim,
      'targetLanguage': targetLanguage,
      'downloadedLanguages': downloadedLanguages.join(','),
      'ownedItems': ownedItems.join(','),
      'equippedHat': equippedHat,
      'equippedShoes': equippedShoes,
      'equippedEffect': equippedEffect,
      'equippedCharacter': equippedCharacter,
      'country': country,
    };
  }

  /// Đọc dữ liệu từ SQLite database map và khởi tạo đối tượng.
  factory LocalGameState.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic val) {
      if (val == null || val.toString().isEmpty) return [];
      return val.toString().split(',');
    }

    return LocalGameState(
      nickname: map['nickname'] ?? "Player_1",
      gold: map['gold'] ?? 2000,
      accumulatedGold: map['accumulatedGold'] ?? 2000,
      singleHighScore: map['singleHighScore'] ?? 0,
      volume: map['volume'] ?? 80,
      lastDailyClaim: map['lastDailyClaim'] ?? 0,
      lastAdClaim: map['lastAdClaim'] ?? 0,
      targetLanguage: map['targetLanguage'] ?? "en",
      downloadedLanguages: parseList(map['downloadedLanguages']).isEmpty 
          ? const ["en", "vi"] 
          : parseList(map['downloadedLanguages']),
      ownedItems: parseList(map['ownedItems']).isEmpty
          ? const ["hat_none", "shoes_none", "effect_none", "char_khoi_nguyen_m", "char_khoi_nguyen_f"]
          : parseList(map['ownedItems']),
      equippedHat: map['equippedHat'] ?? "hat_none",
      equippedShoes: map['equippedShoes'] ?? "shoes_none",
      equippedEffect: map['equippedEffect'] ?? "effect_none",
      equippedCharacter: map['equippedCharacter'] ?? "char_khoi_nguyen_m",
      country: map['country'] ?? "vn",
    );
  }
}

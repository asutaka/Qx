class ShopItem {
  final String id;
  final String name;
  final int price;
  final String assetOrEmoji;

  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.assetOrEmoji,
  });
}

class AppShopItems {
  static const List<ShopItem> characters = [
    ShopItem(id: "char_khoi_nguyen_m", name: "Genesis Male 🎩", price: 0, assetOrEmoji: "assets/characters/char_khoi_nguyen_m.webp"),
    ShopItem(id: "char_khoi_nguyen_f", name: "Genesis Female 👒", price: 0, assetOrEmoji: "assets/characters/char_khoi_nguyen_f.webp"),
    ShopItem(id: "char_wukong", name: "Wukong 🐵👑", price: 2000, assetOrEmoji: "assets/characters/char_wukong.webp"),
    ShopItem(id: "char_tu_ha", name: "Fairy Zixia 🧚‍♀️", price: 1800, assetOrEmoji: "assets/characters/char_tu_ha.webp"),
    ShopItem(id: "char_am_nguyet_m", name: "Dark Moon Male 🌙", price: 1200, assetOrEmoji: "assets/characters/char_am_nguyet_m.webp"),
    ShopItem(id: "char_am_nguyet_f", name: "Dark Moon Female 🌕", price: 1200, assetOrEmoji: "assets/characters/char_am_nguyet_f.webp"),
    ShopItem(id: "char_hao_nhoang_m", name: "Flashy Male ✨", price: 1500, assetOrEmoji: "assets/characters/char_hao_nhoang_m.webp"),
    ShopItem(id: "char_hao_nhoang_f", name: "Flashy Female 💖", price: 1500, assetOrEmoji: "assets/characters/char_hao_nhoang_f.webp"),
    ShopItem(id: "char_det_nen_m", name: "Weaver Male 🧵", price: 1000, assetOrEmoji: "assets/characters/char_det_nen_m.webp"),
    ShopItem(id: "char_det_nen_f", name: "Weaver Female 🪡", price: 1000, assetOrEmoji: "assets/characters/char_det_nen_f.webp"),
    ShopItem(id: "char_xuat_kich", name: "Strike Squad 🛡️", price: 1500, assetOrEmoji: "assets/characters/char_xuat_kich.webp"),
    ShopItem(id: "char_lan_m", name: "Lion Dance Male 🦁", price: 1600, assetOrEmoji: "assets/characters/char_lan_m.webp"),
    ShopItem(id: "char_lan_f", name: "Lion Dance Female 🏮", price: 1600, assetOrEmoji: "assets/characters/char_lan_f.webp"),
    ShopItem(id: "char_birthday_m", name: "Birthday Boy 🎂", price: 800, assetOrEmoji: "assets/characters/char_birthday_m.webp"),
    ShopItem(id: "char_birthday_f", name: "Birthday Girl 🎁", price: 800, assetOrEmoji: "assets/characters/char_birthday_f.webp"),
    ShopItem(id: "char_noel_m", name: "Christmas Snow Male ❄️", price: 1000, assetOrEmoji: "assets/characters/char_noel_m.webp"),
    ShopItem(id: "char_noel_f", name: "Christmas Snow Female 🎅", price: 1000, assetOrEmoji: "assets/characters/char_noel_f.webp"),
  ];

  static const List<ShopItem> hats = [
    ShopItem(id: "hat_none", name: "No Hat", price: 0, assetOrEmoji: ""),
    ShopItem(id: "hat_cowboy", name: "Cowboy Hat 🤠", price: 500, assetOrEmoji: "🤠"),
    ShopItem(id: "hat_crown", name: "Crown 👑", price: 1500, assetOrEmoji: "👑"),
  ];

  static const List<ShopItem> shoes = [
    ShopItem(id: "shoes_none", name: "No Shoes", price: 0, assetOrEmoji: ""),
    ShopItem(id: "shoes_running", name: "Sneakers 👟", price: 300, assetOrEmoji: "👟"),
    ShopItem(id: "shoes_gold", name: "Golden Boots 🥾", price: 1000, assetOrEmoji: "🥾"),
  ];

  static const List<ShopItem> effects = [
    ShopItem(id: "effect_none", name: "No Effect", price: 0, assetOrEmoji: ""),
    ShopItem(id: "effect_fire", name: "Fire Trail 🔥", price: 800, assetOrEmoji: "🔥"),
    ShopItem(id: "effect_rainbow", name: "Rainbow Trail 🌈", price: 1200, assetOrEmoji: "🌈"),
  ];
}

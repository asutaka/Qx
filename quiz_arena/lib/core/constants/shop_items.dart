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
    ShopItem(id: "char_khoi_nguyen_m", name: "Khởi Nguyên Nam 🎩", price: 0, assetOrEmoji: "assets/characters/char_khoi_nguyen_m.webp"),
    ShopItem(id: "char_khoi_nguyen_f", name: "Khởi Nguyên Nữ 👒", price: 0, assetOrEmoji: "assets/characters/char_khoi_nguyen_f.webp"),
    ShopItem(id: "char_wukong", name: "Tề Thiên Đại Thánh 🐵👑", price: 2000, assetOrEmoji: "assets/characters/char_wukong.webp"),
    ShopItem(id: "char_tu_ha", name: "Tử Hà Tiên Tử 🧚‍♀️", price: 1800, assetOrEmoji: "assets/characters/char_tu_ha.webp"),
    ShopItem(id: "char_am_nguyet_m", name: "Ám Nguyệt Mỹ Nam 🌙", price: 1200, assetOrEmoji: "assets/characters/char_am_nguyet_m.webp"),
    ShopItem(id: "char_am_nguyet_f", name: "Ám Nguyệt Mỹ Nữ 🌕", price: 1200, assetOrEmoji: "assets/characters/char_am_nguyet_f.webp"),
    ShopItem(id: "char_hao_nhoang_m", name: "Cực Kỳ Hào Nhoáng Nam ✨", price: 1500, assetOrEmoji: "assets/characters/char_hao_nhoang_m.webp"),
    ShopItem(id: "char_hao_nhoang_f", name: "Cực Kỳ Hào Nhoáng Nữ 💖", price: 1500, assetOrEmoji: "assets/characters/char_hao_nhoang_f.webp"),
    ShopItem(id: "char_det_nen_m", name: "Dệt Nền Thời Đại Nam 🧵", price: 1000, assetOrEmoji: "assets/characters/char_det_nen_m.webp"),
    ShopItem(id: "char_det_nen_f", name: "Dệt Nền Thời Đại Nữ 🪡", price: 1000, assetOrEmoji: "assets/characters/char_det_nen_f.webp"),
    ShopItem(id: "char_xuat_kich", name: "Đoàn Quân Xuất Kích 🛡️", price: 1500, assetOrEmoji: "assets/characters/char_xuat_kich.webp"),
    ShopItem(id: "char_lan_m", name: "Múa Lân Nam 🦁", price: 1600, assetOrEmoji: "assets/characters/char_lan_m.webp"),
    ShopItem(id: "char_lan_f", name: "Múa Lân Nữ 🏮", price: 1600, assetOrEmoji: "assets/characters/char_lan_f.webp"),
    ShopItem(id: "char_birthday_m", name: "Nam Sinh Nhật 🎂", price: 800, assetOrEmoji: "assets/characters/char_birthday_m.webp"),
    ShopItem(id: "char_birthday_f", name: "Nữ Sinh Nhật 🎁", price: 800, assetOrEmoji: "assets/characters/char_birthday_f.webp"),
    ShopItem(id: "char_dun_dun", name: "Đùn Đùn 🐧", price: 1400, assetOrEmoji: "assets/characters/char_dun_dun.webp"),
    ShopItem(id: "char_noel_m", name: "Tuyết Giáng Sinh Nam ❄️", price: 1000, assetOrEmoji: "assets/characters/char_noel_m.webp"),
    ShopItem(id: "char_noel_f", name: "Tuyết Giáng Sinh Nữ 🎅", price: 1000, assetOrEmoji: "assets/characters/char_noel_f.webp"),
  ];

  static const List<ShopItem> hats = [
    ShopItem(id: "hat_none", name: "Không đội mũ", price: 0, assetOrEmoji: ""),
    ShopItem(id: "hat_cowboy", name: "Mũ Cao Bồi 🤠", price: 500, assetOrEmoji: "🤠"),
    ShopItem(id: "hat_crown", name: "Vương Miện 👑", price: 1500, assetOrEmoji: "👑"),
  ];

  static const List<ShopItem> shoes = [
    ShopItem(id: "shoes_none", name: "Không đi giày", price: 0, assetOrEmoji: ""),
    ShopItem(id: "shoes_running", name: "Giày Thể Thao 👟", price: 300, assetOrEmoji: "👟"),
    ShopItem(id: "shoes_gold", name: "Bốt Vàng 🥾", price: 1000, assetOrEmoji: "🥾"),
  ];

  static const List<ShopItem> effects = [
    ShopItem(id: "effect_none", name: "Không hiệu ứng", price: 0, assetOrEmoji: ""),
    ShopItem(id: "effect_fire", name: "Vệt Lửa 🔥", price: 800, assetOrEmoji: "🔥"),
    ShopItem(id: "effect_rainbow", name: "Cầu Vồng 🌈", price: 1200, assetOrEmoji: "🌈"),
  ];
}

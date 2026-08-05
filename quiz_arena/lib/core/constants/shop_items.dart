enum ItemRarity { common, rare, epic, legendary }

class ShopItem {
  final String id;
  final String name;
  final int price;
  final String assetOrEmoji;
  final ItemRarity rarity;
  final String description;

  const ShopItem({
    required this.id,
    required this.name,
    required this.price,
    required this.assetOrEmoji,
    this.rarity = ItemRarity.common,
    this.description = "",
  });
}

class AppShopItems {
  static const List<ShopItem> characters = [
    // Common (0 - 800 Coins)
    ShopItem(id: "char_khoi_nguyen_m", name: "Genesis Male 🎩", price: 0, assetOrEmoji: "assets/characters/char_khoi_nguyen_m.webp", rarity: ItemRarity.common),
    ShopItem(id: "char_khoi_nguyen_f", name: "Genesis Female 👒", price: 0, assetOrEmoji: "assets/characters/char_khoi_nguyen_f.webp", rarity: ItemRarity.common),
    ShopItem(id: "char_birthday_m", name: "Birthday Boy 🎂", price: 600, assetOrEmoji: "assets/characters/char_birthday_m.webp", rarity: ItemRarity.common),
    ShopItem(id: "char_birthday_f", name: "Birthday Girl 🎁", price: 600, assetOrEmoji: "assets/characters/char_birthday_f.webp", rarity: ItemRarity.common),
    ShopItem(id: "char_noel_m", name: "Snow Male ❄️", price: 800, assetOrEmoji: "assets/characters/char_noel_m.webp", rarity: ItemRarity.common),
    ShopItem(id: "char_noel_f", name: "Snow Female 🎅", price: 800, assetOrEmoji: "assets/characters/char_noel_f.webp", rarity: ItemRarity.common),

    // Rare (1200 - 2000 Coins)
    ShopItem(id: "char_det_nen_m", name: "Weaver Male 🧵", price: 1200, assetOrEmoji: "assets/characters/char_det_nen_m.webp", rarity: ItemRarity.rare),
    ShopItem(id: "char_det_nen_f", name: "Weaver Female 🪡", price: 1200, assetOrEmoji: "assets/characters/char_det_nen_f.webp", rarity: ItemRarity.rare),
    ShopItem(id: "char_am_nguyet_m", name: "Dark Moon Male 🌙", price: 1800, assetOrEmoji: "assets/characters/char_am_nguyet_m.webp", rarity: ItemRarity.rare),
    ShopItem(id: "char_am_nguyet_f", name: "Dark Moon Female 🌕", price: 1800, assetOrEmoji: "assets/characters/char_am_nguyet_f.webp", rarity: ItemRarity.rare),
    ShopItem(id: "char_astronaut", name: "Astro Explorer 🧑‍🚀", price: 2000, assetOrEmoji: "assets/characters/char_astronaut.webp", rarity: ItemRarity.rare),

    // Epic (2500 - 4000 Coins)
    ShopItem(id: "char_hao_nhoang_m", name: "Flashy Male ✨", price: 2500, assetOrEmoji: "assets/characters/char_hao_nhoang_m.webp", rarity: ItemRarity.epic),
    ShopItem(id: "char_hao_nhoang_f", name: "Flashy Female 💖", price: 2500, assetOrEmoji: "assets/characters/char_hao_nhoang_f.webp", rarity: ItemRarity.epic),
    ShopItem(id: "char_lan_m", name: "Lion Dance Male 🦁", price: 3000, assetOrEmoji: "assets/characters/char_lan_m.webp", rarity: ItemRarity.epic),
    ShopItem(id: "char_lan_f", name: "Lion Dance Female 🏮", price: 3000, assetOrEmoji: "assets/characters/char_lan_f.webp", rarity: ItemRarity.epic),
    ShopItem(id: "char_xuat_kich", name: "Strike Squad 🛡️", price: 3500, assetOrEmoji: "assets/characters/char_xuat_kich.webp", rarity: ItemRarity.epic),
    ShopItem(id: "char_cyber_mage", name: "Cyber Mage 🔮", price: 4000, assetOrEmoji: "assets/characters/char_cyber_mage.webp", rarity: ItemRarity.epic),

    // Legendary (6000 - 10000 Coins)
    ShopItem(id: "char_tu_ha", name: "Fairy Zixia 🧚‍♀️", price: 6000, assetOrEmoji: "assets/characters/char_tu_ha.webp", rarity: ItemRarity.legendary),
    ShopItem(id: "char_cyber_samurai", name: "Cyber Samurai ⚔️", price: 8000, assetOrEmoji: "assets/characters/char_cyber_samurai.webp", rarity: ItemRarity.legendary),
    ShopItem(id: "char_pharaoh", name: "Pharaoh Gold 👑", price: 9500, assetOrEmoji: "assets/characters/char_pharaoh.webp", rarity: ItemRarity.legendary),
    ShopItem(id: "char_wukong", name: "Wukong 🐵👑", price: 10000, assetOrEmoji: "assets/characters/char_wukong.webp", rarity: ItemRarity.legendary),
  ];

  static const List<ShopItem> hats = [
    ShopItem(id: "hat_none", name: "No Hat", price: 0, assetOrEmoji: "", rarity: ItemRarity.common),
    ShopItem(id: "hat_cap", name: "Baseball Cap 🧢", price: 300, assetOrEmoji: "🧢", rarity: ItemRarity.common),
    ShopItem(id: "hat_straw", name: "Nón Lá 🌾", price: 500, assetOrEmoji: "🌾", rarity: ItemRarity.common),
    ShopItem(id: "hat_cowboy", name: "Cowboy Hat 🤠", price: 1000, assetOrEmoji: "🤠", rarity: ItemRarity.rare),
    ShopItem(id: "hat_graduate", name: "Graduate Cap 🎓", price: 1800, assetOrEmoji: "🎓", rarity: ItemRarity.rare),
    ShopItem(id: "hat_wizard", name: "Wizard Hat 🧙‍♂️", price: 3200, assetOrEmoji: "🧙‍♂️", rarity: ItemRarity.epic),
    ShopItem(id: "hat_astro", name: "Astro Helmet 🧑‍🚀", price: 4500, assetOrEmoji: "🧑‍🚀", rarity: ItemRarity.epic),
    ShopItem(id: "hat_crown", name: "Royal Crown 👑", price: 8000, assetOrEmoji: "👑", rarity: ItemRarity.legendary),
  ];

  static const List<ShopItem> shoes = [
    ShopItem(id: "shoes_none", name: "No Shoes", price: 0, assetOrEmoji: "", rarity: ItemRarity.common),
    ShopItem(id: "shoes_running", name: "Sneakers 👟", price: 400, assetOrEmoji: "👟", rarity: ItemRarity.common),
    ShopItem(id: "shoes_sandal", name: "Comfy Sandals 🩴", price: 600, assetOrEmoji: "🩴", rarity: ItemRarity.common),
    ShopItem(id: "shoes_roller", name: "Roller Skates 🛼", price: 1200, assetOrEmoji: "🛼", rarity: ItemRarity.rare),
    ShopItem(id: "shoes_skate", name: "Ice Skates ⛸️", price: 2000, assetOrEmoji: "⛸️", rarity: ItemRarity.rare),
    ShopItem(id: "shoes_gold", name: "Golden Boots 🥾", price: 3500, assetOrEmoji: "🥾", rarity: ItemRarity.epic),
    ShopItem(id: "shoes_rocket", name: "Rocket Shoes 🚀", price: 7500, assetOrEmoji: "🚀", rarity: ItemRarity.legendary),
  ];

  static const List<ShopItem> effects = [
    ShopItem(id: "effect_none", name: "No Effect", price: 0, assetOrEmoji: "", rarity: ItemRarity.common),
    ShopItem(id: "effect_bubbles", name: "Bubble Trail 🫧", price: 500, assetOrEmoji: "🫧", rarity: ItemRarity.common),
    ShopItem(id: "effect_hearts", name: "Heart Trail 💖", price: 800, assetOrEmoji: "💖", rarity: ItemRarity.common),
    ShopItem(id: "effect_stars", name: "Star Trail ⭐", price: 1500, assetOrEmoji: "⭐", rarity: ItemRarity.rare),
    ShopItem(id: "effect_fire", name: "Fire Trail 🔥", price: 2500, assetOrEmoji: "🔥", rarity: ItemRarity.rare),
    ShopItem(id: "effect_lightning", name: "Lightning Trail ⚡", price: 4500, assetOrEmoji: "⚡", rarity: ItemRarity.epic),
    ShopItem(id: "effect_rainbow", name: "Rainbow Trail 🌈", price: 9000, assetOrEmoji: "🌈", rarity: ItemRarity.legendary),
  ];

  static const List<ShopItem> tracks = [
    ShopItem(id: "track_cyber", name: "Cyber Neon 🌌", price: 0, assetOrEmoji: "🌌", rarity: ItemRarity.common, description: "Classic Cyberpunk Grid"),
    ShopItem(id: "track_sakura", name: "Sakura Bloom 🌸", price: 1500, assetOrEmoji: "🌸", rarity: ItemRarity.rare, description: "Dreamy Cherry Blossom Petals"),
    ShopItem(id: "track_lightning", name: "Cyber Lightning ⚡", price: 2500, assetOrEmoji: "⚡", rarity: ItemRarity.rare, description: "High Voltage Electric Track"),
    ShopItem(id: "track_hellfire", name: "Magma Hellfire 🔥", price: 4000, assetOrEmoji: "🔥", rarity: ItemRarity.epic, description: "Molten Lava Ember Track"),
    ShopItem(id: "track_galaxy", name: "Starlight Galaxy ✨", price: 5500, assetOrEmoji: "✨", rarity: ItemRarity.epic, description: "Deep Cosmic Stardust Track"),
    ShopItem(id: "track_gold", name: "Golden Royale 👑", price: 10000, assetOrEmoji: "👑", rarity: ItemRarity.legendary, description: "Pure 24K Gold & Diamond Track"),
  ];
}

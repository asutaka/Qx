import 'package:flutter/material.dart';
import '../../core/constants/shop_items.dart';
import '../../core/theme/colors.dart';

/// Widget biểu diễn nhân vật đang chạy cùng các phụ kiện (Mũ, Giày, Hiệu ứng).
class RunnerWidget extends StatelessWidget {
  final String characterId;
  final String hatId;
  final String shoesId;
  final String effectId;
  final double size;

  const RunnerWidget({
    Key? key,
    required this.characterId,
    required this.hatId,
    required this.shoesId,
    required this.effectId,
    this.size = 54,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tìm thông tin tương ứng trong cơ sở dữ liệu hằng số
    final char = AppShopItems.characters.firstWhere((c) => c.id == characterId, orElse: () => AppShopItems.characters[0]);
    final hat = AppShopItems.hats.firstWhere((h) => h.id == hatId, orElse: () => AppShopItems.hats[0]);
    final shoes = AppShopItems.shoes.firstWhere((s) => s.id == shoesId, orElse: () => AppShopItems.shoes[0]);
    final effect = AppShopItems.effects.firstWhere((e) => e.id == effectId, orElse: () => AppShopItems.effects[0]);

    // Thiết lập màu sắc và cường độ phát sáng dựa trên hiệu ứng vệt chạy
    Color glowColor = Colors.transparent;
    double glowBlur = 0.0;
    if (effectId == 'effect_fire') {
      glowColor = AppColors.accentPink;
      glowBlur = 12.0;
    } else if (effectId == 'effect_rainbow') {
      glowColor = AppColors.accentCyan;
      glowBlur = 12.0;
    }

    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Vẽ Emoji vệt hiệu ứng bám gót chạy phía sau
          if (effect.assetOrEmoji.isNotEmpty)
            Positioned(
              left: -8,
              bottom: 4,
              child: Text(
                effect.assetOrEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            
          // 2. Avatar tròn nhân vật kèm đường viền và hiệu ứng phát quang
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentCyan, width: 2),
              boxShadow: [
                if (glowColor != Colors.transparent)
                  BoxShadow(
                    color: glowColor,
                    blurRadius: glowBlur,
                    spreadRadius: 2,
                  )
              ],
              color: AppColors.bgSecondary,
            ),
            child: ClipOval(
              child: Image.asset(
                char.assetOrEmoji,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Hiển thị ký tự đầu hoặc icon 👤 nếu chưa tải được asset ảnh
                  return Center(
                    child: Text(
                      char.name.runes.firstOrNull != null 
                          ? String.fromCharCode(char.name.runes.first) 
                          : '👤',
                      style: TextStyle(fontSize: size * 0.4, color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),

          // 3. Mũ (Đặt ở vị trí phía trên đầu avatar)
          if (hat.assetOrEmoji.isNotEmpty)
            Positioned(
              top: -10,
              child: Text(
                hat.assetOrEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),

          // 4. Giày (Đặt ở vị trí góc chân avatar)
          if (shoes.assetOrEmoji.isNotEmpty)
            Positioned(
              bottom: -4,
              right: 6,
              child: Text(
                shoes.assetOrEmoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/shop_items.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';

/// Màn hình Cửa hàng Trang phục & Phụ kiện (Shop Screen)
class ShopScreen extends StatefulWidget {
  final VoidCallback onBackToLobby;

  const ShopScreen({Key? key, required this.onBackToLobby}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final state = gameProvider.state;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgPrimary, AppColors.bgSecondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Shop (Tiêu đề + số vàng hiện có)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: widget.onBackToLobby,
                        ),
                        const SizedBox(width: 8),
                        Text("SHOP", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGold.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: AppColors.accentGold, size: 18),
                          const SizedBox(width: 4),
                          Text("${state.gold}", style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentCyan,
                labelColor: AppColors.accentCyan,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                tabs: const [
                  Tab(text: "Characters"),
                  Tab(text: "Hats"),
                  Tab(text: "Shoes"),
                  Tab(text: "Effects"),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShopGrid(AppShopItems.characters, "character", state),
                    _buildShopGrid(AppShopItems.hats, "hat", state),
                    _buildShopGrid(AppShopItems.shoes, "shoes", state),
                    _buildShopGrid(AppShopItems.effects, "effect", state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopGrid(List<ShopItem> items, String category, var state) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = state.ownedItems.contains(item.id);
        
        bool isEquipped = false;
        if (category == "character") isEquipped = (state.equippedCharacter == item.id);
        else if (category == "hat") isEquipped = (state.equippedHat == item.id);
        else if (category == "shoes") isEquipped = (state.equippedShoes == item.id);
        else if (category == "effect") isEquipped = (state.equippedEffect == item.id);

        return GlassContainer(
          borderColor: isEquipped ? AppColors.accentCyan : AppColors.cardBorder,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Emoji đại diện hoặc Tên
              Expanded(
                child: Center(
                  child: item.assetOrEmoji.contains('/')
                      ? Image.asset(
                          item.assetOrEmoji,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 50, color: AppColors.textSecondary);
                          },
                        )
                      : _getItemGraphic(item),
                ),
              ),
              
              // Tên vật phẩm
              Text(
                item.name,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Nút tương tác Mua / Trang Bị
              SizedBox(
                width: double.infinity,
                child: Builder(builder: (btnContext) {
                  if (isEquipped) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBorder.withOpacity(0.4),
                        foregroundColor: AppColors.textPrimary.withOpacity(0.3),
                        elevation: 0,
                      ),
                      onPressed: null,
                      child: const Text("Equipped", style: TextStyle(fontSize: 12)),
                    );
                  } else if (isOwned) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCyan.withOpacity(0.2),
                        foregroundColor: AppColors.accentCyan,
                        side: const BorderSide(color: AppColors.accentCyan),
                      ),
                      onPressed: () {
                        gameProvider.equipItem(item.id, category);
                      },
                      child: const Text("Equip", style: TextStyle(fontSize: 12)),
                    );
                  } else {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        gameProvider.buyItem(item);
                      },
                      child: Text("Buy ${item.price}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    );
                  }
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getItemGraphic(ShopItem item) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (item.id) {
      // Hats
      case "hat_none":
        iconData = Icons.face_retouching_natural;
        iconColor = AppColors.textSecondary;
        bgColor = AppColors.textSecondary.withOpacity(0.1);
        break;
      case "hat_cowboy":
        iconData = Icons.style_rounded;
        iconColor = Colors.brown;
        bgColor = Colors.brown.withOpacity(0.1);
        break;
      case "hat_crown":
        iconData = Icons.emoji_events_rounded;
        iconColor = AppColors.accentGold;
        bgColor = AppColors.accentGold.withOpacity(0.1);
        break;
        
      // Shoes
      case "shoes_none":
        iconData = Icons.do_not_step;
        iconColor = AppColors.textSecondary;
        bgColor = AppColors.textSecondary.withOpacity(0.1);
        break;
      case "shoes_running":
        iconData = Icons.directions_run_rounded;
        iconColor = AppColors.accentCyan;
        bgColor = AppColors.accentCyan.withOpacity(0.1);
        break;
      case "shoes_gold":
        iconData = Icons.bolt_rounded;
        iconColor = AppColors.accentGold;
        bgColor = AppColors.accentGold.withOpacity(0.1);
        break;
        
      // Effects
      case "effect_none":
        iconData = Icons.blur_off_rounded;
        iconColor = AppColors.textSecondary;
        bgColor = AppColors.textSecondary.withOpacity(0.1);
        break;
      case "effect_fire":
        iconData = Icons.whatshot_rounded;
        iconColor = Colors.redAccent;
        bgColor = Colors.redAccent.withOpacity(0.1);
        break;
      case "effect_rainbow":
        iconData = Icons.looks_rounded;
        iconColor = Colors.purpleAccent;
        bgColor = Colors.purpleAccent.withOpacity(0.1);
        break;
        
      default:
        iconData = Icons.help_outline;
        iconColor = AppColors.textSecondary;
        bgColor = AppColors.textSecondary.withOpacity(0.1);
    }

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 36, color: iconColor),
    );
  }
}

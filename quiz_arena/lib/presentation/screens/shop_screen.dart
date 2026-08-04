import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/shop_items.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';
import '../../data/services/audio_service.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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

              // Tabs (5 Danh mục: Characters, Hats, Shoes, Effects, Tracks)
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentCyan,
                labelColor: AppColors.accentCyan,
                unselectedLabelColor: AppColors.textSecondary,
                isScrollable: true,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: const [
                  Tab(text: "Characters"),
                  Tab(text: "Hats"),
                  Tab(text: "Shoes"),
                  Tab(text: "Effects"),
                  Tab(text: "Tracks 🌌"),
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
                    _buildShopGrid(AppShopItems.tracks, "track", state),
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
        childAspectRatio: 0.76,
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
        else if (category == "track") isEquipped = (state.equippedTrack == item.id);

        Color rarityColor;
        String rarityLabel;
        switch (item.rarity) {
          case ItemRarity.legendary:
            rarityColor = const Color(0xFFFFD700);
            rarityLabel = "LEGENDARY";
            break;
          case ItemRarity.epic:
            rarityColor = const Color(0xFFA020F0);
            rarityLabel = "EPIC";
            break;
          case ItemRarity.rare:
            rarityColor = const Color(0xFF1E90FF);
            rarityLabel = "RARE";
            break;
          case ItemRarity.common:
            rarityColor = Colors.grey;
            rarityLabel = "COMMON";
            break;
        }

        return GlassContainer(
          borderColor: isEquipped ? AppColors.accentCyan : (item.rarity == ItemRarity.legendary ? rarityColor : AppColors.cardBorder),
          child: Stack(
            children: [
              Column(
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

                  if (item.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        item.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 6),

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
                            AudioService().playClick(volume: gameProvider.state.volume);
                            gameProvider.equipItem(item.id, category);
                          },
                          child: const Text("Equip", style: TextStyle(fontSize: 12)),
                        );
                      } else {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rarityColor == const Color(0xFFFFD700) ? AppColors.accentGold : rarityColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final bought = gameProvider.buyItem(item);
                            if (bought) {
                              AudioService().playClaim(volume: gameProvider.state.volume);
                            } else {
                              AudioService().playWrong(volume: gameProvider.state.volume);
                            }
                          },
                          child: Text("Buy ${item.price}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        );
                      }
                    }),
                  ),
                ],
              ),

              // Rarity Badge ở góc trên bên phải
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rarityColor.withOpacity(0.6), width: 1),
                  ),
                  child: Text(
                    rarityLabel,
                    style: TextStyle(color: rarityColor, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _getItemGraphic(ShopItem item) {
    if (item.assetOrEmoji.isNotEmpty && !item.assetOrEmoji.contains('/')) {
      return Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: AppColors.bgSecondary.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            item.assetOrEmoji,
            style: const TextStyle(fontSize: 34),
          ),
        ),
      );
    }

    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.stars, size: 36, color: AppColors.accentCyan),
    );
  }
}

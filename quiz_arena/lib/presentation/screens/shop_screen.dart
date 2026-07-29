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
            colors: [AppColors.bgPrimary, Color(0xFF1E1035)],
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: widget.onBackToLobby,
                        ),
                        const SizedBox(width: 8),
                        Text("CỬA HÀNG", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: AppColors.accentGold, size: 18),
                          const SizedBox(width: 4),
                          Text("${state.gold}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                tabs: const [
                  Tab(text: "Nhân Vật"),
                  Tab(text: "Mũ"),
                  Tab(text: "Giày"),
                  Tab(text: "Hiệu Ứng"),
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
                            return const Icon(Icons.person, size: 50, color: Colors.white70);
                          },
                        )
                      : Text(
                          item.assetOrEmoji.isNotEmpty ? item.assetOrEmoji : "❌",
                          style: const TextStyle(fontSize: 48),
                        ),
                ),
              ),
              
              // Tên vật phẩm
              Text(
                item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white30,
                        elevation: 0,
                      ),
                      onPressed: null,
                      child: const Text("Đang dùng", style: TextStyle(fontSize: 12)),
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
                      child: const Text("Trang bị", style: TextStyle(fontSize: 12)),
                    );
                  } else {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        final success = gameProvider.buyItem(item);
                        if (success) {
                          ScaffoldMessenger.of(btnContext).showSnackBar(
                            SnackBar(content: Text("Chúc mừng! Bạn đã mua thành công ${item.name}!")),
                          );
                        } else {
                          ScaffoldMessenger.of(btnContext).showSnackBar(
                            const SnackBar(content: Text("Bạn không đủ vàng để mua vật phẩm này!")),
                          );
                        }
                      },
                      child: Text("Mua ${item.price}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
}

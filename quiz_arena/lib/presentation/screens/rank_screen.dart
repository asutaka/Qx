import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';

/// Màn hình Bảng xếp hạng (Rank / Leaderboard Screen)
class RankScreen extends StatefulWidget {
  final VoidCallback onBackToLobby;

  const RankScreen({Key? key, required this.onBackToLobby}) : super(key: key);

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getCountryFlag(String code) {
    const flags = {
      'vn': '🇻🇳', 'us': '🇺🇸', 'jp': '🇯🇵', 'kr': '🇰🇷',
      'gb': '🇬🇧', 'fr': '🇫🇷', 'de': '🇩🇪', 'sg': '🇸🇬'
    };
    return flags[code.toLowerCase()] ?? '🏳️';
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final state = gameProvider.state;

    // Giả lập danh sách Leaderboard
    final List<Map<String, dynamic>> singleRankList = [
      {'name': 'Alex 🇺🇸', 'score': 54, 'title': 'Chuyên gia'},
      {'name': 'Yuki 🇯🇵', 'score': 42, 'title': 'Có hiểu biết'},
      {'name': state.nickname + ' ' + _getCountryFlag(state.country), 'score': state.singleHighScore, 'title': 'Newbie', 'isMe': true},
      {'name': 'Min-jun 🇰🇷', 'score': 31, 'title': 'Tập sự'},
      {'name': 'Hans 🇩🇪', 'score': 18, 'title': 'Tập sự'},
    ];

    // Sắp xếp lại Single Rank theo điểm số
    singleRankList.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final List<Map<String, dynamic>> goldRankList = [
      {'name': 'Yuki 🇯🇵', 'gold': 12500, 'title': 'Nhà thông thái'},
      {'name': 'Alex 🇺🇸', 'gold': 9800, 'title': 'Chuyên gia'},
      {'name': 'Min-jun 🇰🇷', 'gold': 5000, 'title': 'Có hiểu biết'},
      {'name': state.nickname + ' ' + _getCountryFlag(state.country), 'gold': state.gold, 'title': 'Newbie', 'isMe': true},
      {'name': 'Hans 🇩🇪', 'gold': 1800, 'title': 'Tập sự'},
    ];

    // Sắp xếp lại Gold Rank theo vàng
    goldRankList.sort((a, b) => (b['gold'] as int).compareTo(a['gold'] as int));

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
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBackToLobby,
                    ),
                    const SizedBox(width: 8),
                    Text("BẢNG XẾP HẠNG", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan)),
                  ],
                ),
              ),

              // Tab Selector
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentCyan,
                labelColor: AppColors.accentCyan,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: "Kỷ lục chơi đơn"),
                  Tab(text: "Tích lũy vàng"),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRankList(singleRankList, "score"),
                    _buildRankList(goldRankList, "gold"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankList(List<Map<String, dynamic>> ranks, String key) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranks.length,
      itemBuilder: (context, index) {
        final entry = ranks[index];
        final isMe = entry['isMe'] == true;

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          borderColor: isMe ? AppColors.accentCyan : AppColors.cardBorder,
          backgroundColor: isMe ? AppColors.accentCyan.withOpacity(0.08) : null,
          child: Row(
            children: [
              // Xếp hạng (Huy chương)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0 
                      ? AppColors.accentGold 
                      : (index == 1 ? const Color(0xFFC0C0C0) : (index == 2 ? const Color(0xFFCD7F32) : Colors.white10)),
                ),
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    color: index < 3 ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Tên & danh hiệu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['name'],
                      style: TextStyle(
                        color: isMe ? AppColors.accentCyan : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry['title'],
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Điểm số / Vàng
              Row(
                children: [
                  if (key == "gold")
                    const Icon(Icons.monetization_on, color: AppColors.accentGold, size: 16)
                  else
                    const Icon(Icons.star, color: AppColors.accentCyan, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${entry[key]}",
                    style: TextStyle(
                      color: key == "gold" ? AppColors.accentGold : AppColors.accentCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

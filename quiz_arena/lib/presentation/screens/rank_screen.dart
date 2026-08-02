import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../widgets/glass_container.dart';
import '../../data/services/firebase_service.dart';

/// Màn hình Bảng xếp hạng (Rank / Leaderboard Screen) kết nối trực tiếp với Firestore
class RankScreen extends StatefulWidget {
  final VoidCallback onBackToLobby;

  const RankScreen({Key? key, required this.onBackToLobby}) : super(key: key);

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final uId = await FirebaseService().getOrCreateUserId();
    if (mounted) {
      setState(() {
        _currentUserId = uId;
      });
    }
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

  String _getRankTitle(int score) {
    if (score >= 90) return 'Wizard 🧙‍♂️';
    if (score >= 75) return 'Sage 🧠';
    if (score >= 55) return 'Expert 🎓';
    if (score >= 35) return 'Knowledgeable 📚';
    if (score >= 15) return 'Apprentice 🛡️';
    return 'Newbie 🌱';
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: widget.onBackToLobby,
                    ),
                    const SizedBox(width: 8),
                    Text("LEADERBOARD", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan)),
                  ],
                ),
              ),

              // Tab Selector
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentCyan,
                labelColor: AppColors.accentCyan,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                tabs: const [
                  Tab(text: "Single High Score"),
                  Tab(text: "Gold Balance"),
                ],
              ),
              const SizedBox(height: 12),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardTab("singleHighScore"),
                    _buildLeaderboardTab("gold"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget FutureBuilder tải bảng xếp hạng trực tiếp từ Firestore
  Widget _buildLeaderboardTab(String fieldName) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .orderBy(fieldName, descending: true)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
            ),
          );
        }
        if (snapshot.hasError) {
          // Trường hợp thiếu chỉ mục (Index) trên Firestore
          if (snapshot.error.toString().contains("FAILED_PRECONDITION")) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "Initializing Firestore index for Leaderboard. Please try again in a few minutes!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.accentGold),
                ),
              ),
            );
          }
          return Center(
            child: Text(
              "Error loading leaderboard: ${snapshot.error}",
              style: const TextStyle(color: AppColors.incorrectRed),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No leaderboard data available.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return _buildRankList(docs, fieldName);
      },
    );
  }

  /// Hàm xây dựng danh sách Widget xếp hạng thực tế
  Widget _buildRankList(List<QueryDocumentSnapshot> docs, String key) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final isMe = doc.id == _currentUserId;

        final nickname = data['nickname'] ?? 'Player';
        final country = data['country'] ?? 'vn';
        final score = data['singleHighScore'] ?? 0;
        final gold = data['gold'] ?? 0;
        final title = _getRankTitle(score);

        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 12),
          borderColor: isMe ? AppColors.accentCyan : AppColors.cardBorder,
          backgroundColor: isMe ? AppColors.accentCyan.withOpacity(0.08) : null,
          child: Row(
            children: [
              // Thứ hạng (Huy chương)
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == 0 
                      ? AppColors.accentGold 
                      : (index == 1 ? const Color(0xFFC0C0C0) : (index == 2 ? const Color(0xFFCD7F32) : AppColors.cardBorder)),
                ),
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    color: index < 3 ? Colors.black : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Tên người chơi & danh hiệu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nickname,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isMe ? AppColors.accentCyan : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(_getCountryFlag(country), style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Trực quan hóa giá trị (Vàng / Sao kỉ lục)
              Row(
                children: [
                  if (key == "gold")
                    const Icon(Icons.monetization_on, color: AppColors.accentGold, size: 16)
                  else
                    const Icon(Icons.star, color: AppColors.accentCyan, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${key == 'gold' ? gold : score}",
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/runner_widget.dart';
import '../../data/services/crazy_games_service.dart';

/// Màn hình Sảnh chính (Lobby Screen) chứa các lựa chọn chế độ chơi và quà tặng.
class LobbyScreen extends StatefulWidget {
  final VoidCallback onStartSingle;
  final VoidCallback onStartBattle;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenRank;

  const LobbyScreen({
    Key? key,
    required this.onStartSingle,
    required this.onStartBattle,
    required this.onOpenShop,
    required this.onOpenSettings,
    required this.onOpenRank,
  }) : super(key: key);

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  Timer? _countdownTimer;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    // Kích hoạt bộ đếm thời gian thực để cập nhật nút xem quảng cáo mỗi giây
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Trả về emoji cờ quốc kỳ từ mã quốc gia
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

  /// Giả lập hiển thị quảng cáo xem thưởng trong 5 giây
  void _showSimulatedAd(BuildContext context, VoidCallback onComplete) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Ad",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _SimulatedAdDialog(onComplete: onComplete);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final state = gameProvider.state;

    // Tính toán thời gian quà tặng
    final now = DateTime.now().millisecondsSinceEpoch;
    const oneDay = 24 * 60 * 60 * 1000;
    const adCooldown = 900 * 1000; // 15 phút (900 giây)

    final bool dailyReady = (now - state.lastDailyClaim >= oneDay);
    final bool adReady = (now - state.lastAdClaim >= adCooldown);

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Thông tin người chơi) - Sticky at top
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        RunnerWidget(
                          characterId: state.equippedCharacter,
                          hatId: state.equippedHat,
                          shoesId: state.equippedShoes,
                          effectId: state.equippedEffect,
                          size: 40,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  state.nickname, 
                                  style: AppTypography.subtitleStyle.copyWith(
                                    color: AppColors.textPrimary, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(_getCountryFlag(state.country), style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            Text(
                              _getRankTitle(state.singleHighScore).toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: AppColors.accentCyan, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Nút Vàng
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentGold, width: 1.5),
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
                          Text(
                            "${state.gold}", 
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Game Billboard / Banner
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(color: AppColors.cardBorder.withOpacity(0.6)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.emoji_events, color: AppColors.accentGold, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "QUIZ ARENA CHAMPIONS",
                                      style: AppTypography.titleStyle.copyWith(
                                        fontSize: 16,
                                        color: AppColors.accentGold,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Test your knowledge & run to victory!",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Battle Mode Card
                        GestureDetector(
                          onTap: () {
                            if (state.gold >= 200) {
                              gameProvider.deductGold(200);
                              widget.onStartBattle();
                            }
                          },
                          child: Container(
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFF8E24AA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE91E63).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -10,
                                  bottom: -20,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white30, width: 2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          "assets/characters/char_wukong.webp",
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, st) => const Icon(Icons.flash_on, color: Colors.white, size: 40),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "REALTIME PvP",
                                          style: TextStyle(
                                            color: Colors.white, 
                                            fontSize: 9, 
                                            fontWeight: FontWeight.bold, 
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "BATTLE MODE",
                                        style: AppTypography.titleStyle.copyWith(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          shadows: const [
                                            Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "1v1 Racing Battle (200 Gold Entry Fee)",
                                        style: AppTypography.bodyStyle.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Single Mode Card
                        GestureDetector(
                          onTap: widget.onStartSingle,
                          child: Container(
                            height: 120,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCFF), Color(0xFF0056E0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00BCFF).withOpacity(0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -10,
                                  bottom: -20,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white30, width: 2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          "assets/characters/char_tu_ha.webp",
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, st) => const Icon(Icons.person, color: Colors.white, size: 40),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          "CHALLENGE MODE",
                                          style: TextStyle(
                                            color: Colors.white, 
                                            fontSize: 9, 
                                            fontWeight: FontWeight.bold, 
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "SINGLE MODE",
                                        style: AppTypography.titleStyle.copyWith(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          shadows: const [
                                            Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "100 Progressive Questions (Offline / Online)",
                                        style: AppTypography.bodyStyle.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        GlassContainer(
                          borderColor: dailyReady 
                              ? AppColors.accentGold.withOpacity(0.5) 
                              : (adReady ? AppColors.accentPink.withOpacity(0.5) : AppColors.cardBorder),
                          child: Row(
                            children: [
                              const Icon(Icons.card_giftcard, color: AppColors.accentGold, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Daily Gift", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text(
                                      dailyReady ? "Get 1,000 gold daily" : "Watch ad to get +500 gold",
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Nút tương tác
                              Builder(builder: (btnContext) {
                                if (dailyReady) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGold,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      gameProvider.claimDaily();
                                    },
                                    child: const Text("Claim 1,000"),
                                  );
                                } else if (adReady) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.accentPink, Color(0xFF8A2BE2)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.accentPink.withOpacity(0.4), blurRadius: 8),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: _isAdLoading ? null : () async {
                                        if (mounted) {
                                          setState(() {
                                            _isAdLoading = true;
                                          });
                                        }
                                        final success = await CrazyGamesService.showAd("rewarded");
                                        if (mounted) {
                                          setState(() {
                                            _isAdLoading = false;
                                          });
                                        }
                                        if (success) {
                                          gameProvider.claimAd();
                                        }
                                      },
                                      child: _isAdLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text("Watch Ad +500 🎬"),
                                    ),
                                  );
                                } else {
                                  // Đếm ngược
                                  final secondsLeft = ((adCooldown - (now - state.lastAdClaim)) / 1000).ceil();
                                  String timeText = "${secondsLeft}s";
                                  if (secondsLeft >= 60) {
                                    final mins = secondsLeft ~/ 60;
                                    final secs = secondsLeft % 60;
                                    timeText = "${mins}m ${secs}s";
                                  }

                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentPink.withOpacity(0.1),
                                      foregroundColor: AppColors.textPrimary.withOpacity(0.4),
                                      disabledBackgroundColor: AppColors.accentPink.withOpacity(0.1),
                                      disabledForegroundColor: AppColors.textPrimary.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(color: AppColors.accentPink.withOpacity(0.2)),
                                      ),
                                    ),
                                    onPressed: null, // Vô hiệu hóa khi đang cooldown
                                    child: Text("Watch Ad +500 ($timeText)", style: const TextStyle(fontSize: 11)),
                                  );
                                }
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Bottom Navigation Bar - Sticky at bottom
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavTab(Icons.home, "Lobby", true, () {}),
                      _buildNavTab(Icons.shopping_bag, "Shop", false, widget.onOpenShop),
                      _buildNavTab(Icons.emoji_events, "Rank", false, widget.onOpenRank),
                      _buildNavTab(Icons.settings, "Settings", false, widget.onOpenSettings),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(IconData icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.accentPink.withOpacity(0.15),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: active ? AppColors.accentPink : AppColors.textSecondary,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? AppColors.accentPink : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog quảng cáo mô phỏng đếm ngược 5 giây
class _SimulatedAdDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const _SimulatedAdDialog({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<_SimulatedAdDialog> createState() => _SimulatedAdDialogState();
}

class _SimulatedAdDialogState extends State<_SimulatedAdDialog> {
  int _secondsLeft = 5;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _adTimer?.cancel();
        Navigator.of(context).pop(); // Đóng Ad Dialog
        widget.onComplete();         // Gọi hàm cộng thưởng
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (5 - _secondsLeft) / 5.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie, color: AppColors.accentPink, size: 80),
              const SizedBox(height: 24),
              const Text(
                "ADVERTISEMENT PLAYING",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                "Remaining: $_secondsLeft seconds",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

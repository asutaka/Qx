import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';

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
            colors: [AppColors.bgPrimary, Color(0xFF1E1035)],
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
                // 1. Header (Thông tin người chơi)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.accentCyan,
                          radius: 20,
                          child: Text(
                            state.nickname.isNotEmpty ? state.nickname[0].toUpperCase() : 'P',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(state.nickname, style: AppTypography.subtitleStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Text(_getCountryFlag(state.country), style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            const Text("NEWBIE", style: TextStyle(fontSize: 10, color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    
                    // Nút Vàng
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
                const SizedBox(height: 24),

                // 2. Chế độ chơi Battle Mode Card
                GestureDetector(
                  onTap: widget.onStartBattle,
                  child: GlassContainer(
                    borderColor: AppColors.accentPink.withOpacity(0.4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("BATTLE MODE", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentPink)),
                              const SizedBox(height: 4),
                              Text("Đối kháng 1v1 chạy đua (Đặt cọc 200 vàng)", style: AppTypography.bodyStyle.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.flash_on, color: AppColors.accentPink, size: 40),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Chế độ chơi Single Mode Card
                GestureDetector(
                  onTap: widget.onStartSingle,
                  child: GlassContainer(
                    borderColor: AppColors.accentCyan.withOpacity(0.4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("SINGLE MODE", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan)),
                              const SizedBox(height: 4),
                              Text("Ai là triệu phú 100 câu hỏi (Offline / Online)", style: AppTypography.bodyStyle.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.person, color: AppColors.accentCyan, size: 40),
                      ],
                    ),
                  ),
                ),
                const Spacer(),

                // 4. Daily Gift Banner (2 chức năng kết hợp đếm ngược 15 phút)
                GlassContainer(
                  borderColor: dailyReady 
                      ? AppColors.accentGold.withOpacity(0.4) 
                      : (adReady ? AppColors.accentPink.withOpacity(0.4) : Colors.white10),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard, color: AppColors.accentGold, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Daily Gift", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(
                              dailyReady ? "Mỗi ngày tặng 1000 vàng" : "Xem quảng cáo nhận thêm 500 vàng",
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
                              ScaffoldMessenger.of(btnContext).showSnackBar(
                                const SnackBar(content: Text("Bạn đã nhận quà đăng nhập hàng ngày: 1,000 Vàng!")),
                              );
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
                              onPressed: () {
                                _showSimulatedAd(btnContext, () {
                                  gameProvider.claimAd();
                                  ScaffoldMessenger.of(btnContext).showSnackBar(
                                    const SnackBar(content: Text("Bạn đã nhận thêm 500 Vàng nhờ xem quảng cáo!")),
                                  );
                                });
                              },
                              child: const Text("Xem QC +500 🎬"),
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
                              foregroundColor: Colors.white30,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppColors.accentPink.withOpacity(0.2)),
                              ),
                            ),
                            onPressed: null, // Vô hiệu hóa khi đang cooldown
                            child: Text("Xem QC +500 ($timeText)", style: const TextStyle(fontSize: 11)),
                          );
                        }
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Bottom Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavTab(Icons.home, "Sảnh", true, () {}),
                    _buildNavTab(Icons.shopping_bag, "Cửa Hàng", false, widget.onOpenShop),
                    _buildNavTab(Icons.emoji_events, "Hạng", false, widget.onOpenRank),
                    _buildNavTab(Icons.settings, "Cài Đặt", false, widget.onOpenSettings),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTab(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: active ? AppColors.accentPink : AppColors.textSecondary, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.accentPink : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
                "QUẢNG CÁO ĐANG PHÁT",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                "Còn lại $_secondsLeft giây",
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

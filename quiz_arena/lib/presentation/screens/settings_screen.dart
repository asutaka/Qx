import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';

/// Màn hình Cài đặt (Settings Screen)
class SettingsScreen extends StatefulWidget {
  final VoidCallback onBackToLobby;

  const SettingsScreen({Key? key, required this.onBackToLobby}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  String _selectedCountry = 'vn';
  int _volume = 80;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GameProvider>(context, listen: false);
    _nicknameController.text = provider.state.nickname;
    _selectedCountry = provider.state.country;
    _volume = provider.state.volume;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  final Map<String, String> _countries = {
    'vn': 'Việt Nam 🇻🇳',
    'us': 'United States 🇺🇸',
    'jp': 'Japan 🇯🇵',
    'kr': 'South Korea 🇰🇷',
    'gb': 'United Kingdom 🇬🇧',
    'fr': 'France 🇫🇷',
    'de': 'Germany 🇩🇪',
    'sg': 'Singapore 🇸🇬',
  };

  void _saveSettings(BuildContext context) {
    final provider = Provider.of<GameProvider>(context, listen: false);
    provider.updateNickname(_nicknameController.text);
    provider.updateCountry(_selectedCountry);
    provider.updateVolume(_volume);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã lưu các cài đặt thành công!")),
    );
    widget.onBackToLobby();
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Cài đặt
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBackToLobby,
                    ),
                    const SizedBox(width: 8),
                    Text("CÀI ĐẶT DỰ ÁN", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan)),
                  ],
                ),
                const SizedBox(height: 24),

                Expanded(
                  child: ListView(
                    children: [
                      // 1. Nickname
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TÊN NGƯỜI CHƠI", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nicknameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Nhập tên của bạn",
                                hintStyle: const TextStyle(color: Colors.white30),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.cardBorder)),
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentCyan)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Chọn Quốc Kỳ (Huy hiệu Leaderboard)
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("QUỐC GIA hiển thị", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: AppColors.bgSecondary,
                              ),
                              child: DropdownButton<String>(
                                value: _selectedCountry,
                                dropdownColor: AppColors.bgSecondary,
                                style: const TextStyle(color: Colors.white),
                                isExpanded: true,
                                underline: Container(height: 1, color: AppColors.cardBorder),
                                items: _countries.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedCountry = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. Âm lượng nhạc nền
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("ÂM LƯỢNG NHẠC NỀN", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text("$_volume%", style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _volume.toDouble(),
                              min: 0,
                              max: 100,
                              activeColor: AppColors.accentCyan,
                              inactiveColor: AppColors.cardBorder,
                              onChanged: (val) {
                                setState(() {
                                  _volume = val.round();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút Lưu thay đổi
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _saveSettings(context),
                  child: const Text("LƯU CÀI ĐẶT", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

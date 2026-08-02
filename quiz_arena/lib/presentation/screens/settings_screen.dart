import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';
import '../../data/services/translation_service.dart';

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
  String _selectedLanguage = 'en';
  int _volume = 80;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GameProvider>(context, listen: false);
    _nicknameController.text = provider.state.nickname;
    _selectedCountry = provider.state.country;
    _selectedLanguage = provider.state.targetLanguage;
    _volume = provider.state.volume;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  final Map<String, String> _countries = {
    'vn': 'Vietnam 🇻🇳',
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
    final String newLanguage = _selectedLanguage;

    provider.updateNickname(_nicknameController.text);
    provider.updateCountry(_selectedCountry);
    provider.updateTargetLanguage(newLanguage);
    provider.updateVolume(_volume);

    // Bắt đầu tải ngầm gói dịch thuật offline nếu chưa được tải trước đó
    if (newLanguage != 'en' && !provider.state.downloadedLanguages.contains(newLanguage)) {
      TranslationService().downloadLanguageModelInBackground(newLanguage, (success) {
        if (success) {
          provider.downloadLanguagePackage(newLanguage);
        }
      });
    }
    
    widget.onBackToLobby();
  }

  Widget _buildPackageDownloadRow(BuildContext context, String langCode, String langName, bool isDownloaded) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(langName, style: const TextStyle(color: Colors.white, fontSize: 13)),
        isDownloaded
            ? const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.correctGreen, size: 16),
                  SizedBox(width: 4),
                  Text("Ready (Offline)", style: TextStyle(color: AppColors.correctGreen, fontSize: 12)),
                ],
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan.withOpacity(0.1),
                  foregroundColor: AppColors.accentCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _downloadPackageSimulation(context, langCode),
                icon: const Icon(Icons.download, size: 14),
                label: const Text("Download package", style: TextStyle(fontSize: 11)),
              ),
      ],
    );
  }

  void _downloadPackageSimulation(BuildContext context, String langCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        double progress = 0.0;
        Timer? dialogTimer;
        bool isDone = false;

        // Gọi tải gói ngôn ngữ thật từ ML Kit (hoặc API giả lập trên Web)
        TranslationService().downloadLanguageModelInBackground(langCode, (success) {
          isDone = true;
        });

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            dialogTimer ??= Timer.periodic(const Duration(milliseconds: 200), (t) {
              if (progress < 0.9) {
                progress += 0.05;
                setDialogState(() {});
              } else if (isDone) {
                progress = 1.0;
                setDialogState(() {});
                t.cancel();
                Navigator.of(ctx).pop();
                
                final provider = Provider.of<GameProvider>(context, listen: false);
                provider.downloadLanguagePackage(langCode);
              }
            });

            return AlertDialog(
              backgroundColor: AppColors.bgSecondary,
              title: const Text("DOWNLOAD TRANSLATION PACKAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Downloading offline translation package for $langCode..."),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                  ),
                  const SizedBox(height: 8),
                  Text("${(progress * 100).toInt()}%", style: const TextStyle(color: AppColors.accentCyan)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
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
                    Text("SETTINGS", style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan)),
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
                            const Text("PLAYER NICKNAME", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nicknameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Enter your nickname",
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
                            const Text("DISPLAY COUNTRY", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
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
 
                      // 2.5. Ngôn ngữ dịch thuật (Target Translation Language)
                      GlassContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("TRANSLATION TARGET LANGUAGE (Google ML Kit)", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Theme(
                              data: Theme.of(context).copyWith(
                                canvasColor: AppColors.bgSecondary,
                              ),
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                dropdownColor: AppColors.bgSecondary,
                                style: const TextStyle(color: Colors.white),
                                isExpanded: true,
                                underline: Container(height: 1, color: AppColors.cardBorder),
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: 'en',
                                    child: Text("English 🇬🇧"),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'vi',
                                    child: Text("Vietnamese 🇻🇳"),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedLanguage = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text("OFFLINE TRANSLATION PACKAGES", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10)),
                            const SizedBox(height: 8),
                            _buildPackageDownloadRow(context, "en", "English 🇬🇧", true),
                            const SizedBox(height: 8),
                            _buildPackageDownloadRow(context, "vi", "Vietnamese 🇻🇳", gameProvider.state.downloadedLanguages.contains("vi")),
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
                                const Text("BACKGROUND MUSIC VOLUME", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  child: const Text("SAVE SETTINGS", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

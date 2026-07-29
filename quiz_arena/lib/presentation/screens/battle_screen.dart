import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/models/question.dart';
import '../../data/models/trivia_category.dart';
import '../../data/models/trivia_difficulty.dart';
import '../../data/services/trivia_api_service.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/runner_widget.dart';
import '../../data/services/translation_service.dart';

/// Màn hình Đua đối kháng Battle Mode 1v1 (Player vs Bot)
class BattleScreen extends StatefulWidget {
  final VoidCallback onBackToLobby;

  const BattleScreen({Key? key, required this.onBackToLobby}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  // Trạng thái chung
  bool _isLoading = true;
  bool _isMatchmaking = true;
  int _matchmakingSec = 3;
  Timer? _matchmakingTimer;

  // Dữ liệu trận đấu
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _playerScore = 0;
  int _botScore = 0;

  // Vật phẩm của Bot (Ngẫu nhiên)
  late String _botCharId;
  late String _botHatId;
  late String _botShoesId;
  late String _botEffectId;

  // Bộ đếm thời gian trả lời
  int _secondsLeft = 30;
  Timer? _questionTimer;
  Timer? _botActionTimer;
  bool _hasAnswered = false;
  String? _selectedAnswer;
  bool _showingAnswerResult = false;

  // Dịch thuật
  bool _isTranslating = false;
  bool _isTranslated = false;
  String? _translatedQuestion;
  Map<String, String> _translatedAnswers = {};

  @override
  void initState() {
    super.initState();
    _initBotCosmetics();
    _startMatchmaking();
    _loadQuestions();
  }

  @override
  void dispose() {
    _matchmakingTimer?.cancel();
    _questionTimer?.cancel();
    _botActionTimer?.cancel();
    super.dispose();
  }

  /// Khởi tạo trang phục ngẫu nhiên cho Bot
  void _initBotCosmetics() {
    _botCharId = "char_wukong";
    _botHatId = "hat_cowboy";
    _botShoesId = "shoes_running";
    _botEffectId = "effect_fire";
  }

  /// Bắt đầu đếm ngược tìm đối thủ
  void _startMatchmaking() {
    _matchmakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_matchmakingSec > 1) {
        setState(() {
          _matchmakingSec--;
        });
      } else {
        _matchmakingTimer?.cancel();
        setState(() {
          _isMatchmaking = false;
        });
        _startQuestionRound();
      }
    });
  }

  /// Tải câu hỏi từ API OTDB (Không truyền độ khó để tải ngẫu nhiên)
  Future<void> _loadQuestions() async {
    final api = TriviaApiService();
    final data = await api.fetchQuestions(
      amount: 10,
      category: TriviaCategory.any,
      difficulty: TriviaDifficulty.any,
    );

    if (data != null && data['results'] != null) {
      final results = data['results'] as List;
      _questions = results.map((q) => Question.fromJson(q)).toList();
    }

    setState(() {
      _isLoading = false;
    });

    // Nếu tải lỗi hoặc không có câu hỏi, tự tạo danh sách câu hỏi dự phòng
    if (_questions.isEmpty) {
      _questions = List.generate(
        10,
        (index) => Question(
          questionText: "Placeholder Question ${index + 1}: What is the capital of France?",
          correctAnswer: "Paris",
          allAnswers: ["Paris", "London", "Berlin", "Rome"],
        ),
      );
    }
  }

  Future<void> _toggleTranslation() async {
    if (_isTranslated) {
      setState(() {
        _isTranslated = false;
      });
      return;
    }

    if (_translatedQuestion != null) {
      setState(() {
        _isTranslated = true;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    final currentQuestion = _questions[_currentQuestionIndex];
    final translator = TranslationService();

    try {
      final transQ = await translator.translate(currentQuestion.questionText);
      final Map<String, String> transAns = {};
      for (final answer in currentQuestion.allAnswers) {
        final transA = await translator.translate(answer);
        transAns[answer] = transA;
      }

      if (mounted) {
        setState(() {
          _translatedQuestion = transQ;
          _translatedAnswers = transAns;
          _isTranslated = true;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối dịch thuật. Vui lòng thử lại!")),
        );
      }
    }
  }

  /// Bắt đầu một vòng câu hỏi mới
  void _startQuestionRound() {
    if (_currentQuestionIndex >= _questions.length || _playerScore >= 10 || _botScore >= 10) {
      _endGame();
      return;
    }

    setState(() {
      _secondsLeft = 30;
      _hasAnswered = false;
      _selectedAnswer = null;
      _showingAnswerResult = false;
      _isTranslated = false;
      _translatedQuestion = null;
      _translatedAnswers.clear();
    });

    // Chạy đếm ngược trả lời câu hỏi
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _questionTimer?.cancel();
        _revealAnswer(null); // Quá giờ trả lời
      }
    });

    // Mô phỏng Bot tự suy nghĩ trả lời ngẫu nhiên
    _botActionTimer?.cancel();
    _botActionTimer = Timer(Duration(seconds: 4 + (DateTime.now().millisecond % 8)), () {
      if (!_showingAnswerResult && mounted) {
        // Tỷ lệ Bot trả lời đúng là 65%
        final botCorrect = (DateTime.now().millisecond % 100) < 65;
        if (botCorrect) {
          setState(() {
            _botScore++;
          });
        }
      }
    });
  }

  /// Chọn đáp án
  void _selectAnswerOption(String option) {
    if (_hasAnswered || _showingAnswerResult) return;
    _revealAnswer(option);
  }

  /// Hiển thị đáp án đúng và tạm dừng 5 giây trước khi sang câu kế tiếp
  void _revealAnswer(String? playerAnswer) {
    _questionTimer?.cancel();
    setState(() {
      _hasAnswered = true;
      _selectedAnswer = playerAnswer;
      _showingAnswerResult = true;

      // Cộng điểm cho Player nếu trả lời đúng
      if (playerAnswer != null && playerAnswer == _questions[_currentQuestionIndex].correctAnswer) {
        _playerScore++;
      }
    });

    // Dừng 5 giây xem kết quả đáp án rồi chuyển sang câu mới
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentQuestionIndex++;
        });
        _startQuestionRound();
      }
    });
  }

  /// Kết thúc trận đấu
  void _endGame() {
    _questionTimer?.cancel();
    _botActionTimer?.cancel();

    final isWin = _playerScore > _botScore;
    final provider = Provider.of<GameProvider>(context, listen: false);

    // Xử lý thưởng vàng đặt cược
    if (isWin) {
      provider.updateHighScore(_playerScore);
      // Đấu thắng nhận 400 vàng (hoàn cọc 200 + thưởng 200)
      provider.claimAd(); // Thay đổi nhỏ cộng tiền
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text(
          isWin ? "🏆 CHIẾN THẮNG!" : "💀 THẤT BẠI!",
          style: TextStyle(color: isWin ? AppColors.accentCyan : AppColors.accentPink, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isWin 
              ? "Bạn đã vượt qua đối thủ với tỉ số $_playerScore - $_botScore.\nBạn nhận được +400 Vàng!"
              : "Bạn đã thua cuộc trước đối thủ với tỉ số $_playerScore - $_botScore.\nBạn bị mất 200 Vàng tiền cọc!",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBackToLobby();
            },
            child: const Text("Về Sảnh", style: TextStyle(color: AppColors.accentCyan)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMatchmaking) {
      return _buildMatchmakingView();
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan)),
        ),
      );
    }

    final gameProvider = Provider.of<GameProvider>(context);
    final playerState = gameProvider.state;
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Battle Info Bar (Số câu hỏi + Giây đếm ngược)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Câu ${_currentQuestionIndex + 1} / 10", style: AppTypography.subtitleStyle.copyWith(color: Colors.white)),
                  Text(
                    "$_secondsLeft s",
                    style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan),
                  ),
                ],
              ),
            ),

            // 2. Race Tracks (Đường đua xe 1v1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;
                  const runnerWidth = 64.0;
                  
                  // Tính vị trí left chạy của nhân vật dựa trên điểm số
                  final playerLeft = (_playerScore / 10.0) * (trackWidth - runnerWidth);
                  final botLeft = (_botScore / 10.0) * (trackWidth - runnerWidth);

                  return GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🏁 ĐƯỜNG ĐUA BATTLE", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // Làn của người chơi
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(playerState.nickname, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                Text("$_playerScore/10", style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 500),
                                    left: playerLeft,
                                    top: 2,
                                    child: RunnerWidget(
                                      characterId: playerState.equippedCharacter,
                                      hatId: playerState.equippedHat,
                                      shoesId: playerState.equippedShoes,
                                      effectId: playerState.equippedEffect,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Làn của Bot
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("BetaTester 🇺🇸", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text("$_botScore/10", style: TextStyle(color: AppColors.accentPink, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 500),
                                    left: botLeft,
                                    top: 2,
                                    child: RunnerWidget(
                                      characterId: _botCharId,
                                      hatId: _botHatId,
                                      shoesId: _botShoesId,
                                      effectId: _botEffectId,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 2.5 Translation toggle bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTranslated ? AppColors.accentPink.withOpacity(0.2) : AppColors.cardBg,
                    foregroundColor: _isTranslated ? AppColors.accentPink : Colors.white,
                    side: BorderSide(color: _isTranslated ? AppColors.accentPink : AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: _isTranslating ? null : _toggleTranslation,
                  icon: _isTranslating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Icon(Icons.translate, size: 16),
                  label: Text(_isTranslated ? "Gốc (English)" : "Dịch (Vietnamese)", style: const TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 3. Question Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    GlassContainer(
                      width: double.infinity,
                      child: Text(
                        _isTranslated && _translatedQuestion != null
                            ? _translatedQuestion!
                            : currentQuestion.questionText,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Options
                    ...currentQuestion.allAnswers.map((option) {
                      Color btnColor = AppColors.cardBg;
                      Color txtColor = Colors.white;

                      if (_showingAnswerResult) {
                        if (option == currentQuestion.correctAnswer) {
                          btnColor = AppColors.correctGreen.withOpacity(0.3);
                          txtColor = AppColors.correctGreen;
                        } else if (option == _selectedAnswer) {
                          btnColor = AppColors.incorrectRed.withOpacity(0.3);
                          txtColor = AppColors.incorrectRed;
                        }
                      } else if (option == _selectedAnswer) {
                        btnColor = AppColors.accentCyan.withOpacity(0.2);
                        txtColor = AppColors.accentCyan;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnColor,
                              foregroundColor: txtColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _showingAnswerResult && option == currentQuestion.correctAnswer
                                      ? AppColors.correctGreen
                                      : (_selectedAnswer == option ? AppColors.accentCyan : AppColors.cardBorder),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onPressed: _showingAnswerResult ? null : () => _selectAnswerOption(option),
                            child: Text(
                               _isTranslated && _translatedAnswers.containsKey(option)
                                   ? _translatedAnswers[option]!
                                   : option,
                               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                             ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trực quan hóa Giao diện Tìm kiếm Đối thủ (Matchmaking)
  Widget _buildMatchmakingView() {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_find, color: AppColors.accentCyan, size: 80),
              const SizedBox(height: 24),
              Text(
                "ĐANG TÌM ĐỐI THỦ...",
                style: AppTypography.titleStyle.copyWith(fontSize: 20, color: AppColors.accentCyan),
              ),
              const SizedBox(height: 12),
              Text(
                "Trận đấu sẽ bắt đầu sau $_matchmakingSec giây",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPink)),
            ],
          ),
        ),
      ),
    );
  }
}

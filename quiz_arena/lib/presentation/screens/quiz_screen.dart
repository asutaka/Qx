import 'dart:async';
import 'dart:ui';
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
import '../../data/services/translation_service.dart';
import '../../data/services/audio_service.dart';

/// Màn hình Chơi đơn Single Mode (Ai Là Triệu Phú - 100 câu hỏi khó dần)
class QuizScreen extends StatefulWidget {
  final VoidCallback onBackToLobby;

  const QuizScreen({Key? key, required this.onBackToLobby}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  
  // Thời gian
  int _secondsLeft = 30;
  Timer? _timer;
  
  // Trợ giúp cơ bản
  bool _hasAnswered = false;
  String? _selectedAnswer;
  bool _showingResult = false;
  
  // Quyền cứu trợ 50/50
  bool _is5050Used = false;
  List<String> _hiddenOptions = [];

  // Quyền cứu trợ mới
  bool _isDoubleAnswerUsed = false; // Đã dùng Trả lời 2 lần chưa
  bool _isDoubleAnswerActive = false; // Trạng thái đang kích hoạt Double Answer cho câu hiện tại
  List<String> _wrongGuesses = []; // Danh sách các phương án đoán sai của câu này
  bool _isChangeQuestionUsed = false; // Đã dùng Đổi câu hỏi chưa

  // Dịch thuật
  bool _isTranslating = false;
  bool _isTranslated = false;
  String? _translatedQuestion;
  Map<String, String> _translatedAnswers = {};

  // Streak Combo
  int _streakCount = 0;
  int _maxStreak = 0;
  String? _comboText;
  Color _comboColor = Colors.orange;
  bool _showComboBadge = false;

  @override
  void initState() {
    super.initState();
    _loadDifficultyQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Tải câu hỏi thích ứng với mức độ khó tăng dần (lọc bỏ các câu hỏi về game và phim)
  Future<void> _loadDifficultyQuestions() async {
    setState(() {
      _isLoading = true;
    });

    final api = TriviaApiService();
    
    // Quyết định độ khó dựa trên số câu đã trả lời đúng hiện tại
    TriviaDifficulty difficulty = TriviaDifficulty.easy;
    if (_score >= 10 && _score < 30) {
      difficulty = TriviaDifficulty.medium;
    } else if (_score >= 30) {
      difficulty = TriviaDifficulty.hard;
    }

    // Tải nhiều câu hỏi hơn (ví dụ 30 câu) để có đủ câu sau khi lọc bỏ game/phim
    final data = await api.fetchQuestions(
      amount: 30,
      category: TriviaCategory.any,
      difficulty: difficulty,
    );

    if (data != null && data['results'] != null) {
      final results = data['results'] as List;
      final allParsed = results.map((q) => Question.fromJson(q)).toList();
      
      // Lọc bỏ câu hỏi về phim (film) và game (game, board games, video games)
      final filtered = allParsed.where((q) {
        final cat = q.category.toLowerCase();
        return !cat.contains('film') && !cat.contains('game');
      }).toList();

      setState(() {
        // Lấy tối đại 10 câu hỏi hợp lệ
        _questions = filtered.take(10).toList();
        
        // Fallback nếu lọc quá tay không đủ 10 câu
        if (_questions.length < 10) {
          final needed = 10 - _questions.length;
          _questions.addAll(List.generate(
            needed,
            (index) => Question(
              questionText: "Fallback General Question ${_score + _questions.length + 1}: What is 5 + 5?",
              correctAnswer: "10",
              allAnswers: ["8", "9", "10", "11"],
            ),
          ));
        }

        _currentIndex = 0;
        _isLoading = false;
        _hiddenOptions.clear();
      });
      _startTimer();
    } else {
      // Fallback
      setState(() {
        _questions = List.generate(
          10,
          (index) => Question(
            questionText: "Fallback Question ${_score + index + 1}: What is 2 + 2?",
            correctAnswer: "4",
            allAnswers: ["2", "3", "4", "5"],
          ),
        );
        _currentIndex = 0;
        _isLoading = false;
        _hiddenOptions.clear();
      });
      _startTimer();
    }
  }

  void _startTimer({bool resume = false}) {
    _timer?.cancel();
    setState(() {
      if (!resume) {
        _secondsLeft = 30;
        _wrongGuesses.clear();
        _isDoubleAnswerActive = false;
      }
      _hasAnswered = false;
      _selectedAnswer = null;
      _showingResult = false;
      _isTranslated = false;
      _translatedQuestion = null;
      _translatedAnswers.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        _handleAnswer(null); // Quá giờ trả lời
      }
    });
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

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final targetLang = gameProvider.state.targetLanguage;
    final currentQuestion = _questions[_currentIndex];
    final translator = TranslationService();

    try {
      final transQ = await translator.translate(currentQuestion.questionText, to: targetLang);
      final Map<String, String> transAns = {};
      for (final answer in currentQuestion.allAnswers) {
        final transA = await translator.translate(answer, to: targetLang);
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
      }
    }
  }

  /// Gọi cứu trợ 50/50 (Loại bỏ 2 đáp án sai)
  void _use5050() {
    if (_is5050Used || _hasAnswered || _showingResult) return;
    
    final currentQuestion = _questions[_currentIndex];
    final incorrectList = currentQuestion.allAnswers
        .where((ans) => ans != currentQuestion.correctAnswer)
        .toList();
    
    incorrectList.shuffle();
    
    setState(() {
      _is5050Used = true;
      // Ẩn 2 đáp án sai đầu tiên sau khi xáo trộn
      _hiddenOptions = [incorrectList[0], incorrectList[1]];
    });
  }

  /// Sử dụng quyền Trả lời 2 lần (Xem quảng cáo để kích hoạt)
  void _useDoubleAnswer() async {
    if (_isDoubleAnswerUsed || _hasAnswered || _showingResult) return;

    // Tạm dừng thời gian trả lời
    _timer?.cancel();

    final bool? watched = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _AdDialog(),
    );

    if (watched == true) {
      setState(() {
        _isDoubleAnswerUsed = true;
        _isDoubleAnswerActive = true;
      });
    }

    // Tiếp tục thời gian trả lời
    _startTimer(resume: true);
  }

  /// Sử dụng quyền Đổi câu hỏi khác
  Future<void> _useChangeQuestion() async {
    if (_isChangeQuestionUsed || _hasAnswered || _showingResult) return;

    _timer?.cancel();
    setState(() {
      _isLoading = true;
    });

    final api = TriviaApiService();
    TriviaDifficulty difficulty = TriviaDifficulty.easy;
    if (_score >= 10 && _score < 30) {
      difficulty = TriviaDifficulty.medium;
    } else if (_score >= 30) {
      difficulty = TriviaDifficulty.hard;
    }

    // Tải về 10 câu để lọc lấy 1 câu không phải phim/game
    final data = await api.fetchQuestions(
      amount: 10,
      category: TriviaCategory.any,
      difficulty: difficulty,
    );

    if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
      final results = data['results'] as List;
      final allParsed = results.map((q) => Question.fromJson(q)).toList();
      
      // Lọc bỏ phim và game
      final filtered = allParsed.where((q) {
        final cat = q.category.toLowerCase();
        return !cat.contains('film') && !cat.contains('game');
      }).toList();

      setState(() {
        if (filtered.isNotEmpty) {
          _questions[_currentIndex] = filtered.first;
        } else {
          // Lấy luôn câu đầu tiên nếu bộ 10 câu tải về toàn là game/phim (hiếm gặp)
          _questions[_currentIndex] = allParsed.first;
        }
        _isChangeQuestionUsed = true;
        _hiddenOptions.clear();
        _wrongGuesses.clear();
        _isLoading = false;
      });
    } else {
      // Fallback khi lỗi API
      setState(() {
        _questions[_currentIndex] = Question(
          questionText: "Fallback Skipped Question ${_score + 1}: What is the capital of Japan?",
          correctAnswer: "Tokyo",
          allAnswers: ["Tokyo", "Seoul", "Beijing", "Bangkok"],
        );
        _isChangeQuestionUsed = true;
        _hiddenOptions.clear();
        _wrongGuesses.clear();
        _isLoading = false;
      });
    }

    _startTimer(); // Bắt đầu lại bộ đếm 30 giây cho câu hỏi mới
  }

  void _handleAnswer(String? answer) {
    _timer?.cancel();
    final currentQuestion = _questions[_currentIndex];
    final isCorrect = (answer != null && answer == currentQuestion.correctAnswer);
    final provider = Provider.of<GameProvider>(context, listen: false);
    final vol = provider.state.volume;

    // Xử lý quyền Trả lời 2 lần (nếu trả lời sai ở lần đầu)
    if (!isCorrect && _isDoubleAnswerActive) {
      AudioService().playWrong(volume: vol);
      setState(() {
        _isDoubleAnswerActive = false; // Sử dụng cơ hội thứ 2 xong
        _selectedAnswer = null;
        if (answer != null) {
          _wrongGuesses.add(answer);
        }
      });
      _startTimer(resume: true); // Tiếp tục đếm ngược từ số giây còn lại
      return;
    }

    if (isCorrect) {
      AudioService().playCorrect(volume: vol);
      _streakCount++;
      if (_streakCount > _maxStreak) {
        _maxStreak = _streakCount;
      }

      if (_streakCount == 2) {
        _comboText = "🔥 2X COMBO!";
        _comboColor = const Color(0xFFFF8C00);
        _showComboBadge = true;
        AudioService().playClaim(volume: vol);
      } else if (_streakCount == 3) {
        _comboText = "⚡ 3X SUPER COMBO!";
        _comboColor = const Color(0xFF00FFFF);
        _showComboBadge = true;
        AudioService().playClaim(volume: vol);
      } else if (_streakCount >= 5) {
        _comboText = "🌌 ${_streakCount}X ULTRA COMBO!";
        _comboColor = const Color(0xFFFF00FF);
        _showComboBadge = true;
        AudioService().playClaim(volume: vol);
      }
    } else {
      AudioService().playWrong(volume: vol);
      _streakCount = 0;
      _showComboBadge = false;
    }

    setState(() {
      _hasAnswered = true;
      _selectedAnswer = answer;
      _showingResult = true;
      if (isCorrect) {
        _score++;
      }
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      if (isCorrect) {
        if (_currentIndex + 1 < _questions.length) {
          setState(() {
            _currentIndex++;
          });
          _startTimer();
        } else {
          // Đã vượt qua pool 10 câu, tải tiếp độ khó tương ứng tiếp theo
          _loadDifficultyQuestions();
        }
      } else {
        // Trả lời sai -> Game Over
        _gameOver();
      }
    });
  }

  void _gameOver() {
    final provider = Provider.of<GameProvider>(context, listen: false);
    provider.updateHighScore(_score);
    AudioService().playDefeat(volume: provider.state.volume);
    
    // Tặng thưởng vàng dựa trên số câu trả lời đúng (1 câu = 10 vàng)
    final rewardGold = _score * 10;
    if (rewardGold > 0) {
      provider.addGold(rewardGold);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.cardBorder, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Trophy/Game Icon (positive and engaging)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.accentGold,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  "QUIZ FINISHED!",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Friendly status message
                Text(
                  "You did a great job! Keep learning and growing.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Score Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Score info
                      Column(
                        children: [
                          Text(
                            "SCORE",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_score",
                            style: TextStyle(
                              color: AppColors.accentCyan,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      
                      // Divider
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.cardBorder,
                      ),
                      
                      // Reward Gold info
                      Column(
                        children: [
                          Text(
                            "REWARD",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on, color: AppColors.accentGold, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                "+$rewardGold",
                                style: TextStyle(
                                  color: AppColors.accentGold,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Back Button (Modern, wide button)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      widget.onBackToLobby();
                    },
                    child: const Text(
                      "Back to Lobby",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan)),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];

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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: widget.onBackToLobby,
                    ),
                    Text("Correct: $_score", style: AppTypography.subtitleStyle.copyWith(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
                    Text(
                      "$_secondsLeft s",
                      style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Linear Timer Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _secondsLeft / 30.0,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _secondsLeft > 10 ? AppColors.accentCyan : AppColors.accentPink,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 16),

                // Cứu trợ panel (Wrap) để hiển thị đẹp mắt 3 quyền trợ giúp
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    // 1. Trợ giúp 50/50
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBg,
                        foregroundColor: AppColors.accentCyan,
                        disabledBackgroundColor: AppColors.cardBorder.withOpacity(0.4),
                        disabledForegroundColor: AppColors.textPrimary.withOpacity(0.3),
                        side: BorderSide(color: _is5050Used ? Colors.transparent : AppColors.accentCyan),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _is5050Used ? null : _use5050,
                      icon: Icon(_is5050Used ? Icons.close : Icons.star_half, size: 16),
                      label: Text(_is5050Used ? "50/50 ❌" : "50/50", style: const TextStyle(fontSize: 11)),
                    ),

                    // 2. Trả lời 2 lần (Xem quảng cáo)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBg,
                        foregroundColor: Colors.purpleAccent,
                        disabledBackgroundColor: AppColors.cardBorder.withOpacity(0.4),
                        disabledForegroundColor: AppColors.textPrimary.withOpacity(0.3),
                        side: BorderSide(color: _isDoubleAnswerUsed ? Colors.transparent : Colors.purpleAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _isDoubleAnswerUsed ? null : _useDoubleAnswer,
                      icon: Icon(_isDoubleAnswerUsed ? Icons.close : Icons.repeat, size: 16),
                      label: Text(_isDoubleAnswerUsed ? "Double Ans ❌" : "Double Ans (Ad)", style: const TextStyle(fontSize: 11)),
                    ),

                    // 3. Đổi câu hỏi
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBg,
                        foregroundColor: Colors.orangeAccent,
                        disabledBackgroundColor: AppColors.cardBorder.withOpacity(0.4),
                        disabledForegroundColor: AppColors.textPrimary.withOpacity(0.3),
                        side: BorderSide(color: _isChangeQuestionUsed ? Colors.transparent : Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: _isChangeQuestionUsed ? null : _useChangeQuestion,
                      icon: Icon(_isChangeQuestionUsed ? Icons.close : Icons.skip_next, size: 16),
                      label: Text(_isChangeQuestionUsed ? "Skip Question ❌" : "Skip Question", style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Streak Combo Badge Overlay
                        if (_showComboBadge && _comboText != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _comboColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _comboColor, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _comboColor.withOpacity(0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _comboText!,
                                    style: TextStyle(
                                      color: _comboColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Translation toggle button (directly above the card)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTranslated ? AppColors.accentPink.withOpacity(0.2) : AppColors.cardBg,
                            foregroundColor: _isTranslated ? AppColors.accentPink : AppColors.textPrimary,
                            side: BorderSide(color: _isTranslated ? AppColors.accentPink : AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: _isTranslating ? null : _toggleTranslation,
                          icon: _isTranslating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary)),
                                )
                              : const Icon(Icons.translate, size: 16),
                          label: Builder(
                            builder: (context) {
                              final targetLang = Provider.of<GameProvider>(context).state.targetLanguage.toUpperCase();
                              return Text(
                                _isTranslated ? "Original (EN)" : "Translate ($targetLang)",
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        GlassContainer(
                          width: double.infinity,
                          borderRadius: 24,
                          padding: const EdgeInsets.all(24),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "QUESTION ${_currentIndex + 1}",
                                  style: const TextStyle(
                                    color: AppColors.accentCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isTranslated && _translatedQuestion != null
                                      ? _translatedQuestion!
                                      : currentQuestion.questionText,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary, 
                                    fontSize: 18, 
                                    height: 1.4,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Answers List
                ...currentQuestion.allAnswers.map((option) {
                  // Kiểm tra xem đáp án có bị ẩn bởi trợ giúp 50/50 hay không
                  final isHidden = _hiddenOptions.contains(option);
                  // Kiểm tra xem đáp án đã từng bị chọn sai ở lượt đầu (khi dùng Double Answer)
                  final isWrongAttempt = _wrongGuesses.contains(option);

                  Color btnColor = AppColors.cardBg;
                  Color txtColor = AppColors.textPrimary;

                  if (_showingResult) {
                    if (option == currentQuestion.correctAnswer) {
                      btnColor = AppColors.correctGreen.withOpacity(0.2);
                      txtColor = AppColors.correctGreen;
                    } else if (option == _selectedAnswer) {
                      btnColor = AppColors.incorrectRed.withOpacity(0.2);
                      txtColor = AppColors.incorrectRed;
                    }
                  } else if (isWrongAttempt) {
                    btnColor = AppColors.incorrectRed.withOpacity(0.1);
                    txtColor = AppColors.incorrectRed;
                  } else if (option == _selectedAnswer) {
                    btnColor = AppColors.accentCyan.withOpacity(0.15);
                    txtColor = AppColors.accentCyan;
                  }

                  final optionIndex = currentQuestion.allAnswers.indexOf(option);
                  final optionLetter = optionIndex >= 0 && optionIndex < 4 
                      ? String.fromCharCode(65 + optionIndex) 
                      : '?';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Visibility(
                      visible: !isHidden,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: Opacity(
                        opacity: isHidden ? 0.0 : 1.0,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnColor,
                              foregroundColor: txtColor,
                              disabledBackgroundColor: btnColor,
                              disabledForegroundColor: txtColor,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _showingResult && option == currentQuestion.correctAnswer
                                      ? AppColors.correctGreen
                                      : (isWrongAttempt
                                          ? AppColors.incorrectRed
                                          : (_selectedAnswer == option ? AppColors.accentCyan : AppColors.cardBorder)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onPressed: (_showingResult || isHidden || isWrongAttempt) ? null : () => _handleAnswer(option),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: txtColor.withOpacity(0.1),
                                    border: Border.all(color: txtColor.withOpacity(0.3)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    optionLetter,
                                    style: TextStyle(color: txtColor, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isTranslated && _translatedAnswers.containsKey(option)
                                        ? _translatedAnswers[option]!
                                        : option,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget hộp thoại xem quảng cáo giả lập cho quyền Trả lời x2
class _AdDialog extends StatefulWidget {
  const _AdDialog({Key? key}) : super(key: key);

  @override
  State<_AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<_AdDialog> {
  int _seconds = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 1) {
        setState(() {
          _seconds--;
        });
      } else {
        _timer?.cancel();
        Navigator.of(context).pop(true); // Trả về true báo hiệu đã xem xong
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill, color: AppColors.accentPink, size: 60),
          const SizedBox(height: 16),
          const Text(
            "🎬 SPONSORED AD",
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          const Text(
            "Watching ad to activate Double Answer lifeline...",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPink)),
          const SizedBox(height: 12),
          Text(
            "Closing in $_seconds seconds...",
            style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

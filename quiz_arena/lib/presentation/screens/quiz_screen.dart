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
import '../../data/services/translation_service.dart';

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

    final currentQuestion = _questions[_currentIndex];
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎬 Quyền Trả lời 2 lần đã được kích hoạt!"),
          backgroundColor: AppColors.correctGreen,
        ),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🔄 Đã đổi sang câu hỏi mới!"),
        backgroundColor: AppColors.correctGreen,
      ),
    );

    _startTimer(); // Bắt đầu lại bộ đếm 30 giây cho câu hỏi mới
  }

  void _handleAnswer(String? answer) {
    _timer?.cancel();
    final currentQuestion = _questions[_currentIndex];
    final isCorrect = (answer != null && answer == currentQuestion.correctAnswer);

    // Xử lý quyền Trả lời 2 lần (nếu trả lời sai ở lần đầu)
    if (!isCorrect && _isDoubleAnswerActive) {
      setState(() {
        _isDoubleAnswerActive = false; // Sử dụng cơ hội thứ 2 xong
        _selectedAnswer = null;
        if (answer != null) {
          _wrongGuesses.add(answer);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Sai rồi! Bạn còn 1 cơ hội cuối trả lời câu này."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      _startTimer(resume: true); // Tiếp tục đếm ngược từ số giây còn lại
      return;
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
    
    // Tặng thưởng vàng dựa trên số câu trả lời đúng (1 câu = 10 vàng)
    final rewardGold = _score * 10;
    if (rewardGold > 0) {
      provider.addGold(rewardGold);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text("💀 KẾT THÚC LƯỢT CHƠI", style: TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold)),
        content: Text(
          "Bạn đã trả lời sai hoặc quá thời gian.\nĐiểm số đạt được: $_score câu đúng.\nPhần thưởng: +$rewardGold Vàng!",
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
      body: SafeArea(
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
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onBackToLobby,
                  ),
                  Text("Đúng: $_score câu", style: AppTypography.subtitleStyle.copyWith(color: AppColors.accentGold)),
                  Text(
                    "$_secondsLeft s",
                    style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cứu trợ panel (Wrap) để hiển thị đẹp mắt 4 quyền trợ giúp
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  // 1. Nút dịch câu hỏi
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isTranslated ? AppColors.accentPink.withOpacity(0.2) : AppColors.cardBg,
                      foregroundColor: _isTranslated ? AppColors.accentPink : Colors.white,
                      side: BorderSide(color: _isTranslated ? AppColors.accentPink : AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: _isTranslating ? null : _toggleTranslation,
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                          )
                        : const Icon(Icons.translate, size: 16),
                    label: Text(
                      _isTranslated ? "Gốc (English)" : "Dịch (Việt)",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),

                  // 2. Trợ giúp 50/50
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _is5050Used ? Colors.white10 : AppColors.accentCyan.withOpacity(0.1),
                      foregroundColor: _is5050Used ? Colors.white30 : AppColors.accentCyan,
                      side: BorderSide(color: _is5050Used ? Colors.transparent : AppColors.accentCyan),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: _is5050Used ? null : _use5050,
                    icon: const Icon(Icons.star_half, size: 16),
                    label: const Text("50/50", style: TextStyle(fontSize: 11)),
                  ),

                  // 3. Trả lời 2 lần (Xem quảng cáo)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDoubleAnswerUsed ? Colors.white10 : Colors.purple.withOpacity(0.1),
                      foregroundColor: _isDoubleAnswerUsed ? Colors.white30 : Colors.purpleAccent,
                      side: BorderSide(color: _isDoubleAnswerUsed ? Colors.transparent : Colors.purpleAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: _isDoubleAnswerUsed ? null : _useDoubleAnswer,
                    icon: const Icon(Icons.repeat, size: 16),
                    label: const Text("Trả lời x2 (QC)", style: TextStyle(fontSize: 11)),
                  ),

                  // 4. Đổi câu hỏi
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isChangeQuestionUsed ? Colors.white10 : Colors.orange.withOpacity(0.1),
                      foregroundColor: _isChangeQuestionUsed ? Colors.white30 : Colors.orangeAccent,
                      side: BorderSide(color: _isChangeQuestionUsed ? Colors.transparent : Colors.orangeAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: _isChangeQuestionUsed ? null : _useChangeQuestion,
                    icon: const Icon(Icons.skip_next, size: 16),
                    label: const Text("Đổi câu hỏi", style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Center(
                  child: GlassContainer(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: Text(
                        _isTranslated && _translatedQuestion != null
                            ? _translatedQuestion!
                            : currentQuestion.questionText,
                        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
                Color txtColor = Colors.white;

                if (_showingResult) {
                  if (option == currentQuestion.correctAnswer) {
                    btnColor = AppColors.correctGreen.withOpacity(0.3);
                    txtColor = AppColors.correctGreen;
                  } else if (option == _selectedAnswer) {
                    btnColor = AppColors.incorrectRed.withOpacity(0.3);
                    txtColor = AppColors.incorrectRed;
                  }
                } else if (isWrongAttempt) {
                  btnColor = AppColors.incorrectRed.withOpacity(0.2);
                  txtColor = AppColors.incorrectRed;
                } else if (option == _selectedAnswer) {
                  btnColor = AppColors.accentCyan.withOpacity(0.2);
                  txtColor = AppColors.accentCyan;
                }

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
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                          child: Text(
                            _isTranslated && _translatedAnswers.containsKey(option)
                                ? _translatedAnswers[option]!
                                : option,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
      backgroundColor: AppColors.bgSecondary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_circle_fill, color: AppColors.accentPink, size: 60),
          const SizedBox(height: 16),
          const Text(
            "🎬 QUẢNG CÁO TÀI TRỢ",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          const Text(
            "Đang xem quảng cáo để kích hoạt quyền Trả lời 2 lần...",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPink)),
          const SizedBox(height: 12),
          Text(
            "Tự động đóng sau $_seconds giây",
            style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

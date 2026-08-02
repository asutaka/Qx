import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/models/question.dart';
import '../../data/models/trivia_category.dart';
import '../../data/models/trivia_difficulty.dart';
import '../../data/services/trivia_api_service.dart';
import '../../data/services/firebase_service.dart';
import '../../logic/game_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/runner_widget.dart';
import '../../data/services/translation_service.dart';

/// Màn hình Đua đối kháng Battle Mode 1v1 (Realtime PvP với Bot fallback)
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
  int _matchmakingSec = 8; // Đợi tối đa 8 giây để ghép cặp PvP
  Timer? _matchmakingTimer;

  // Realtime PvP state
  String _playerId = "";
  String? _roomId;
  bool _isHost = false;
  bool _isBotGame = false;
  bool _gameEnded = false;
  StreamSubscription? _roomSubscription;
  Timer? _opponentTimeoutTimer;

  // Đối thủ thông tin
  String _opponentId = "";
  String _opponentName = "Đang tìm...";
  String _opponentCharId = "char_wukong";
  String _opponentHatId = "hat_cowboy";
  String _opponentShoesId = "shoes_running";
  String _opponentEffectId = "effect_fire";

  // Dữ liệu trận đấu
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _playerScore = 0;
  int _botScore = 0; // Điểm của đối thủ (được đồng bộ hoặc chạy bằng Bot)

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
    _initMatchmakingAndFirebase();
  }

  @override
  void dispose() {
    _matchmakingTimer?.cancel();
    _questionTimer?.cancel();
    _botActionTimer?.cancel();
    _roomSubscription?.cancel();
    _opponentTimeoutTimer?.cancel();
    
    // Nếu rời trận sớm khi đang đợi ghép cặp, Host sẽ tự xóa phòng
    if (_isHost && _roomId != null && !_gameEnded) {
      FirebaseFirestore.instance.collection('rooms').doc(_roomId).delete().catchError((e) => null);
    }
    super.dispose();
  }

  /// Khởi tạo Matchmaking qua Firebase Firestore
  Future<void> _initMatchmakingAndFirebase() async {
    try {
      _playerId = await FirebaseService().getOrCreateUserId();
      final provider = Provider.of<GameProvider>(context, listen: false);
      final state = provider.state;

      // 1. Tìm xem có phòng nào đang ở trạng thái waiting không
      final query = await FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .get();

      final now = DateTime.now().millisecondsSinceEpoch;
      DocumentSnapshot? validRoom;

      for (final doc in query.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as int? ?? 0;
        // Chỉ nhận phòng được tạo trong vòng 15 giây qua để tránh phòng "rác" của phiên cũ
        if ((now - createdAt).abs() < 15000) {
          validRoom = doc;
          break;
        } else {
          // Xóa phòng rác để dọn dẹp Firestore
          FirebaseFirestore.instance.collection('rooms').doc(doc.id).delete().catchError((e) => null);
        }
      }

      if (validRoom != null) {
        // Có phòng đợi hợp lệ -> Tham gia làm Player 2 (Guest)
        _roomId = validRoom.id;
        _isHost = false;
        _isBotGame = false;

        // Cập nhật thông tin của Player 2 lên Firestore
        await FirebaseFirestore.instance.collection('rooms').doc(_roomId).update({
          'player2Id': _playerId,
          'player2Name': state.nickname,
          'player2Character': state.equippedCharacter,
          'player2Hat': state.equippedHat,
          'player2Shoes': state.equippedShoes,
          'player2Effect': state.equippedEffect,
          'status': 'playing',
          'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
        });
        
        _subscribeToRoom();
      } else {
        // Không có phòng nào đợi -> Tạo phòng mới làm Player 1 (Host)
        _roomId = _playerId;
        _isHost = true;
        _isBotGame = false;

        // Tải câu hỏi từ API trước khi tạo phòng
        await _loadQuestions();

        await FirebaseFirestore.instance.collection('rooms').doc(_roomId).set({
          'status': 'waiting',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
          'player1Id': _playerId,
          'player1Name': state.nickname,
          'player1Character': state.equippedCharacter,
          'player1Hat': state.equippedHat,
          'player1Shoes': state.equippedShoes,
          'player1Effect': state.equippedEffect,
          'player1Score': 0,
          'player1Finished': false,
          'player2Id': '',
          'player2Name': '',
          'player2Character': '',
          'player2Hat': '',
          'player2Shoes': '',
          'player2Effect': '',
          'player2Score': 0,
          'player2Finished': false,
          'questions': _questions.map((q) => q.toJson()).toList(),
          'winnerId': '',
        });

        _subscribeToRoom();
        _startMatchmakingCountdown();
      }
    } catch (e) {
      print("Lỗi khởi tạo trận đấu realtime: $e");
      // Fallback cục bộ hoàn toàn nếu Firestore bị lỗi hoặc offline
      _isBotGame = true;
      _isHost = true;
      await _loadQuestions();
      setState(() {
        _opponentName = "BetaTester 🇺🇸";
        _opponentCharId = "char_wukong";
        _opponentHatId = "hat_cowboy";
        _opponentShoesId = "shoes_running";
        _opponentEffectId = "effect_fire";
        _isMatchmaking = false;
      });
      _startQuestionRound();
    }
  }

  /// Đếm ngược matchmaking (Đợi tối đa 8 giây, nếu quá giờ sẽ ghép với Bot)
  void _startMatchmakingCountdown() {
    _matchmakingSec = 8;
    _matchmakingTimer?.cancel();
    _matchmakingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_matchmakingSec > 1) {
        if (mounted) {
          setState(() {
            _matchmakingSec--;
          });
        }
      } else {
        _matchmakingTimer?.cancel();
        // Hết 8s chưa có ai -> Chuyển sang đấu với Bot (Bot fallback)
        if (_isHost && !_isBotGame && _roomId != null) {
          _isBotGame = true;
          try {
            await FirebaseFirestore.instance.collection('rooms').doc(_roomId).update({
              'player2Id': 'bot_id',
              'player2Name': 'BetaTester 🇺🇸',
              'player2Character': 'char_wukong',
              'player2Hat': 'hat_cowboy',
              'player2Shoes': 'shoes_running',
              'player2Effect': 'effect_fire',
              'status': 'playing',
              'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
            });
          } catch (e) {
            print("Lỗi chuyển phòng sang Bot mode: $e");
          }
        }
      }
    });
  }

  /// Đăng ký lắng nghe các thay đổi của phòng trên Firestore
  void _subscribeToRoom() {
    _roomSubscription?.cancel();
    if (_roomId == null) return;

    _roomSubscription = FirebaseFirestore.instance
        .collection('rooms')
        .doc(_roomId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;
      final data = snapshot.data()!;

      final status = data['status'] as String;
      final p1Id = data['player1Id'] as String;
      final p2Id = data['player2Id'] as String;

      // Cập nhật thông tin đối thủ
      if (_isHost) {
        if (p2Id.isNotEmpty) {
          setState(() {
            _opponentId = p2Id;
            _opponentName = data['player2Name'] ?? 'Opponent';
            _opponentCharId = data['player2Character'] ?? 'char_wukong';
            _opponentHatId = data['player2Hat'] ?? 'hat_cowboy';
            _opponentShoesId = data['player2Shoes'] ?? 'shoes_running';
            _opponentEffectId = data['player2Effect'] ?? 'effect_fire';
            if (p2Id == 'bot_id') {
              _isBotGame = true;
            }
          });
        }
      } else {
        setState(() {
          _opponentId = p1Id;
          _opponentName = data['player1Name'] ?? 'Opponent';
          _opponentCharId = data['player1Character'] ?? 'char_wukong';
          _opponentHatId = data['player1Hat'] ?? 'hat_cowboy';
          _opponentShoesId = data['player1Shoes'] ?? 'shoes_running';
          _opponentEffectId = data['player1Effect'] ?? 'effect_fire';
        });

        // Nếu là Guest, tải câu hỏi từ Firestore xuống
        if (_questions.isEmpty) {
          final qList = data['questions'] as List;
          setState(() {
            _questions = qList.map((q) => Question.fromJson(q)).toList();
            _isLoading = false;
          });
        }
      }

      // Cập nhật điểm số real-time từ Firestore
      final p1Score = data['player1Score'] as int;
      final p2Score = data['player2Score'] as int;
      if (mounted) {
        setState(() {
          _playerScore = _isHost ? p1Score : p2Score;
          _botScore = _isHost ? p2Score : p1Score; // botScore tái sử dụng làm điểm đối thủ
        });
      }

      // Bắt đầu game khi phòng chuyển trạng thái playing
      if (_isMatchmaking && status == 'playing') {
        _matchmakingTimer?.cancel();
        setState(() {
          _isMatchmaking = false;
        });
        _startQuestionRound();
      }

      // Kiểm tra kết thúc trận đấu
      final p1Finished = data['player1Finished'] as bool? ?? false;
      final p2Finished = data['player2Finished'] as bool? ?? false;
      if ((p1Finished && p2Finished) || p1Score >= 10 || p2Score >= 10) {
        _opponentTimeoutTimer?.cancel();
        _opponentTimeoutTimer = null;
        _endGameRealtime(data);
      } else {
        // Kiểm tra nếu mình đã hoàn thành nhưng đối thủ chưa hoàn thành (có thể đã rớt mạng)
        final myFinished = _isHost ? p1Finished : p2Finished;
        final oppFinished = _isHost ? p2Finished : p1Finished;
        if (myFinished && !oppFinished) {
          if (_opponentTimeoutTimer == null) {
            _startOpponentTimeout();
          }
        } else {
          _opponentTimeoutTimer?.cancel();
          _opponentTimeoutTimer = null;
        }
      }
    });
  }

  /// Bắt đầu đếm ngược chờ đối thủ hoàn thành (quá 25 giây tự xử thắng/thua/hòa)
  void _startOpponentTimeout() {
    _opponentTimeoutTimer?.cancel();
    _opponentTimeoutTimer = Timer(const Duration(seconds: 25), () {
      if (mounted && !_gameEnded) {
        _forceEndGameDueToTimeout();
      }
    });
  }

  /// Tự động kết thúc game khi đối thủ offline/rời trận quá lâu
  void _forceEndGameDueToTimeout() {
    if (_gameEnded) return;
    _gameEnded = true;

    _questionTimer?.cancel();
    _botActionTimer?.cancel();
    _roomSubscription?.cancel();
    _opponentTimeoutTimer?.cancel();

    final provider = Provider.of<GameProvider>(context, listen: false);
    final scoreDiff = _playerScore - _botScore;

    String titleText;
    Color titleColor;
    String contentText;

    if (scoreDiff > 0) {
      titleText = "🏆 CHIẾN THẮNG (ĐỐI THỦ RỜI TRẬN)!";
      titleColor = AppColors.accentCyan;
      contentText = "Đối thủ đã mất kết nối. Bạn nhận được +400 Vàng!";
      provider.updateHighScore(_playerScore);
      provider.addGold(400);
    } else if (scoreDiff < 0) {
      titleText = "💀 THẤT BẠI!";
      titleColor = AppColors.accentPink;
      contentText = "Bạn đã thua cuộc trước đối thủ với tỉ số $_playerScore - $_botScore.\nBạn bị mất 200 Vàng tiền cọc!";
    } else {
      titleText = "🤝 HÒA NHAU!";
      titleColor = AppColors.accentGold;
      contentText = "Trận đấu kết thúc do đối thủ rời trận. Điểm số hòa nhau.\nBạn được hoàn lại 180 Vàng!";
      provider.addGold(180);
    }

    if (_isHost && _roomId != null) {
      FirebaseFirestore.instance.collection('rooms').doc(_roomId).delete().catchError((e) => null);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(titleText, style: TextStyle(color: titleColor, fontWeight: FontWeight.bold)),
        content: Text(contentText, style: const TextStyle(color: AppColors.textPrimary)),
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

  /// Tải câu hỏi từ API OTDB (Lọc bỏ các câu hỏi về game và phim)
  Future<void> _loadQuestions() async {
    final api = TriviaApiService();
    // Tải về 30 câu để đảm bảo đủ câu hỏi sau khi lọc
    final data = await api.fetchQuestions(
      amount: 30,
      category: TriviaCategory.any,
      difficulty: TriviaDifficulty.any,
    );

    if (data != null && data['results'] != null) {
      final results = data['results'] as List;
      final allParsed = results.map((q) => Question.fromJson(q)).toList();
      
      // Lọc bỏ các câu hỏi về phim (film) và game (game, video games, board games)
      final filtered = allParsed.where((q) {
        final cat = q.category.toLowerCase();
        return !cat.contains('film') && !cat.contains('game');
      }).toList();

      _questions = filtered.take(10).toList();
    }

    // Nếu tải lỗi hoặc không đủ câu hỏi sau khi lọc, tự tạo danh sách câu hỏi dự phòng
    if (_questions.length < 10) {
      final needed = 10 - _questions.length;
      final fallbackQuestions = List.generate(
        needed,
        (index) => Question(
          questionText: "Fallback General Question ${_questions.length + index + 1}: What is 10 + 10?",
          correctAnswer: "20",
          allAnswers: ["15", "18", "20", "25"],
        ),
      );
      _questions.addAll(fallbackQuestions);
    }

    setState(() {
      _isLoading = false;
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
      }
    }
  }

  /// Bắt đầu một vòng câu hỏi mới
  void _startQuestionRound() {
    if (_currentQuestionIndex >= _questions.length || _playerScore >= 10 || _botScore >= 10) {
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

    // Mô phỏng Bot tự suy nghĩ trả lời ngẫu nhiên (chỉ chạy nếu là Host trong Bot game)
    if (_isHost && _isBotGame) {
      _botActionTimer?.cancel();
      _botActionTimer = Timer(Duration(seconds: 4 + (DateTime.now().millisecond % 8)), () {
        if (!_showingAnswerResult && mounted) {
          final botCorrect = (DateTime.now().millisecond % 100) < 65;
          if (botCorrect) {
            final newBotScore = _botScore + 1;
            FirebaseFirestore.instance.collection('rooms').doc(_roomId).update({
              'player2Score': newBotScore,
              if (_currentQuestionIndex >= _questions.length - 1 || newBotScore >= 10)
                'player2Finished': true
            }).catchError((e) => print("Lỗi cập nhật điểm Bot: $e"));
          }
        }
      });
    }
  }

  /// Chọn đáp án
  void _selectAnswerOption(String option) {
    if (_hasAnswered || _showingAnswerResult) return;
    _revealAnswer(option);
  }

  /// Hiển thị đáp án đúng và tạm dừng 5 giây trước khi sang câu kế tiếp
  void _revealAnswer(String? playerAnswer) {
    _questionTimer?.cancel();
    _botActionTimer?.cancel();

    final isCorrect = playerAnswer != null && playerAnswer == _questions[_currentQuestionIndex].correctAnswer;
    final newScore = isCorrect ? _playerScore + 1 : _playerScore;
    final isLastQuestion = _currentQuestionIndex >= _questions.length - 1;
    final isFinished = isLastQuestion || newScore >= 10;

    setState(() {
      _hasAnswered = true;
      _selectedAnswer = playerAnswer;
      _showingAnswerResult = true;
    });

    // Cập nhật kết quả lên Firestore
    if (_roomId != null) {
      if (_isHost) {
        FirebaseFirestore.instance.collection('rooms').doc(_roomId).update({
          'player1Score': newScore,
          if (isFinished) 'player1Finished': true,
          if (isFinished && _isBotGame) 'player2Finished': true,
        }).catchError((e) => print("Lỗi cập nhật điểm Host: $e"));
      } else {
        FirebaseFirestore.instance.collection('rooms').doc(_roomId).update({
          'player2Score': newScore,
          if (isFinished) 'player2Finished': true,
          if (isFinished && _isBotGame) 'player1Finished': true,
        }).catchError((e) => print("Lỗi cập nhật điểm Guest: $e"));
      }
    } else {
      // Trường hợp fallback hoàn toàn offline không có phòng
      setState(() {
        _playerScore = newScore;
      });
      if (isFinished) {
        _endGameOffline();
      }
    }

    // Dừng 5 giây xem kết quả đáp án rồi chuyển sang câu mới
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentQuestionIndex++;
        });
        if (_roomId != null) {
          _startQuestionRound();
        } else {
          // Offline fallback
          if (_currentQuestionIndex >= _questions.length || _playerScore >= 10 || _botScore >= 10) {
            _endGameOffline();
          } else {
            _startQuestionRound();
          }
        }
      }
    });
  }

  /// Kết thúc trận đấu Realtime PvP
  void _endGameRealtime(Map<String, dynamic> roomData) {
    if (_gameEnded) return;
    _gameEnded = true;

    _questionTimer?.cancel();
    _botActionTimer?.cancel();
    _roomSubscription?.cancel();

    final provider = Provider.of<GameProvider>(context, listen: false);
    
    final p1Score = roomData['player1Score'] as int;
    final p2Score = roomData['player2Score'] as int;
    
    final myScore = _isHost ? p1Score : p2Score;
    final oppScore = _isHost ? p2Score : p1Score;

    final scoreDiff = myScore - oppScore;

    String titleText;
    Color titleColor;
    String contentText;

    if (scoreDiff > 0) {
      titleText = "🏆 VICTORY!";
      titleColor = AppColors.accentCyan;
      contentText = "You defeated your opponent by a score of $myScore - $oppScore.\nYou received +400 Gold!";
      provider.updateHighScore(myScore);
      provider.addGold(400);
    } else if (scoreDiff < 0) {
      titleText = "💀 DEFEATED!";
      titleColor = AppColors.accentPink;
      contentText = "You lost to your opponent by a score of $myScore - $oppScore.\nYou lost the 200 Gold entry deposit!";
    } else {
      titleText = "🤝 DRAW!";
      titleColor = AppColors.accentGold;
      contentText = "It's a draw with a score of $myScore - $oppScore.\nBoth sides pay a 10% fee (20 Gold).\nYou received 180 Gold back!";
      provider.addGold(180);
    }

    // Clean up Firestore room (Chỉ host thực hiện xóa phòng để tránh tranh chấp xóa trùng)
    if (_isHost && _roomId != null) {
      FirebaseFirestore.instance.collection('rooms').doc(_roomId).delete().catchError((e) {
        print("Lỗi xóa phòng: $e");
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          titleText,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          contentText,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBackToLobby();
            },
            child: const Text("Back to Lobby", style: TextStyle(color: AppColors.accentCyan)),
          )
        ],
      ),
    );
  }

  /// Kết thúc trận đấu Offline / Lỗi
  void _endGameOffline() {
    _questionTimer?.cancel();
    _botActionTimer?.cancel();

    final provider = Provider.of<GameProvider>(context, listen: false);
    final int scoreDiff = _playerScore - _botScore;

    String titleText;
    Color titleColor;
    String contentText;

    if (scoreDiff > 0) {
      titleText = "🏆 VICTORY!";
      titleColor = AppColors.accentCyan;
      contentText = "You defeated your opponent by a score of $_playerScore - $_botScore.\nYou received +400 Gold!";
      provider.updateHighScore(_playerScore);
      provider.addGold(400);
    } else if (scoreDiff < 0) {
      titleText = "💀 DEFEATED!";
      titleColor = AppColors.accentPink;
      contentText = "You lost to your opponent by a score of $_playerScore - $_botScore.\nYou lost the 200 Gold entry deposit!";
    } else {
      titleText = "🤝 DRAW!";
      titleColor = AppColors.accentGold;
      contentText = "It's a draw with a score of $_playerScore - $_botScore.\nBoth sides pay a 10% fee (20 Gold).\nYou received 180 Gold back!";
      provider.addGold(180);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          titleText,
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          contentText,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onBackToLobby();
            },
            child: const Text("Back to Lobby", style: TextStyle(color: AppColors.accentCyan)),
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

    if (_currentQuestionIndex >= _questions.length || _playerScore >= 10 || _botScore >= 10) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE9FE), Color(0xFFE0F2FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Battle Info Bar (Số câu hỏi + Giây đếm ngược)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Question ${_currentQuestionIndex + 1} / 10", style: AppTypography.subtitleStyle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    Text(
                      "$_secondsLeft s",
                      style: AppTypography.titleStyle.copyWith(fontSize: 22, color: AppColors.accentCyan),
                    ),
                  ],
                ),
              ),

              // Linear Timer Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
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
              ),
              const SizedBox(height: 12),

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
                          Text("🏁 BATTLE TRACK", style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),

                          // Làn của người chơi
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(playerState.nickname, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text("$_playerScore/10", style: const TextStyle(color: AppColors.accentCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 60,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.04),
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
                                  Text(_opponentName, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text("$_botScore/10", style: TextStyle(color: AppColors.accentPink, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 60,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 500),
                                      left: botLeft,
                                      top: 2,
                                      child: RunnerWidget(
                                        characterId: _opponentCharId,
                                        hatId: _opponentHatId,
                                        shoesId: _opponentShoesId,
                                        effectId: _opponentEffectId,
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
                      foregroundColor: _isTranslated ? AppColors.accentPink : AppColors.textPrimary,
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
                    label: Text(_isTranslated ? "Original (EN)" : "Translate (VN)", style: const TextStyle(fontSize: 12)),
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
                        borderRadius: 20,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              "QUESTION ${_currentQuestionIndex + 1}",
                              style: const TextStyle(
                                color: AppColors.accentCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isTranslated && _translatedQuestion != null
                                  ? _translatedQuestion!
                                  : currentQuestion.questionText,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.4, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Options
                      ...currentQuestion.allAnswers.map((option) {
                        Color btnColor = AppColors.cardBg;
                        Color txtColor = AppColors.textPrimary;

                        if (_showingAnswerResult) {
                          if (option == currentQuestion.correctAnswer) {
                            btnColor = AppColors.correctGreen.withOpacity(0.2);
                            txtColor = AppColors.correctGreen;
                          } else if (option == _selectedAnswer) {
                            btnColor = AppColors.incorrectRed.withOpacity(0.2);
                            txtColor = AppColors.incorrectRed;
                          }
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
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: btnColor,
                                foregroundColor: txtColor,
                                disabledBackgroundColor: btnColor,
                                disabledForegroundColor: txtColor,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  /// Hủy tìm trận và quay lại sảnh
  void _cancelMatchmaking() {
    _matchmakingTimer?.cancel();
    _roomSubscription?.cancel();
    if (_isHost && _roomId != null) {
      FirebaseFirestore.instance.collection('rooms').doc(_roomId).delete().catchError((e) => null);
    }
    widget.onBackToLobby();
  }

  /// Trực quan hóa Giao diện Tìm kiếm Đối thủ (Matchmaking)
  Widget _buildMatchmakingView() {
    final gameProvider = Provider.of<GameProvider>(context);
    final playerState = gameProvider.state;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDE9FE), Color(0xFFE0F2FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.radar, color: AppColors.accentCyan, size: 70),
                const SizedBox(height: 16),
                Text(
                  "SEARCHING FOR OPPONENT...",
                  style: AppTypography.titleStyle.copyWith(fontSize: 24, color: AppColors.accentCyan, letterSpacing: 1.5),
                ),
                const SizedBox(height: 6),
                Text(
                  "Auto-matching with Bot in $_matchmakingSec seconds",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 48),

                // Giao diện Matchup VS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Bạn (Left)
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentCyan.withOpacity(0.1),
                            border: Border.all(color: AppColors.accentCyan, width: 2),
                          ),
                          child: Center(
                            child: Transform.scale(
                              scale: 1.2,
                              child: RunnerWidget(
                                characterId: playerState.equippedCharacter,
                                hatId: playerState.equippedHat,
                                shoesId: playerState.equippedShoes,
                                effectId: playerState.equippedEffect,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          playerState.nickname,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Text("YOU", style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    // VS Badge (Middle)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentPink.withOpacity(0.1),
                        border: Border.all(color: AppColors.accentPink.withOpacity(0.5), width: 1.5),
                      ),
                      child: const Text(
                        "VS",
                        style: TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold, fontSize: 18, fontStyle: FontStyle.italic),
                      ),
                    ),

                    // Đối thủ (Right)
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cardBg,
                            border: Border.all(color: AppColors.cardBorder, width: 1.5),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPink),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Searching...",
                          style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 14),
                        ),
                        Text("OPPONENT", style: TextStyle(color: AppColors.textPrimary.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Nút Hủy Tìm Trận
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBg,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: _cancelMatchmaking,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text(
                    "Cancel Matchmaking",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
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

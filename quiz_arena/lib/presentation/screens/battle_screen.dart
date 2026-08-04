import 'dart:async';
import 'dart:math';
import 'dart:ui';
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
import '../../data/services/audio_service.dart';

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
  String _opponentTrackId = "track_cyber";

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

  // Streak Combo
  int _playerStreakCount = 0;
  String? _playerComboText;
  Color _playerComboColor = Colors.orange;
  bool _showPlayerComboBadge = false;

  static final List<String> _firstNames = [
    'Speedy', 'Quiz', 'Runner', 'Alpha', 'Beta', 'Hyper', 'Swift', 'Apex', 'Brainy',
    'Mega', 'Smart', 'Master', 'Super', 'Turbo', 'Flash', 'Pro', 'Champion', 'Elite',
    'Chibi', 'Pixel', 'Sonic', 'Nexus', 'Cosmic', 'Shadow', 'Storm', 'Strike', 'Nova',
    'Dino', 'Panda', 'Tiger', 'Ninja', 'Samurai', 'Hero', 'Wizard', 'Ghost', 'Rogue'
  ];

  static final List<String> _lastNames = [
    'Racer', 'Master', 'Brain', 'King', 'Queen', 'Ninja', 'Star', 'Player', 'Hunter',
    'Gamer', 'Knight', 'Seeker', 'Challenger', 'Solver', 'Mind', 'Guru', 'Sage',
    'Spark', 'Dash', 'Blitz', 'Bolt', 'Wave', 'Storm', 'Shadow', 'Frost', 'Flame'
  ];

  static final List<String> _flags = [
    '🇺🇸', '🇻🇳', '🇬🇧', '🇯🇵', '🇰🇷', '🇩🇪', '🇫🇷', '🇦🇺', '🇨🇦', '🇸🇬', '🇮🇳', '🇧🇷', '🇷🇺',
    '🇪🇸', '🇮🇹', '🇳🇱', '🇸🇪', '🇨🇭', '🇳🇿', '🇲🇾', '🇹🇭', '🇵🇭', '🇮🇩'
  ];

  static final List<String> _characters = ['char_wukong', 'char_tu_ha', 'char_xuat_kich', 'char_lan_m', 'char_hao_nhoang_m'];
  static final List<String> _hats = ['hat_cowboy', 'hat_straw', 'hat_cap', 'hat_crown', 'hat_wizard', 'hat_astro', 'hat_graduate'];
  static final List<String> _shoes = ['shoes_running', 'shoes_gold', 'shoes_rocket', 'shoes_roller', 'shoes_skate'];
  static final List<String> _effects = ['effect_fire', 'effect_stars', 'effect_lightning', 'effect_hearts', 'effect_bubbles', 'effect_rainbow'];
  static final List<String> _tracks = ['track_cyber', 'track_sakura', 'track_lightning', 'track_hellfire', 'track_galaxy', 'track_gold'];

  late final List<Map<String, String>> _randomOpponents;

  @override
  void initState() {
    super.initState();
    
    // Generate 99 random-looking simulated opponents
    final rand = Random(42); // Stable seed
    _randomOpponents = List.generate(99, (index) {
      final firstName = _firstNames[rand.nextInt(_firstNames.length)];
      final lastName = _lastNames[rand.nextInt(_lastNames.length)];
      final flag = _flags[rand.nextInt(_flags.length)];
      final hasNumber = rand.nextBool();
      final numStr = hasNumber ? "${rand.nextInt(90) + 10}" : "";
      final name = "$firstName$lastName$numStr $flag";

      return {
        'name': name,
        'character': _characters[rand.nextInt(_characters.length)],
        'hat': _hats[rand.nextInt(_hats.length)],
        'shoes': _shoes[rand.nextInt(_shoes.length)],
        'effect': _effects[rand.nextInt(_effects.length)],
        'track': _tracks[rand.nextInt(_tracks.length)],
      };
    });

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

      // 1. Tìm xem có phòng nào đang ở trạng thái waiting không (bỏ qua phòng của chính mình)
      final query = await FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .get();

      final now = DateTime.now().millisecondsSinceEpoch;
      DocumentSnapshot? validRoom;

      for (final doc in query.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as int? ?? 0;
        final p1Id = data['player1Id'] as String? ?? '';

        // Chỉ chọn phòng do người khác tạo trong 15s gần đây
        if (p1Id != _playerId && (now - createdAt).abs() < 15000) {
          validRoom = doc;
          break;
        } else if ((now - createdAt).abs() >= 15000) {
          // Xóa phòng rác cũ
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
          'player2Track': state.equippedTrack,
          'status': 'playing',
          'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
        });

        _subscribeToRoom();
      } else {
        // Không có phòng nào đợi -> Tạo phòng mới làm Player 1 (Host) NGAY LẬP TỨC!
        _roomId = _playerId;
        _isHost = true;
        _isBotGame = false;

        // Tạo phòng lên Firestore NGAY trước khi load questions để các client khác tìm thấy ngay
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
          'player1Track': state.equippedTrack,
          'player1Score': 0,
          'player1Finished': false,
          'player2Id': '',
          'player2Name': '',
          'player2Character': '',
          'player2Hat': '',
          'player2Shoes': '',
          'player2Effect': '',
          'player2Track': 'track_cyber',
          'player2Score': 0,
          'player2Finished': false,
          'questions': [], // Sẽ được điền sau khi _loadQuestions() hoàn thành
          'winnerId': '',
        });

        _subscribeToRoom();
        _startMatchmakingCountdown();

        // Tải câu hỏi từ API ở background và đẩy lên Firestore
        _loadQuestions().then((_) async {
          if (_roomId != null && _isHost && mounted) {
            await FirebaseFirestore.instance.collection('rooms').doc(_roomId).update({
              'questions': _questions.map((q) => q.toJson()).toList(),
            }).catchError((e) => print("Lỗi cập nhật questions cho room: $e"));
          }
        });
      }
    } catch (e) {
      print("Lỗi khởi tạo trận đấu realtime: $e");
      // Fallback cục bộ hoàn toàn nếu Firestore bị lỗi hoặc offline
      _isBotGame = true;
      _isHost = true;
      await _loadQuestions();
      final randomOpponent = _randomOpponents[DateTime.now().millisecond % _randomOpponents.length];
      setState(() {
        _opponentName = randomOpponent['name']!;
        _opponentCharId = randomOpponent['character']!;
        _opponentHatId = randomOpponent['hat']!;
        _opponentShoesId = randomOpponent['shoes']!;
        _opponentEffectId = randomOpponent['effect']!;
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
          // Kiểm tra định kỳ xem có phòng ngẫu nhiên khác do Host khác tạo đồng thời không
          if (_isHost && _opponentId.isEmpty) {
            _checkForOtherWaitingRooms();
          }
        }
      } else {
        _matchmakingTimer?.cancel();
        // Hết 8s chưa có ai -> Chuyển sang đấu với đối thủ tự động
        if (_isHost && !_isBotGame && _roomId != null) {
          _isBotGame = true;
          final randomOpponent = _randomOpponents[DateTime.now().millisecond % _randomOpponents.length];
          try {
            await FirebaseFirestore.instance.collection('rooms').doc(_roomId).update({
              'player2Id': 'bot_id',
              'player2Name': randomOpponent['name']!,
              'player2Character': randomOpponent['character']!,
              'player2Hat': randomOpponent['hat']!,
              'player2Shoes': randomOpponent['shoes']!,
              'player2Effect': randomOpponent['effect']!,
              'player2Track': randomOpponent['track']!,
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

  /// Tự động kiểm tra nếu có Host khác vừa tạo phòng waiting song song để gộp vào 1 phòng
  Future<void> _checkForOtherWaitingRooms() async {
    if (!_isHost || !_isMatchmaking || _opponentId.isNotEmpty || _roomId == null) return;

    try {
      final query = await FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .get();

      final now = DateTime.now().millisecondsSinceEpoch;
      DocumentSnapshot? otherRoom;

      for (final doc in query.docs) {
        if (doc.id == _roomId) continue;
        final data = doc.data();
        final p1Id = data['player1Id'] as String? ?? '';
        final createdAt = data['createdAt'] as int? ?? 0;

        if (p1Id != _playerId && (now - createdAt).abs() < 15000) {
          // Ưu tiên ghép vào phòng được tạo trước (hoặc có ID nhỏ hơn nếu cùng timestamp)
          final myDoc = await FirebaseFirestore.instance.collection('rooms').doc(_roomId).get();
          final myCreatedAt = (myDoc.data()?['createdAt'] as int?) ?? now;

          if (createdAt < myCreatedAt || (createdAt == myCreatedAt && doc.id.compareTo(_roomId!) < 0)) {
            otherRoom = doc;
            break;
          }
        }
      }

      if (otherRoom != null && mounted && _isMatchmaking && _opponentId.isEmpty) {
        final targetRoomId = otherRoom.id;
        final provider = Provider.of<GameProvider>(context, listen: false);
        final state = provider.state;

        // Cập nhật tham gia phòng của Host khác làm Player 2
        await FirebaseFirestore.instance.collection('rooms').doc(targetRoomId).update({
          'player2Id': _playerId,
          'player2Name': state.nickname,
          'player2Character': state.equippedCharacter,
          'player2Hat': state.equippedHat,
          'player2Shoes': state.equippedShoes,
          'player2Effect': state.equippedEffect,
          'status': 'playing',
          'expireAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
        });

        // Xóa phòng rác do mình tự tạo trước đó
        FirebaseFirestore.instance.collection('rooms').doc(_roomId).delete().catchError((e) => null);

        // Chuyển vai trò sang Guest và lắng nghe phòng mới
        _roomId = targetRoomId;
        _isHost = false;
        _subscribeToRoom();
      }
    } catch (e) {
      print("Lỗi re-check waiting rooms: $e");
    }
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
            _opponentTrackId = data['player2Track'] ?? 'track_cyber';
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
          _opponentTrackId = data['player1Track'] ?? 'track_cyber';
        });

        // Nếu là Guest, tải câu hỏi từ Firestore xuống khi sẵn sàng
        if (_questions.isEmpty && data['questions'] != null) {
          final qList = data['questions'] as List;
          if (qList.isNotEmpty) {
            setState(() {
              _questions = qList.map((q) => Question.fromJson(q)).toList();
              _isLoading = false;
            });
          }
        }
      }

      // Cập nhật điểm số real-time từ Firestore
      final p1Score = data['player1Score'] as int? ?? 0;
      final p2Score = data['player2Score'] as int? ?? 0;
      if (mounted) {
        setState(() {
          _playerScore = _isHost ? p1Score : p2Score;
          _botScore = _isHost ? p2Score : p1Score; // botScore tái sử dụng làm điểm đối thủ
        });
      }

      // Bắt đầu game khi phòng chuyển trạng thái playing VÀ câu hỏi đã tải thành công
      final roomQuestions = data['questions'] as List? ?? [];
      if (_isMatchmaking && status == 'playing') {
        if (_questions.isEmpty && roomQuestions.isNotEmpty) {
          _questions = roomQuestions.map((q) => Question.fromJson(q)).toList();
        }
        if (_questions.isNotEmpty) {
          _matchmakingTimer?.cancel();
          setState(() {
            _isMatchmaking = false;
            _isLoading = false;
          });
          _startQuestionRound();
        }
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
    IconData iconData;
    Color iconColor;

    if (scoreDiff > 0) {
      titleText = "VICTORY (OPPONENT LEFT)!";
      titleColor = AppColors.accentCyan;
      contentText = "Your opponent has disconnected. You received +400 Gold!";
      iconData = Icons.emoji_events_rounded;
      iconColor = AppColors.accentGold;
      provider.updateHighScore(_playerScore);
      provider.addGold(400);
    } else if (scoreDiff < 0) {
      titleText = "DEFEATED!";
      titleColor = AppColors.accentPink;
      contentText = "You lost to your opponent by a score of $_playerScore - $_botScore.\nYou lost the 200 Gold entry deposit!";
      iconData = Icons.sentiment_very_dissatisfied_rounded;
      iconColor = AppColors.accentPink;
    } else {
      titleText = "DRAW!";
      titleColor = AppColors.accentGold;
      contentText = "Match ended due to opponent disconnect. It's a draw.\nYou received 180 Gold back!";
      iconData = Icons.handshake_rounded;
      iconColor = AppColors.accentGold;
      provider.addGold(180);
    }

    if (_isHost && _roomId != null) {
      FirebaseFirestore.instance.collection('rooms').doc(_roomId).delete().catchError((e) => null);
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
                // Top Trophy/Game Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 54,
                  ),
                ),
                // Title
                Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Friendly status message
                Text(
                  contentText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
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
                            "YOUR SCORE",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_playerScore",
                            style: TextStyle(
                              color: AppColors.accentCyan,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      
                      // VS divider
                      Text(
                        "VS",
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.3),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      
                      // Opponent Score info
                      Column(
                        children: [
                          Text(
                            "OPP SCORE",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_botScore",
                            style: TextStyle(
                              color: AppColors.accentPink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
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

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final targetLang = gameProvider.state.targetLanguage;
    final currentQuestion = _questions[_currentQuestionIndex];
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

  /// Bắt đầu một vòng câu hỏi mới
  void _startQuestionRound() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length || _playerScore >= 10 || _botScore >= 10) {
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
    final provider = Provider.of<GameProvider>(context, listen: false);
    int bonusScore = 0;
    if (isCorrect) {
      AudioService().playCorrect(volume: provider.state.volume);
      _playerStreakCount++;

      if (_playerStreakCount == 2) {
        _playerComboText = "🔥 2X COMBO! (+1 Bonus PK)";
        _playerComboColor = const Color(0xFFFF8C00);
        _showPlayerComboBadge = true;
        bonusScore = 1;
        AudioService().playClaim(volume: provider.state.volume);
      } else if (_playerStreakCount == 3) {
        _playerComboText = "⚡ 3X SUPER COMBO! (+2 Bonus PK)";
        _playerComboColor = const Color(0xFF00FFFF);
        _showPlayerComboBadge = true;
        bonusScore = 2;
        AudioService().playClaim(volume: provider.state.volume);
      } else if (_playerStreakCount >= 5) {
        _playerComboText = "🌌 ${_playerStreakCount}X ULTRA COMBO! (+3 Bonus PK)";
        _playerComboColor = const Color(0xFFFF00FF);
        _showPlayerComboBadge = true;
        bonusScore = 3;
        AudioService().playClaim(volume: provider.state.volume);
      }
    } else {
      AudioService().playWrong(volume: provider.state.volume);
      _playerStreakCount = 0;
      _showPlayerComboBadge = false;
    }

    final newScore = isCorrect ? _playerScore + 1 + bonusScore : _playerScore;
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
    IconData iconData;
    Color iconColor;

    if (scoreDiff > 0) {
      AudioService().playVictory(volume: provider.state.volume);
      titleText = "VICTORY!";
      titleColor = AppColors.accentCyan;
      contentText = "You defeated your opponent by a score of $myScore - $oppScore.\nYou received +400 Gold!";
      iconData = Icons.emoji_events_rounded;
      iconColor = AppColors.accentGold;
      provider.updateHighScore(myScore);
      provider.addGold(400);
    } else if (scoreDiff < 0) {
      AudioService().playDefeat(volume: provider.state.volume);
      titleText = "DEFEATED!";
      titleColor = AppColors.accentPink;
      contentText = "You lost to your opponent by a score of $myScore - $oppScore.\nYou lost the 200 Gold entry deposit!";
      iconData = Icons.sentiment_very_dissatisfied_rounded;
      iconColor = AppColors.accentPink;
    } else {
      AudioService().playClaim(volume: provider.state.volume);
      titleText = "DRAW!";
      titleColor = AppColors.accentGold;
      contentText = "It's a draw with a score of $myScore - $oppScore.\nBoth sides pay a 10% fee (20 Gold).\nYou received 180 Gold back!";
      iconData = Icons.handshake_rounded;
      iconColor = AppColors.accentGold;
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
                // Top Trophy/Game Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Friendly status message
                Text(
                  contentText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
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
                            "YOUR SCORE",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$myScore",
                            style: TextStyle(
                              color: AppColors.accentCyan,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      
                      // VS divider
                      Text(
                        "VS",
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.3),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      
                      // Opponent Score info
                      Column(
                        children: [
                          Text(
                            "OPP SCORE",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$oppScore",
                            style: TextStyle(
                              color: AppColors.accentPink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
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

  /// Kết thúc trận đấu Offline / Lỗi
  void _endGameOffline() {
    _questionTimer?.cancel();
    _botActionTimer?.cancel();

    final provider = Provider.of<GameProvider>(context, listen: false);
    final int scoreDiff = _playerScore - _botScore;

    String titleText;
    Color titleColor;
    String contentText;
    IconData iconData;
    Color iconColor;

    if (scoreDiff > 0) {
      titleText = "VICTORY!";
      titleColor = AppColors.accentCyan;
      contentText = "You defeated your opponent by a score of $_playerScore - $_botScore.\nYou received +400 Gold!";
      iconData = Icons.emoji_events_rounded;
      iconColor = AppColors.accentGold;
      provider.updateHighScore(_playerScore);
      provider.addGold(400);
    } else if (scoreDiff < 0) {
      titleText = "DEFEATED!";
      titleColor = AppColors.accentPink;
      contentText = "You lost to your opponent by a score of $_playerScore - $_botScore.\nYou lost the 200 Gold entry deposit!";
      iconData = Icons.sentiment_very_dissatisfied_rounded;
      iconColor = AppColors.accentPink;
    } else {
      titleText = "DRAW!";
      titleColor = AppColors.accentGold;
      contentText = "It's a draw with a score of $_playerScore - $_botScore.\nBoth sides pay a 10% fee (20 Gold).\nYou received 180 Gold back!";
      iconData = Icons.handshake_rounded;
      iconColor = AppColors.accentGold;
      provider.addGold(180);
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
                // Top Trophy/Game Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Friendly status message
                Text(
                  contentText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.7),
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
                            "YOUR SCORE",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_playerScore",
                            style: TextStyle(
                              color: AppColors.accentCyan,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      
                      // VS divider
                      Text(
                        "VS",
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.3),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      
                      // Opponent Score info
                      Column(
                        children: [
                          Text(
                            "OPP SCORE",
                            style: TextStyle(
                              color: AppColors.textPrimary.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_botScore",
                            style: TextStyle(
                              color: AppColors.accentPink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
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
            colors: [AppColors.bgPrimary, AppColors.bgSecondary],
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
                    const runnerWidth = 56.0;
                    const finishWidth = 36.0;
                    final usableTrackWidth = trackWidth - runnerWidth - finishWidth;
                    
                    final playerLeft = (_playerScore / 10.0) * usableTrackWidth;
                    final botLeft = (_botScore / 10.0) * usableTrackWidth;

                    final scoreDiff = _playerScore - _botScore;

                    return GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Track + Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "🏁 CYBER BATTLE TRACK", 
                                style: TextStyle(
                                  color: AppColors.textPrimary, 
                                  fontSize: 11, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: scoreDiff > 0 
                                      ? AppColors.accentCyan.withOpacity(0.2) 
                                      : (scoreDiff < 0 ? AppColors.accentPink.withOpacity(0.2) : Colors.amber.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scoreDiff > 0 
                                        ? AppColors.accentCyan 
                                        : (scoreDiff < 0 ? AppColors.accentPink : Colors.amber),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  scoreDiff > 0 
                                      ? "🔥 IN THE LEAD (+$scoreDiff)" 
                                      : (scoreDiff < 0 ? "⚡ TRAILING ($scoreDiff)" : "⚔️ EVEN (0)"),
                                  style: TextStyle(
                                    color: scoreDiff > 0 
                                        ? AppColors.accentCyan 
                                        : (scoreDiff < 0 ? AppColors.accentPink : Colors.amber),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Làn của người chơi
                          _buildLaneTrack(
                            nickname: playerState.nickname,
                            score: _playerScore,
                            leftPos: playerLeft,
                            usableWidth: usableTrackWidth,
                            trackWidth: trackWidth,
                            runnerWidth: runnerWidth,
                            finishWidth: finishWidth,
                            isPlayer: true,
                            characterId: playerState.equippedCharacter,
                            hatId: playerState.equippedHat,
                            shoesId: playerState.equippedShoes,
                            effectId: playerState.equippedEffect,
                            trackId: playerState.equippedTrack,
                          ),
                          const SizedBox(height: 12),

                          // Làn của Bot / Đối thủ
                          _buildLaneTrack(
                            nickname: _opponentName,
                            score: _botScore,
                            leftPos: botLeft,
                            usableWidth: usableTrackWidth,
                            trackWidth: trackWidth,
                            runnerWidth: runnerWidth,
                            finishWidth: finishWidth,
                            isPlayer: false,
                            characterId: _opponentCharId,
                            hatId: _opponentHatId,
                            shoesId: _opponentShoesId,
                            effectId: _opponentEffectId,
                            trackId: _opponentTrackId,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // 2.5 Streak Combo Badge
              if (_showPlayerComboBadge && _playerComboText != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _playerComboColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _playerComboColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _playerComboColor.withOpacity(0.4),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        _playerComboText!,
                        style: TextStyle(
                          color: _playerComboColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              // 2.6 Translation toggle bar
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
                    label: Builder(
                      builder: (context) {
                        final targetLang = Provider.of<GameProvider>(context).state.targetLanguage.toUpperCase();
                        return Text(_isTranslated ? "Original (EN)" : "Translate ($targetLang)", style: const TextStyle(fontSize: 12));
                      },
                    ),
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
            colors: [AppColors.bgPrimary, AppColors.bgSecondary],
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
                  "Connecting to live match in $_matchmakingSec seconds...",
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

  Widget _buildLaneTrack({
    required String nickname,
    required int score,
    required double leftPos,
    required double usableWidth,
    required double trackWidth,
    required double runnerWidth,
    required double finishWidth,
    required bool isPlayer,
    required String characterId,
    required String hatId,
    required String shoesId,
    required String effectId,
    required String trackId,
  }) {
    final themeColor = isPlayer ? AppColors.accentCyan : AppColors.accentPink;
    
    // Theme customization based on equipped track
    Color trackBg = const Color(0xFF0F1322);
    Color trackBorder = themeColor;
    List<Color> trailGradient = isPlayer
        ? [AppColors.accentCyan.withOpacity(0.7), AppColors.accentCyan.withOpacity(0.05)]
        : [AppColors.accentPink.withOpacity(0.7), AppColors.accentPink.withOpacity(0.05)];
    List<Color> finishGradient = const [Color(0xFFFFD700), Color(0xFFFF8C00)];
    String trackWatermark = "";

    if (trackId == 'track_sakura') {
      trackBg = const Color(0xFF2E1527);
      trackBorder = const Color(0xFFFF69B4);
      trailGradient = [const Color(0xFFFFB7C5), const Color(0xFFFF69B4).withOpacity(0.1)];
      finishGradient = [const Color(0xFFFFB7C5), const Color(0xFFFF1493)];
      trackWatermark = "🌸";
    } else if (trackId == 'track_lightning') {
      trackBg = const Color(0xFF16102D);
      trackBorder = const Color(0xFF9370DB);
      trailGradient = [const Color(0xFF00FFFF), const Color(0xFF8A2BE2).withOpacity(0.1)];
      finishGradient = [const Color(0xFF00FFFF), const Color(0xFF8A2BE2)];
      trackWatermark = "⚡";
    } else if (trackId == 'track_hellfire') {
      trackBg = const Color(0xFF2C0A0A);
      trackBorder = const Color(0xFFFF4500);
      trailGradient = [const Color(0xFFFFD700), const Color(0xFFFF4500).withOpacity(0.1)];
      finishGradient = [const Color(0xFFFF4500), const Color(0xFF8B0000)];
      trackWatermark = "🔥";
    } else if (trackId == 'track_galaxy') {
      trackBg = const Color(0xFF0C0926);
      trackBorder = const Color(0xFFE066FF);
      trailGradient = [const Color(0xFFE066FF), const Color(0xFF4B0082).withOpacity(0.1)];
      finishGradient = [const Color(0xFFFFD700), const Color(0xFF9400D3)];
      trackWatermark = "✨";
    } else if (trackId == 'track_gold') {
      trackBg = const Color(0xFF281E08);
      trackBorder = const Color(0xFFFFD700);
      trailGradient = [const Color(0xFFFFF8DC), const Color(0xFFFFD700).withOpacity(0.1)];
      finishGradient = [const Color(0xFFFFFFFF), const Color(0xFFFFD700)];
      trackWatermark = "👑";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(isPlayer ? Icons.person : Icons.smart_toy, color: trackBorder, size: 14),
                const SizedBox(width: 4),
                Text(
                  nickname,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              "$score / 10 PK",
              style: TextStyle(color: trackBorder, fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 76,
          width: double.infinity,
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: trackBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: trackBorder.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: trackBorder.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background Watermark Emoji
              if (trackWatermark.isNotEmpty)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "$trackWatermark  $trackWatermark  $trackWatermark",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white.withOpacity(0.08),
                        letterSpacing: 20,
                      ),
                    ),
                  ),
                ),

              // 1. Grid Checkpoints (10 nấc vạch kẻ)
              Positioned.fill(
                child: Row(
                  children: List.generate(10, (index) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withOpacity(0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 2. Vạch Đích (FINISH GATE 🏁)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: finishWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: finishGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: finishGradient.first.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("🏁", style: TextStyle(fontSize: 13)),
                        Text("GOAL", style: TextStyle(fontSize: 7, color: Colors.black, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Dải Sáng Nitro Progress Trail chạy sau lưng Avatar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                left: 0,
                top: 0,
                bottom: 0,
                width: (leftPos + runnerWidth / 2).clamp(0.0, trackWidth - finishWidth),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: trailGradient,
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // 4. Avatar Runner với Hiệu ứng Phụ kiện & Phát sáng Motion Glow
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                left: leftPos,
                top: 4,
                child: RunnerWidget(
                  characterId: characterId,
                  hatId: hatId,
                  shoesId: shoesId,
                  effectId: effectId,
                  size: 48,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


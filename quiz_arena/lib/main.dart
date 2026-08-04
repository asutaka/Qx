import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/colors.dart';
import 'logic/game_provider.dart';
import 'presentation/screens/lobby_screen.dart';
import 'presentation/screens/battle_screen.dart';
import 'presentation/screens/quiz_screen.dart';
import 'presentation/screens/shop_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/rank_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully!");
  } catch (e) {
    print("Firebase initialization error (using fallback): $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: const QuizArenaApp(),
    ),
  );
}

class QuizArenaApp extends StatelessWidget {
  const QuizArenaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark();
    return MaterialApp(
      title: 'Quiz Arena',
      debugShowCheckedModeBanner: false,
      theme: darkTheme.copyWith(
        scaffoldBackgroundColor: AppColors.bgPrimary,
        primaryColor: AppColors.accentCyan,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentCyan,
          secondary: AppColors.accentPink,
          background: AppColors.bgPrimary,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(darkTheme.textTheme),
      ),
      home: const MainNavigationController(),
    );
  }
}

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({Key? key}) : super(key: key);

  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> {
  // Trạng thái điều hướng màn hình hiện tại
  // Hỗ trợ: 'lobby', 'single', 'battle', 'shop', 'settings', 'rank'
  String _currentScreen = 'lobby';

  void _navigateTo(String screenName) {
    setState(() {
      _currentScreen = screenName;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case 'single':
        return QuizScreen(
          onBackToLobby: () => _navigateTo('lobby'),
        );
      case 'battle':
        return BattleScreen(
          onBackToLobby: () => _navigateTo('lobby'),
        );
      case 'shop':
        return ShopScreen(
          onBackToLobby: () => _navigateTo('lobby'),
        );
      case 'settings':
        return SettingsScreen(
          onBackToLobby: () => _navigateTo('lobby'),
        );
      case 'rank':
        return RankScreen(
          onBackToLobby: () => _navigateTo('lobby'),
        );
      case 'lobby':
      default:
        return LobbyScreen(
          onStartSingle: () => _navigateTo('single'),
          onStartBattle: () => _navigateTo('battle'),
          onOpenShop: () => _navigateTo('shop'),
          onOpenSettings: () => _navigateTo('settings'),
          onOpenRank: () => _navigateTo('rank'),
        );
    }
  }
}

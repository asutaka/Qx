import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // --- CẤU HÌNH CHO WEB ---
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBhu8v2MpCvlOKqyzsS6-jdcFWmEDvQUiI",
    authDomain: "quiz-b35e2.firebaseapp.com",
    projectId: "quiz-b35e2",
    storageBucket: "quiz-b35e2.firebasestorage.app",
    messagingSenderId: "784208965058",
    appId: "1:784208965058:web:75515beea1b7dad19eba5b",
    measurementId: "G-1JYB0JFW4Z"
  );

  // --- CẤU HÌNH CHO ANDROID ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhu8v2MpCvlOKqyzsS6-jdcFWmEDvQUiI',
    appId: '1:784208965058:android:183e54b6f1cf0d3d9eba5b',
    messagingSenderId: '784208965058',
    projectId: 'quiz-b35e2',
    storageBucket: 'quiz-b35e2.firebasestorage.app',
  );

  // --- CẤU HÌNH CHO IOS ---
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhu8v2MpCvlOKqyzsS6-jdcFWmEDvQUiI',
    appId: '1:784208965058:ios:ae428aad0788baa69eba5b',
    messagingSenderId: '784208965058',
    projectId: 'quiz-b35e2',
    storageBucket: 'quiz-b35e2.firebasestorage.app',
    iosBundleId: 'com.example.quizArena',
  );
}

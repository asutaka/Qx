// File cấu hình mẫu cho Firebase. Sẽ được ghi đè hoàn toàn khi bạn chạy lệnh:
// flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'placeholder-api-key',
      appId: 'placeholder-app-id',
      messagingSenderId: 'placeholder-sender-id',
      projectId: 'placeholder-project-id',
      authDomain: 'placeholder-auth-domain',
      storageBucket: 'placeholder-storage-bucket',
    );
  }
}

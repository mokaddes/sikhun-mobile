import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Programmatic Firebase options for the Sikhun production project (`sikhun-52abd`).
/// Allows clean initialization on Android/iOS/Web without requiring google-services.json
/// in CI builds.
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
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAN1UCm4GXHzA1_rf7wjhG3Z_9d0P8Y6hM',
    appId: '1:169250530746:web:b18213a04b5f52f345a983',
    messagingSenderId: '169250530746',
    projectId: 'sikhun-52abd',
    authDomain: 'sikhun-52abd.firebaseapp.com',
    storageBucket: 'sikhun-52abd.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAN1UCm4GXHzA1_rf7wjhG3Z_9d0P8Y6hM',
    appId: '1:169250530746:web:b18213a04b5f52f345a983',
    messagingSenderId: '169250530746',
    projectId: 'sikhun-52abd',
    storageBucket: 'sikhun-52abd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAN1UCm4GXHzA1_rf7wjhG3Z_9d0P8Y6hM',
    appId: '1:169250530746:web:b18213a04b5f52f345a983',
    messagingSenderId: '169250530746',
    projectId: 'sikhun-52abd',
    storageBucket: 'sikhun-52abd.firebasestorage.app',
    iosBundleId: 'com.sikhun.sikhunMobile',
  );
}

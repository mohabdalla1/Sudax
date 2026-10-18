
import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

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
    apiKey: 'AIzaSyAaxRtKoAc1NNr3ZckJwASceMwbvrtebuE',
    appId: '1:95601748411:web:ef873f77ff0a0536a2fc9e',
    messagingSenderId: '95601748411',
    projectId: 'sudax-7b575',
    authDomain: 'sudax-7b575.firebaseapp.com',
    storageBucket: 'sudax-7b575.firebasestorage.app',
  );

  // These aliases are suitable for Web configuration only.
  // Replace them with platform-specific options before using
  // this configuration to initialize native Android or iOS apps.
  static const FirebaseOptions android = web;
  static const FirebaseOptions ios = web;
}

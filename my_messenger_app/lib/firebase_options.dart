import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDcYuFVq69ft7nr2W3CDb6eFuW3ZNvvEQc',
    appId: '1:747106508037:web:d03a8f6ab30aea5a5a2b6c',
    messagingSenderId: '747106508037',
    projectId: 'rytext-f030d',
    authDomain: 'rytext-f030d.firebaseapp.com',
    storageBucket: 'rytext-f030d.firebasestorage.app',
    measurementId: 'G-JW5HEL8M34',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789012:android:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'rytext-f030d',
    storageBucket: 'rytext-f030d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'rytext-f030d',
    storageBucket: 'rytext-f030d.appspot.com',
    iosBundleId: 'com.example.myMessengerApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'rytext-f030d',
    storageBucket: 'rytext-f030d.appspot.com',
    iosBundleId: 'com.example.myMessengerApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789012:web:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'rytext-f030d',
    authDomain: 'rytext-f030d.firebaseapp.com',
    storageBucket: 'rytext-f030d.appspot.com',
  );
} 
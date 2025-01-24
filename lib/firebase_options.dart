// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA3AJlKpFzXn6fSAppSPQ7sWkziGuDQ2Ig',
    appId: '1:172479368024:web:9b4fa33d3c9413f157b32d',
    messagingSenderId: '172479368024',
    projectId: 'fir-flutter-c623d',
    authDomain: 'fir-flutter-c623d.firebaseapp.com',
    storageBucket: 'fir-flutter-c623d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD69tD8s4gU4IJj3gLMdn-xQz1TIXxs75E',
    appId: '1:172479368024:android:692778e4f9b0c33257b32d',
    messagingSenderId: '172479368024',
    projectId: 'fir-flutter-c623d',
    storageBucket: 'fir-flutter-c623d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDXsXYg5avzdT3YOxi457tFPA_xckq6SPA',
    appId: '1:172479368024:ios:4926332f13727b1c57b32d',
    messagingSenderId: '172479368024',
    projectId: 'fir-flutter-c623d',
    storageBucket: 'fir-flutter-c623d.firebasestorage.app',
    iosBundleId: 'com.example.intecSocialApp',
  );

}
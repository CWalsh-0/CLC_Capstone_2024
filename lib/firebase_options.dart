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
    apiKey: 'AIzaSyAVbP8Qn7zgEtiboz2LCGJ-aQTOwN-qXWs',
    appId: '1:698464399536:web:7f179d240f69d19be78b75',
    messagingSenderId: '698464399536',
    projectId: 'keyfob-pj',
    authDomain: 'keyfob-pj.firebaseapp.com',
    storageBucket: 'keyfob-pj.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC88RLAxJFBlcNkQwBtxez_-VFDdnREDn8',
    appId: '1:698464399536:android:649093a951f9629ee78b75',
    messagingSenderId: '698464399536',
    projectId: 'keyfob-pj',
    storageBucket: 'keyfob-pj.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJsLXh1HRPgCcqLee14VyqHLj5t2N8iMo',
    appId: '1:698464399536:ios:3094445cc7a1f0d0e78b75',
    messagingSenderId: '698464399536',
    projectId: 'keyfob-pj',
    storageBucket: 'keyfob-pj.firebasestorage.app',
    iosBundleId: 'com.example.flutterdb',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBJsLXh1HRPgCcqLee14VyqHLj5t2N8iMo',
    appId: '1:698464399536:ios:3094445cc7a1f0d0e78b75',
    messagingSenderId: '698464399536',
    projectId: 'keyfob-pj',
    storageBucket: 'keyfob-pj.firebasestorage.app',
    iosBundleId: 'com.example.flutterdb',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAVbP8Qn7zgEtiboz2LCGJ-aQTOwN-qXWs',
    appId: '1:698464399536:web:5123fca80b777243e78b75',
    messagingSenderId: '698464399536',
    projectId: 'keyfob-pj',
    authDomain: 'keyfob-pj.firebaseapp.com',
    storageBucket: 'keyfob-pj.firebasestorage.app',
  );

}
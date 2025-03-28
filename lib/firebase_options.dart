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
    apiKey: 'AIzaSyCn3KW9aOfupAa8-VQT3MGBaaJqycawV3s',
    appId: '1:379390566634:web:b20b8e94b0e96eb794f793',
    messagingSenderId: '379390566634',
    projectId: 'remind-dev-20a7c',
    authDomain: 'remind-dev-20a7c.firebaseapp.com',
    storageBucket: 'remind-dev-20a7c.appspot.com',
    measurementId: 'G-1LMXC5TMNF',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmyNQ6nknuj4ZeIzc611ls-oMl_YbnJ5o',
    appId: '1:379390566634:ios:f4ba9fc1d723f39294f793',
    messagingSenderId: '379390566634',
    projectId: 'remind-dev-20a7c',
    storageBucket: 'remind-dev-20a7c.appspot.com',
    iosBundleId: 'com.example.remindDev',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDmyNQ6nknuj4ZeIzc611ls-oMl_YbnJ5o',
    appId: '1:379390566634:ios:f4ba9fc1d723f39294f793',
    messagingSenderId: '379390566634',
    projectId: 'remind-dev-20a7c',
    storageBucket: 'remind-dev-20a7c.appspot.com',
    iosBundleId: 'com.example.remindDev',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCn3KW9aOfupAa8-VQT3MGBaaJqycawV3s',
    appId: '1:379390566634:web:684bc34944a521ef94f793',
    messagingSenderId: '379390566634',
    projectId: 'remind-dev-20a7c',
    authDomain: 'remind-dev-20a7c.firebaseapp.com',
    storageBucket: 'remind-dev-20a7c.appspot.com',
    measurementId: 'G-0J1PYS232S',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA2_OMMFyL4oxgU5SAnyIYwg82ry7HR5-0',
    appId: '1:379390566634:android:72df2f5dfe5070cf94f793',
    messagingSenderId: '379390566634',
    projectId: 'remind-dev-20a7c',
    storageBucket: 'remind-dev-20a7c.appspot.com',
  );

}
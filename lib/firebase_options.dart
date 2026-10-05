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
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDwkmfRn7_GZwUslawEuWRYUvkceL96xNg',
    appId: '1:121993344266:web:27ebcee3efe000a251f6f3',
    messagingSenderId: '121993344266',
    projectId: 'examinantt-ae432',
    authDomain: 'examinantt-ae432.firebaseapp.com',
    storageBucket: 'examinantt-ae432.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwkmfRn7_GZwUslawEuWRYUvkceL96xNg',
    appId: '1:121993344266:android:27ebcee3efe000a251f6f3',
    messagingSenderId: '121993344266',
    projectId: 'examinantt-ae432',
    authDomain: 'examinantt-ae432.firebaseapp.com',
    storageBucket: 'examinantt-ae432.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwkmfRn7_GZwUslawEuWRYUvkceL96xNg',
    appId: '1:121993344266:ios:27ebcee3efe000a251f6f3',
    messagingSenderId: '121993344266',
    projectId: 'examinantt-ae432',
    authDomain: 'examinantt-ae432.firebaseapp.com',
    storageBucket: 'examinantt-ae432.appspot.com',
  );
}

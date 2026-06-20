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
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB0-PX-my1Y4cquM66ZK2yvR7cvFFrXAwo',
    appId: '1:177916001676:web:b6515932f4cd5b9cd7aaa9',
    messagingSenderId: '177916001676',
    projectId: 'smartparkingsystem-e8234',
    authDomain: 'smartparkingsystem-e8234.firebaseapp.com',
    storageBucket: 'smartparkingsystem-e8234.firebasestorage.app',
    measurementId: 'G-C2F9VZY6Z2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBZCKFs2PXNlF1VkzNmG4WAxLY8LArYiWo',
    appId: '1:177916001676:android:f7ee41ffa48f08e7d7aaa9',
    messagingSenderId: '177916001676',
    projectId: 'smartparkingsystem-e8234',
    storageBucket: 'smartparkingsystem-e8234.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDNJiWN20VqUdbtK0bjWjB0sI-ZeSmogh4',
    appId: '1:177916001676:ios:7c3d5d2878dc10acd7aaa9',
    messagingSenderId: '177916001676',
    projectId: 'smartparkingsystem-e8234',
    storageBucket: 'smartparkingsystem-e8234.firebasestorage.app',
    iosBundleId: 'com.example.mobile',
  );
}

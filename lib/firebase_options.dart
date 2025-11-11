// Placeholder Firebase options. Replace with FlutterFire CLI generated values.
// Run: flutterfire configure
// Then delete this file and use the generated one.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhCKoqSbPkCB15WIRrTPDCqsIC5AxIsjo',
    appId: '1:713418788893:web:6e6ef63e6f745409ce36f4',
    messagingSenderId: '713418788893',
    projectId: 'e-commerce-app-portfolio',
    authDomain: 'e-commerce-app-portfolio.firebaseapp.com',
    storageBucket: 'e-commerce-app-portfolio.firebasestorage.app',
  );

  // TODO: Replace all values below with real configs from FlutterFire CLI

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDYmD1dE7h0nMUEWUdOCfoVEOx7N_vsh8g',
    appId: '1:713418788893:android:711a518f3f8f3eddce36f4',
    messagingSenderId: '713418788893',
    projectId: 'e-commerce-app-portfolio',
    storageBucket: 'e-commerce-app-portfolio.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDTQaWakIB0eRs-gBqLDzHYUlOM8qOaGWc',
    appId: '1:713418788893:ios:20c6e4b7d9fe4887ce36f4',
    messagingSenderId: '713418788893',
    projectId: 'e-commerce-app-portfolio',
    storageBucket: 'e-commerce-app-portfolio.firebasestorage.app',
    iosBundleId: 'com.example.bmcEcommerce',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.bmcecommerce',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR_LINUX_API_KEY',
    appId: 'YOUR_LINUX_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}

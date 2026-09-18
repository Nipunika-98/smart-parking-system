# Smart Parking Mobile Application

The mobile application is the user-facing Flutter component of the Smart Parking System. It allows vehicle owners to access parking information, manage vehicles, track parking sessions, and view related payments and history.

## Features

- User registration and login
- Forgot-password and change-password flows
- View available parking slots and parking levels
- Add and manage vehicles
- QR-code parking flow
- Active parking-session tracking
- Parking history
- Parking-rate viewing
- Payment confirmation
- Notifications
- User profile management

## Technology Stack

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider
- Google Sign-In

## Requirements

- Flutter SDK with Dart SDK 3.7 or a compatible version
- Android Studio and Android SDK for Android development
- An Android emulator or physical device
- Firebase project configuration

Check your environment with:

```bash
flutter doctor
```

## Installation

From the repository root:

```bash
cd mobile
flutter pub get
```

## Run the Application

```bash
flutter run
```

To run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Validation and Testing

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Clean and rebuild dependencies if required:

```bash
flutter clean
flutter pub get
```

## Build an Android APK

```bash
flutter build apk --release
```

The generated APK is normally located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

```text
mobile/
├── lib/
│   ├── constants/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── utils/
│   ├── widgets/
│   ├── firebase_options.dart
│   └── main.dart
├── assets/
├── android/
├── ios/
├── web/
├── test/
├── pubspec.yaml
├── firebase.json
└── firestore.rules
```

## Firebase Configuration

The application uses Firebase for authentication, Firestore data, storage, and real-time parking information. Confirm that the Firebase project configuration is available for the target platform before running the app.

Do not commit private service-account keys or other secret credentials to the repository.

## Important Notes

- The Firebase project must be active for cloud-dependent features to work.
- Authentication providers used by the application must be enabled in Firebase.
- Firestore collections and rules must be configured for the demonstration environment.
- QR scanning and other device features may require a physical device for complete testing.

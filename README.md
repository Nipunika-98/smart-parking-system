# Smart Parking System

A smart multi-level vehicle parking management system designed to optimize parking operations, improve user experience, and support real-time parking availability tracking.

This project combines a Flutter mobile application, an Angular dashboard, and an ESP32-based smart parking simulation to provide a complete end-to-end parking solution for drivers, administrators, and system operators.

## Project Overview

The Smart Parking System helps users:

- Search and view real-time parking availability
- Reserve or monitor parking slots
- Register vehicles and manage parking sessions
- Make digital payments and track transaction history
- View parking rates and active bookings
- Access a centralized dashboard for system monitoring and management

The system also simulates hardware-level parking slot status using sensors and LEDs, allowing the system to represent real parking occupancy data in a practical, testable way.

## Key Features

### Mobile Application
- User registration and login
- Forgot password and password change flow
- Vehicle registration and management
- Parking slot availability viewing
- Active parking session tracking
- Parking history and notifications
- QR-based entry/exit flow
- Payment confirmation and transaction records
- Profile management

### Admin Dashboard
- Parking slot management
- Parking rates configuration
- User directory and system monitoring
- Reports and analytics
- Transaction logs
- System settings and access control

### Smart Parking Simulation
- ESP32-based smart parking slot simulation
- Real-time occupancy status tracking
- Firebase integration for slot updates
- LED indicators to represent occupied / available slot states
- Simulation of multi-level parking logic

## Technology Stack

### Mobile App
- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider
- Google Sign-In

### Dashboard
- Angular
- TypeScript
- Angular Router
- Firebase SDK
- Chart.js
- ng2-charts

### Simulation / Hardware
- ESP32
- PlatformIO
- Arduino
- Adafruit NeoPixel
- Firebase Arduino Client
- Python Firebase bridge

## Repository Structure

```text
smart-parking-system/
├── README.md
├── mobile/                      # Flutter mobile app
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── pubspec.yaml
│   ├── firebase.json
│   └── README.md
├── dashboard/                   # Angular admin dashboard
│   ├── src/
│   ├── package.json
│   ├── angular.json
│   └── README.md
├── simulation/                  # ESP32 / hardware simulation
│   ├── src/
│   ├── include/
│   ├── lib/
│   ├── hardware_sim/
│   ├── platformio.ini
│   ├── requirements.txt
│   ├── firebase_bridge.py
│   ├── diagram.json
│   ├── wokwi.toml
│   └── wokwi-project.txt
└── .gitignore
```

## System Architecture

The system is organized into three connected layers:

1. Mobile Client
   - Used by drivers to access parking information and manage their parking sessions.

2. Admin Dashboard
   - Used by parking administrators to monitor and control parking operations.

3. Smart Parking Simulation / Hardware Layer
   - Represents real device-level parking slot states and sends data to the backend.

These components communicate using Firebase services, allowing real-time data synchronization across the application and dashboard.

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Nipunika-98/smart-parking-system.git
cd smart-parking-system
```

### 2. Mobile App Setup

```bash
cd mobile
flutter pub get
flutter analyze
flutter run
```

If you want to build the Android app:

```bash
flutter build apk --release
```

### 3. Dashboard Setup

```bash
cd dashboard
npm install
npm run build
npm start
```

Then open the app in the browser at:

```text
http://localhost:4200/
```

### 4. Simulation Setup

For the ESP32 simulation:

```bash
cd simulation
pio run
```

For Python bridge setup:

```bash
cd simulation
python -m venv .venv
source .venv/bin/activate   # Linux/macOS
# or .venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

## Firebase Configuration

This project uses Firebase for authentication, database access, and real-time parking updates.

Before running the app, ensure:

- Firebase project is created and active
- `google-services.json` is configured for Android
- Firebase configuration files are set correctly
- Firestore rules allow the required operations
- Service account credentials are configured when using the Python bridge

## Use Cases

- Drivers can find available parking spaces in real time.
- Users can manage their vehicles and parking sessions.
- Admins can monitor occupancy and revenue.
- The hardware simulation demonstrates the smart parking concept in practice.
- The system provides a scalable foundation for smart city and intelligent parking applications.

## Benefits

- Reduces time spent searching for parking
- Improves parking space utilization
- Enhances user convenience
- Supports automation and real-time monitoring
- Provides a practical IoT-enabled parking management solution

## Future Enhancements

- Real-time reservation system
- Dynamic pricing based on occupancy
- SMS/Email notifications
- Advanced analytics and prediction
- Integration with QR gate entry systems
- Additional parking floor management features
- Support for more hardware sensors and camera-based detection

## License

This project is intended for academic and project-development use. Please check the repository and institutional requirements before publishing or commercializing the application.

## Contributors

This project was developed as a smart parking management solution combining mobile, web, and IoT simulation components.

## Notes

This repository includes separate modules for the mobile app, dashboard, and simulation layer. Each part can be worked on and tested independently, but together they form a complete smart parking system.

---

For a full setup guide and execution instructions, refer to each project folder's README files in `mobile/`, `dashboard/`, and `simulation/`.

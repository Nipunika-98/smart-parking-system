# Smart Parking System

Smart multi-level vehicle parking management system designed to optimize parking operations, improve user experience, and provide real-time monitoring of parking availability.

## 1. Project Title

Smart Parking System

## 2. Abstract

The Smart Parking System is an integrated solution that combines a mobile application, a web dashboard, and a smart parking simulation to improve the efficiency of parking management in urban environments. The system allows users to view available parking slots, register vehicles, make payments, track active parking sessions, and monitor parking history. At the same time, administrators can manage parking slots, configure pricing, monitor transactions, and generate reports through a centralized dashboard.

The project addresses common problems such as vehicle congestion, inefficient parking-space utilization, and poor visibility of parking availability. By integrating real-time data, Firebase services, and hardware simulation, the system demonstrates a practical smart-city application that can be expanded for real-world deployment.

## 3. Problem Statement

Traditional parking systems often rely on manual monitoring, scattered information, and inefficient space utilization. Drivers waste time searching for available parking slots, while parking operators find it difficult to manage occupancy, user records, and transaction information. These inefficiencies create congestion, poor user experience, and reduced operational productivity.

The lack of a centralized system for monitoring, reporting, and real-time slot status makes parking management difficult in busy areas such as commercial complexes, universities, and public facilities.

## 4. Objectives

- Design a smart parking system that improves parking-slot visibility.
- Provide a user-friendly mobile application for drivers.
- Develop an admin dashboard for parking management and monitoring.
- Integrate real-time Firebase-based data synchronization.
- Simulate hardware-level parking occupancy using ESP32 and LED indicators.
- Reduce the time required to find available parking.
- Provide a scalable foundation for future smart-city and IoT implementations.

## 5. Scope of the Project

This project includes three primary components:

1. A mobile application for parking users.
2. A web-based admin dashboard for parking management.
3. A smart parking simulation for hardware and sensor-level behavior.

The system is intended for educational and prototype-level deployment. It demonstrates how real-time software, cloud services, and IoT concepts can improve parking operations.

## 6. Motivation

Parking management is a major challenge in modern urban environments. Drivers often spend unnecessary time finding available slots, while administrators lack accurate real-time information. Digital and smart technologies can simplify this process and improve user convenience and organizational efficiency.

This project provides a practical solution combining software engineering with IoT concepts. It is suitable for a university final-year project because it demonstrates mobile development, web development, cloud integration, database management, and embedded-system simulation.

## 7. System Overview

The Smart Parking System consists of the following layers:

- **Mobile Client Layer:** Used by drivers to find parking availability, register vehicles, make payments, and track sessions.
- **Admin Dashboard Layer:** Used by administrators to manage spaces, configure rates, monitor transactions, and generate reports.
- **Smart Simulation Layer:** Represents sensors, occupancy indicators, and parking-slot states through ESP32-based simulation.
- **Firebase Integration Layer:** Provides authentication, real-time data storage, and synchronization among the modules.

## 8. Functional Requirements

### 8.1 User Module

- User registration and login
- Password recovery and password change
- Vehicle registration and management
- View available parking slots
- Check parking rates
- Start and end parking sessions
- Track payment and parking history
- Receive notifications
- QR-based parking entry or exit flow

### 8.2 Admin Module

- View overall parking status
- Manage parking slots
- Set parking rates
- Track user records
- Monitor transaction logs
- Generate reports
- Manage system settings
- Control access to administrative functions

### 8.3 Simulation Module

- Simulate parking occupancy using ESP32 and LED states
- Update parking-slot status in real time
- Connect the simulation to Firebase
- Demonstrate sensor-based parking-monitoring behavior
- Support multi-level parking simulation

## 9. Non-Functional Requirements

- User-friendly interface
- Real-time data updates
- Secure authentication
- Data consistency across mobile and dashboard components
- Modular and maintainable code structure
- Scalability for future enhancement
- Compatibility with modern development tools and frameworks

## 10. System Architecture

```text
+-------------------+       +--------------------+       +----------------------+
| Mobile App        | ----> | Firebase / DB      | <---- | Admin Dashboard      |
| Flutter           |       | Authentication,    |       | Angular              |
| - Login           |       | Firestore, Storage |       | - Slot Management    |
| - Vehicles        |       +--------------------+       | - Reports            |
| - QR / Payment    |                                      | - Rates              |
| - Parking History |                                      | - Transactions       |
+-------------------+                                      +----------------------+
          ^
          |
          v
+-------------------+
| ESP32 / Simulation|
| - Slot sensors    |
| - LED indicators  |
| - Firebase sync   |
+-------------------+
```

## 11. Technology Stack

### Mobile Application

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider
- Google Sign-In

### Admin Dashboard

- Angular 19
- TypeScript
- Firebase SDK
- Angular Router
- Chart.js
- ng2-charts

### Hardware Simulation

- ESP32
- PlatformIO
- Arduino framework
- Adafruit NeoPixel
- Firebase Arduino Client Library
- Python Firebase bridge

## 12. Repository Structure

```text
smart-parking-system/
├── README.md
├── mobile/                    # Flutter mobile application
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── pubspec.yaml
│   ├── firebase.json
│   └── README.md
├── dashboard/                 # Angular admin dashboard
│   ├── src/
│   ├── package.json
│   ├── angular.json
│   └── README.md
├── simulation/                # ESP32 and hardware simulation
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

## 13. Module Description

### 13.1 Mobile Application

The mobile app provides the end-user interface for parking management. Drivers can register, log in, view parking slots, manage vehicles, monitor parking sessions, view rates, complete payment flows, and review their history.

### 13.2 Admin Dashboard

The dashboard provides a management interface for administrators to monitor slot utilization, control parking prices, manage users, review reports, and inspect transaction logs.

### 13.3 Hardware Simulation

The simulation module mimics a real smart parking environment using ESP32 logic and LED status indicators. It updates slot states in Firebase so that the mobile application and dashboard can reflect the simulated parking conditions.

## 14. User Flows

### Driver Flow

1. Register or log in.
2. Add a vehicle.
3. View parking availability.
4. Check parking rates and slot status.
5. Scan a QR code or begin a parking session.
6. Track the active session and complete payment.
7. Review transaction and parking history.

### Administrator Flow

1. Log in to the dashboard.
2. View occupancy and user activity.
3. Update rates or manage slot states.
4. Review reports and transaction logs.
5. Manage users and system settings.

## 15. Development Methodology

The project follows a modular software-development approach:

1. Requirement analysis
2. System design
3. UI/UX design
4. Mobile and dashboard development
5. Firebase integration
6. Hardware simulation
7. Testing and debugging
8. Documentation and final evaluation

This approach ensures that each component is developed and tested systematically before integration.

## 16. Firebase Integration

Firebase is used for:

- User authentication
- Cloud Firestore data storage
- Real-time parking-slot updates
- Transaction and parking-history storage
- Firebase Storage operations
- Synchronization between the mobile app, dashboard, and simulation

Before running the project, ensure that the Firebase project is active and that the required platform configuration files and Firestore rules are available.

> Do not commit Firebase service-account private keys or other secret credentials to a public repository. Configure them locally or provide them separately according to university requirements.

## 17. Installation and Setup

### 17.1 Clone the Repository

```bash
git clone https://github.com/Nipunika-98/smart-parking-system.git
cd smart-parking-system
```

### 17.2 Mobile Application Setup

Requirements:

- Flutter SDK with Dart SDK 3.7 or a compatible version
- Android Studio and Android SDK for Android builds
- A physical device or emulator

Commands:

```bash
cd mobile
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

To generate an Android release APK:

```bash
flutter build apk --release
```

### 17.3 Dashboard Setup

Requirements:

- Node.js and npm
- Angular CLI 19-compatible environment

Commands:

```bash
cd dashboard
npm install
npm run build
npm start
```

Open the dashboard at:

```text
http://localhost:4200/
```

To run tests:

```bash
npm test
```

### 17.4 ESP32 / PlatformIO Setup

Install Visual Studio Code with the PlatformIO extension, then open the `simulation` directory.

```bash
cd simulation
pio run
```

To upload to a connected ESP32 board:

```bash
pio run --target upload
pio device monitor
```

The PlatformIO project is configured for the ESP32 DOIT DevKit V1 board using the Arduino framework.

### 17.5 Python Firebase Bridge Setup

```bash
cd simulation
python -m venv .venv
```

Activate the environment on Linux/macOS:

```bash
source .venv/bin/activate
```

Activate it on Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

If the bridge requires Firebase Admin credentials, configure the service-account path locally using `GOOGLE_APPLICATION_CREDENTIALS`. Never commit the credential JSON file to the repository.

## 18. Configuration Requirements

Before running the complete system, confirm that:

- Flutter is installed and recognized by `flutter doctor`.
- Node.js and npm are installed.
- Python is installed for simulation support.
- Firebase configuration is complete.
- Android SDK is configured for mobile builds.
- PlatformIO is installed for ESP32 development.
- Required Firebase authentication providers are enabled.
- Firestore collections and security rules are configured for the demonstration.

## 19. Main Screens and Features

The mobile application includes screens such as:

- Login
- Registration
- Forgot Password
- Home
- Active Parking Session
- History
- Profile
- Add Vehicle
- QR Scan
- Payment Successful
- Notifications
- View Rates

The dashboard includes modules for:

- Parking slot management
- User directory
- Parking rates
- Reports
- Transaction logs
- System settings
- Login and access protection

## 20. Testing and Verification

The following checks should be completed before university submission:

```bash
cd mobile
flutter analyze
flutter test
```

```bash
cd dashboard
npm run build
npm test
```

```bash
cd simulation
pio run
```

Functional testing should cover:

- Application startup and navigation
- User registration and authentication
- Vehicle registration
- Parking-slot availability
- Active parking sessions
- QR flow and payment confirmation
- Firebase synchronization
- Dashboard rendering and reports
- Transaction logs
- ESP32 or Wokwi simulation behavior
- Error handling and recovery

## 21. Expected Outcomes

The completed system is expected to:

- Reduce the time users spend searching for parking.
- Improve parking-space utilization.
- Provide real-time visibility of parking status.
- Simplify administrative parking operations.
- Demonstrate practical integration between mobile, web, cloud, and IoT systems.

## 22. Challenges Faced

- Integrating multiple technologies into one solution
- Maintaining real-time synchronization between modules
- Configuring Firebase for different application platforms
- Aligning hardware simulation with application logic
- Managing authentication and data security
- Testing the system across different development environments

## 23. Limitations

- This is an academic prototype and not a full-scale production deployment.
- It depends on Firebase configuration and valid project credentials.
- Real hardware deployment would require sensor installation and environment-specific calibration.
- Payment processing may require a production payment gateway for real transactions.
- Additional backend and security hardening would be required for commercial deployment.

## 24. Future Enhancements

- Real-time parking reservation
- Dynamic pricing based on demand and occupancy
- SMS and email notifications
- AI-based parking prediction
- Advanced analytics and reporting
- Camera-based vehicle and slot detection
- Integration with production payment gateways
- Multi-location parking support
- Automatic barrier and gate control
- Smart-city scale deployment

## 25. Conclusion

The Smart Parking System is a practical and innovative solution that integrates mobile technology, web-based management, Firebase services, and IoT simulation to optimize parking operations. It demonstrates how software and hardware can work together to improve user experience, reduce parking search time, and enhance operational efficiency.

The project is suitable for a final-year university submission because it combines real-world problem solving, system analysis, UI development, cloud database integration, authentication, reporting, embedded simulation, and software testing in one complete system.

## 26. University Submission Checklist

Before submitting the project, verify the following:

- [ ] Main source code is available in the `main` branch.
- [ ] Mobile application runs successfully with `flutter run`.
- [ ] `flutter analyze` completes without errors.
- [ ] Mobile tests have been executed.
- [ ] Dashboard runs with `npm start`.
- [ ] Dashboard production build completes successfully.
- [ ] Simulation builds successfully with PlatformIO.
- [ ] Firebase configuration is documented without exposing private keys.
- [ ] Screenshots and demonstration videos are included separately if required.
- [ ] Final-year report, diagrams, test evidence, and user manual are attached.
- [ ] Temporary files, generated build folders, and secret credentials are excluded.
- [ ] Installation instructions have been tested on a clean computer.

## 27. Recommended Submission Documents

A complete university submission may include:

```text
submission/
├── final-year-project-report.pdf
├── user-manual.pdf
├── test-report.pdf
├── presentation.pptx
├── demonstration-video.mp4
├── architecture-diagram.png
├── database-design.png
├── screenshots/
└── source-code.zip
```

## 28. References and Credits

This project uses the following technologies and platforms:

- [Flutter](https://flutter.dev/)
- [Angular](https://angular.dev/)
- [Firebase](https://firebase.google.com/)
- [PlatformIO](https://platformio.org/)
- [ESP32](https://www.espressif.com/en/products/socs/esp32)
- [Wokwi](https://wokwi.com/)

## 29. Contributors

This project was developed as a smart parking management solution combining mobile, web, cloud, and IoT simulation components.

## 30. Related Documentation

For module-specific instructions, refer to:

- [`mobile/README.md`](mobile/README.md)
- [`dashboard/README.md`](dashboard/README.md)
- [`simulation/`](simulation/)

---

**Repository:** https://github.com/Nipunika-98/smart-parking-system

# Smart Parking Simulation

The simulation module represents the hardware and IoT layer of the Smart Parking System. It uses an ESP32-based PlatformIO project, LED indicators, Wokwi configuration, and a Python Firebase bridge to simulate parking-slot status and synchronize data with the application.

## Features

- ESP32 smart parking simulation
- Multi-slot and multi-level parking logic
- LED indicators for parking-slot states
- Firebase synchronization
- Wokwi simulation support
- Python Firebase bridge

## Technology Stack

- ESP32 DOIT DevKit V1
- PlatformIO
- Arduino framework
- C++
- Adafruit NeoPixel
- Firebase Arduino Client Library
- Python
- Firebase Admin SDK
- Wokwi

## Requirements

- Visual Studio Code with PlatformIO, or PlatformIO CLI
- ESP32 DOIT DevKit V1 board for hardware deployment
- Python 3
- Firebase project configuration
- Wokwi account if using the online simulator

## PlatformIO Setup

Open the `simulation` directory in Visual Studio Code with the PlatformIO extension installed.

Build the project:

```bash
cd simulation
pio run
```

Upload the firmware to a connected ESP32 board:

```bash
pio run --target upload
```

Open the serial monitor:

```bash
pio device monitor
```

The board and library dependencies are defined in `platformio.ini`.

## Wokwi Setup

The simulation includes the following Wokwi-related files:

- `diagram.json`
- `wokwi.toml`
- `wokwi-project.txt`

Open the project in Wokwi and use the provided diagram and configuration to run the virtual ESP32 circuit.

## Python Firebase Bridge

Create and activate a virtual environment:

```bash
python -m venv .venv
```

Linux/macOS:

```bash
source .venv/bin/activate
```

Windows PowerShell:

```powershell
.venv\Scripts\Activate.ps1
```

Install the Python dependencies:

```bash
pip install -r requirements.txt
```

The required packages include:

- `firebase-admin`
- `colorama`

Run the bridge, when configured for your environment:

```bash
python firebase_bridge.py
```

## Firebase Credentials

The Firebase bridge may require a Firebase Admin SDK service-account credential. Configure the credential locally through the `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

Linux/macOS:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
```

Windows PowerShell:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
```

Never commit service-account JSON files or private keys to the repository.

## Project Structure

```text
simulation/
├── src/
│   └── main.cpp
├── include/
├── lib/
├── hardware_sim/
├── test/
├── diagram.json
├── platformio.ini
├── requirements.txt
├── firebase_bridge.py
├── wokwi.toml
└── wokwi-project.txt
```

## Verification

Build the firmware before submission:

```bash
pio run
```

For hardware testing, verify that:

- The ESP32 connects successfully.
- LED indicators show the expected slot states.
- Serial output reports the expected sensor or slot status.
- Firebase receives the simulated updates.
- The mobile app and dashboard display the corresponding parking status.

## Troubleshooting

- Confirm that the correct ESP32 board and serial port are selected.
- Check the USB cable and board drivers if upload fails.
- Run `pio pkg update` if PlatformIO dependencies are missing.
- Verify Firebase credentials and network connectivity for bridge errors.
- Use Wokwi when physical ESP32 hardware is unavailable.

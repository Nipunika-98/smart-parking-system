#include <Arduino.h>
#include <Adafruit_NeoPixel.h>
#include <WiFi.h>
#include <time.h>
#include <Firebase_ESP_Client.h>

// Provide the token generation process info.
#include "addons/TokenHelper.h"

// ========================================
// 9-Slot Smart Parking Management System
// Wokwi-Compatible Version
// ========================================

// Insert your Firebase credentials here
#define FIREBASE_API_KEY "AIzaSyB0-PX-my1Y4cquM66ZK2yvR7cvFFrXAwo"
#define FIREBASE_PROJECT_ID "smartparkingsystem-e8234"
#define USER_EMAIL "nimal@smartpark.lk"
#define USER_PASSWORD "NimalSt1"

// WiFi Credentials (Wokwi default)
#define WIFI_SSID "Wokwi-GUEST"
#define WIFI_PASSWORD ""

#define NUM_SLOTS 9
#define LED_PIN 15
#define BRIGHTNESS 200
#define DETECTION_THRESHOLD 50 // Distance in cm to consider slot occupied

Adafruit_NeoPixel strip(NUM_SLOTS, LED_PIN, NEO_GRB + NEO_KHZ800);

// Pin assignments for 9 sensors (direct connection)
// Using only pins available in Wokwi ESP32 DevKit C V4
const int triggerPins[NUM_SLOTS] = {26, 25, 33, 32, 13, 12, 14, 27, 19};
const int echoPins[NUM_SLOTS] = {35, 34, 23, 16, 4, 22, 17, 5, 18};

// Slot names representing different levels
const String slotNames[NUM_SLOTS] = {
  "L1-A-01", "L1-A-07", "L1-B-03", 
  "L2-C-03", "L2-D-05", "L2-D-10", 
  "L3-E-04", "L3-E-09", "L3-F-02"
};

// Level mapping for the slots
const int slotLevels[NUM_SLOTS] = {1, 1, 1, 2, 2, 2, 3, 3, 3};

// State tracking
bool slotState[NUM_SLOTS];
int slotDistance[NUM_SLOTS];
int availableCount = NUM_SLOTS;

// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// NTP server for time
const char* ntpServer = "pool.ntp.org";

// Function to sync time
void initTime() {
  configTime(0, 0, ntpServer);
  Serial.print("Waiting for NTP time sync: ");
  time_t now = time(nullptr);
  while (now < 8 * 3600 * 2) {
    delay(500);
    Serial.print(".");
    now = time(nullptr);
  }
  Serial.println("\nTime synced.");
}

// Generate an RFC3339 formatted timestamp
String getTimestamp() {
  time_t now = time(nullptr);
  struct tm timeinfo;
  gmtime_r(&now, &timeinfo);
  char buffer[30];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
  return String(buffer);
}

// Read ultrasonic sensor
long readUltrasonic(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  return pulseIn(echoPin, HIGH, 30000);
}

// Update system statistics
void updateStatistics() {
  availableCount = 0;
  for (int i = 0; i < NUM_SLOTS; i++) {
    if (!slotState[i]) availableCount++;
  }
}

// Print system status
void printStatus() {
  Serial.println("\n========================================");
  Serial.println("PARKING STATUS SUMMARY");
  Serial.println("========================================");
  Serial.print("Available Slots: ");
  Serial.print(availableCount);
  Serial.print(" / ");
  Serial.println(NUM_SLOTS);
  Serial.print("Occupancy Rate: ");
  Serial.print(((NUM_SLOTS - availableCount) * 100) / NUM_SLOTS);
  Serial.println("%");
  Serial.println("----------------------------------------");
  
  for (int i = 0; i < NUM_SLOTS; i++) {
    Serial.print("Slot ");
    Serial.print(slotNames[i]);
    Serial.print(": ");
    Serial.print(slotState[i] ? "OCCUPIED" : "AVAILABLE");
    Serial.print(" (");
    Serial.print(slotDistance[i]);
    Serial.println("cm)");
  }
  Serial.println("========================================\n");
}

void updateFirestore(int index, bool isOccupied) {
  if (Firebase.ready()) {
    String documentPath = "parking_slots/";
    documentPath += slotNames[index];
    
    // Parse slot name to get base number (e.g. L1-A-01 -> A-01)
    int firstDash = slotNames[index].indexOf('-');
    String shortSlotName = slotNames[index].substring(firstDash + 1);
    
    FirebaseJson content;
    String timestamp = getTimestamp();
    
    // Create the structure requested
    content.set("fields/lastUpdated/timestampValue", timestamp);
    // Integer values in Firestore REST API can be passed as strings or we use integerValue but actually stringified int in the raw JSON
    content.set("fields/levelNumber/integerValue", String(slotLevels[index]));
    String sensorId = "SENSOR-";
    sensorId += shortSlotName;
    content.set("fields/sensorId/stringValue", sensorId);
    content.set("fields/sensorLastUpdate/timestampValue", timestamp);
    content.set("fields/sensorStatus/stringValue", "ONLINE");
    content.set("fields/slotNumber/stringValue", shortSlotName);
    content.set("fields/status/stringValue", isOccupied ? "OCCUPIED" : "AVAILABLE");

    Serial.print("Updating Firestore document: ");
    Serial.println(documentPath);
    
    // Use Patch document to update only specified fields or create if not exist
    if (Firebase.Firestore.patchDocument(&fbdo, FIREBASE_PROJECT_ID, "", documentPath.c_str(), content.raw(), "")) {
      Serial.println("✓ Firestore update success");
    } else {
      Serial.print("✗ Firestore update failed: ");
      Serial.println(fbdo.errorReason());
    }
  } else {
    Serial.println("✗ Firebase not ready, skipping update");
  }
}

void setup() {
  Serial.begin(115200);
  delay(500);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║  SMART PARKING MANAGEMENT SYSTEM       ║");
  Serial.println("║  9-Slot Configuration (Firebase)       ║");
  Serial.println("║  Author: Naveen Sanjaya                ║");
  Serial.println("╚════════════════════════════════════════╝\n");

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✓ WiFi connected");
  
  // Sync time
  initTime();
  
  // Initialize Firebase
  Serial.println("Initializing Firebase...");
  config.api_key = FIREBASE_API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  
  // Assign the callback function for the long running token generation task
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // Initialize sensor pins
  Serial.println("Initializing sensors...");
  for (int i = 0; i < NUM_SLOTS; i++) {
    pinMode(triggerPins[i], OUTPUT);
    pinMode(echoPins[i], INPUT);
    digitalWrite(triggerPins[i], LOW);
    slotState[i] = false;
    slotDistance[i] = 0;
    
    Serial.print("  Slot ");
    Serial.print(slotNames[i]);
    Serial.print(" (Trig: ");
    Serial.print(triggerPins[i]);
    Serial.print(", Echo: ");
    Serial.print(echoPins[i]);
    Serial.println(")");
  }

  // Initialize LED strip
  Serial.println("\nInitializing LED indicators...");
  strip.begin();
  strip.setBrightness(BRIGHTNESS);
  
  // Startup animation
  Serial.println("Running startup sequence...");
  for(int i = 0; i < NUM_SLOTS; i++) {
    strip.setPixelColor(i, strip.Color(0, 0, 255)); // Blue
    strip.show();
    delay(100);
  }
  
  // Set all to green (available)
  for(int i = 0; i < NUM_SLOTS; i++) {
    strip.setPixelColor(i, strip.Color(0, 255, 0)); // Green
  }
  strip.show();
  
  Serial.println("\n✓ System initialized successfully!");
  Serial.println("✓ All slots marked AVAILABLE (GREEN)");
  Serial.println("\nStarting real-time monitoring...\n");
  
  delay(1000);
}

void loop() {
  static unsigned long lastStatusPrint = 0;
  static int scanCount = 0;
  bool stateChanged = false;
  
  scanCount++;
  
  // Scan all slots
  for (int i = 0; i < NUM_SLOTS; i++) {
    // Read sensor
    long duration = readUltrasonic(triggerPins[i], echoPins[i]);
    int distance = duration * 0.034 / 2;
    
    slotDistance[i] = distance;
    
    // Determine occupancy
    bool isOccupied = (duration > 0 && distance < DETECTION_THRESHOLD);
    
    // Check for state change
    if (slotState[i] != isOccupied) {
      slotState[i] = isOccupied;
      stateChanged = true;
      
      // Update LED
      if (isOccupied) {
        strip.setPixelColor(i, strip.Color(255, 0, 0)); // Red
        Serial.print("🚗 Slot ");
        Serial.print(slotNames[i]);
        Serial.print(" -> OCCUPIED (Vehicle detected at ");
        Serial.print(distance);
        Serial.println("cm)");
      } else {
        strip.setPixelColor(i, strip.Color(0, 255, 0)); // Green
        Serial.print("✓ Slot ");
        Serial.print(slotNames[i]);
        Serial.println(" -> AVAILABLE");
      }
      strip.show();
      
      // Update Firebase
      updateFirestore(i, isOccupied);
    }
    
    delay(50); // Small delay between sensor readings
  }
  
  // Update statistics if any state changed
  if (stateChanged) {
    updateStatistics();
  }
  
  // Print full status every 10 seconds
  if (millis() - lastStatusPrint > 10000) {
    printStatus();
    lastStatusPrint = millis();
  }
  
  delay(100); // Delay between scan cycles
}
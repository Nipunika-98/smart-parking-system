#include <Arduino.h>

// --- PINS ---
const int TRIG_PIN = 25; 
const int ECHO_PIN = 33; 
const int LED_PIN  = 2;  

void setup() {
  Serial.begin(115200);
  Serial.println("--- MONITORING (Silent until < 20cm) ---");

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(LED_PIN, OUTPUT);
  
  digitalWrite(TRIG_PIN, LOW); 
}

void loop() {
  // 1. Trigger
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // 2. Read Echo
  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  int distance = duration * 0.034 / 2;

  // 3. Logic: Only print and light up if closer than 20cm
  if (distance > 0 && distance < 20) {
    
    // Print ONLY when close
    Serial.print("Object Detected: ");
    Serial.print(distance);
    Serial.println(" cm");
    
    digitalWrite(LED_PIN, HIGH); // LED ON
  } else {
    // If far away or error (0), do nothing but turn off LED
    digitalWrite(LED_PIN, LOW);  // LED OFF
  }

  delay(500); 
}
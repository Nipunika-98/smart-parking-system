#!/usr/bin/env python3
"""
Smart Parking System - Firebase Bridge Script
=============================================
Simulates 9 ultrasonic parking sensors (matching the Wokwi circuit)
and pushes real-time slot status updates to Firebase Firestore.

Run this alongside the Wokwi simulation in VS Code.
The Wokwi circuit is a visual demo; this script drives the live data.

Usage:
  python firebase_bridge.py

Commands (once running):
  <num> o     → Set slot OCCUPIED     (e.g., "1 o")
  <num> a     → Set slot AVAILABLE    (e.g., "3 a")
  <num> m     → Set slot MAINTENANCE  (e.g., "7 m")
  auto        → Toggle slots randomly (demo mode)
  reset       → Set all slots to AVAILABLE
  status      → Print current slot states
  quit        → Exit

Slot mapping:
  1=L1-A-01  2=L1-A-02  3=L1-A-03
  4=L1-B-01  5=L1-B-02  6=L1-B-03
  7=L1-C-01  8=L1-C-02  9=L1-C-03
"""

import sys
import os
import time
import random
import threading
from datetime import datetime

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed.")
    print("Run: pip install firebase-admin colorama")
    sys.exit(1)

try:
    import colorama
    from colorama import Fore, Back, Style
    colorama.init(autoreset=True)
    HAS_COLOR = True
except ImportError:
    HAS_COLOR = False
    # Stub colorama
    class _Stub:
        def __getattr__(self, name): return ""
    Fore = Back = Style = _Stub()

# ─────────────────────────────────────────────────────────────
#  CONFIGURATION
# ─────────────────────────────────────────────────────────────

SERVICE_ACCOUNT_FILE = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")

# 9 slots matching the Wokwi circuit layout
SLOT_MAP = {
    "1": {"doc_id": "L1-A-01", "sensor_id": "A1", "zone": "Zone A", "label": "A-01"},
    "2": {"doc_id": "L1-A-02", "sensor_id": "A2", "zone": "Zone A", "label": "A-02"},
    "3": {"doc_id": "L1-A-03", "sensor_id": "A3", "zone": "Zone A", "label": "A-03"},
    "4": {"doc_id": "L1-B-01", "sensor_id": "B1", "zone": "Zone B", "label": "B-01"},
    "5": {"doc_id": "L1-B-02", "sensor_id": "B2", "zone": "Zone B", "label": "B-02"},
    "6": {"doc_id": "L1-B-03", "sensor_id": "B3", "zone": "Zone B", "label": "B-03"},
    "7": {"doc_id": "L1-C-01", "sensor_id": "C1", "zone": "Zone C", "label": "C-01"},
    "8": {"doc_id": "L1-C-02", "sensor_id": "C2", "zone": "Zone C", "label": "C-02"},
    "9": {"doc_id": "L1-C-03", "sensor_id": "C3", "zone": "Zone C", "label": "C-03"},
}

STATUS_COLORS = {
    "AVAILABLE":   Fore.GREEN,
    "OCCUPIED":    Fore.RED,
    "MAINTENANCE": Fore.YELLOW,
}

STATUS_ICONS = {
    "AVAILABLE":   "🟢",
    "OCCUPIED":    "🔴",
    "MAINTENANCE": "🟡",
}

# ─────────────────────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────────────────────

slot_states = {num: "AVAILABLE" for num in SLOT_MAP}
db = None
auto_mode = False
auto_thread = None

# ─────────────────────────────────────────────────────────────
#  FIREBASE INIT
# ─────────────────────────────────────────────────────────────

def init_firebase():
    global db
    if not os.path.exists(SERVICE_ACCOUNT_FILE):
        print(f"\n{Fore.RED}✗ ERROR: serviceAccountKey.json not found!")
        print(f"{Fore.YELLOW}Download it from Firebase Console:")
        print(f"  Project Settings → Service Accounts → Generate new private key")
        print(f"  Save as: {SERVICE_ACCOUNT_FILE}\n")
        sys.exit(1)

    try:
        cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print(f"{Fore.GREEN}✓ Firebase connected (project: smartparkingsystem-e8234)")
    except Exception as e:
        print(f"{Fore.RED}✗ Firebase init failed: {e}")
        sys.exit(1)

# ─────────────────────────────────────────────────────────────
#  FIRESTORE UPDATE
# ─────────────────────────────────────────────────────────────

def update_slot(num: str, status: str, distance_cm: int = 0) -> bool:
    """Update a single parking slot in Firestore."""
    slot = SLOT_MAP[num]
    doc_id = slot["doc_id"]
    sensor_id = slot["sensor_id"]

    try:
        db.collection("parking_slots").document(doc_id).update({
            "status": status,
            "sensorId": sensor_id,
            "sensorStatus": "ACTIVE",
            "sensorLastUpdate": firestore.SERVER_TIMESTAMP,
            "lastUpdated": firestore.SERVER_TIMESTAMP,
        })
        slot_states[num] = status
        ts = datetime.now().strftime("%H:%M:%S")
        color = STATUS_COLORS.get(status, "")
        icon = STATUS_ICONS.get(status, "•")
        print(f"  {Fore.CYAN}[{ts}]{Style.RESET_ALL} {icon} {color}{doc_id}{Style.RESET_ALL} → {color}{status}{Style.RESET_ALL}")
        return True
    except Exception as e:
        print(f"  {Fore.RED}✗ Failed to update {doc_id}: {e}")
        return False

def reset_all():
    """Set all 9 slots to AVAILABLE."""
    print(f"\n{Fore.CYAN}Resetting all slots to AVAILABLE...")
    for num in SLOT_MAP:
        update_slot(num, "AVAILABLE")
    print()

# ─────────────────────────────────────────────────────────────
#  DISPLAY
# ─────────────────────────────────────────────────────────────

def print_header():
    print(f"\n{Fore.CYAN}{'═'*55}")
    print(f"  {Fore.WHITE}{Style.BRIGHT}SMART PARKING SYSTEM — Firebase Bridge")
    print(f"{Fore.CYAN}  Wokwi Visual Simulation ↔ Firebase Firestore")
    print(f"{'═'*55}{Style.RESET_ALL}")

def print_status():
    avail = sum(1 for s in slot_states.values() if s == "AVAILABLE")
    occ   = sum(1 for s in slot_states.values() if s == "OCCUPIED")
    maint = sum(1 for s in slot_states.values() if s == "MAINTENANCE")

    print(f"\n{Fore.WHITE}{Style.BRIGHT}─── LEVEL 1 PARKING STATUS ─────────────────────────{Style.RESET_ALL}")
    zones = [("Zone A", ["1","2","3"]), ("Zone B", ["4","5","6"]), ("Zone C", ["7","8","9"])]
    for zone_name, nums in zones:
        print(f"  {Fore.WHITE}{zone_name}:{Style.RESET_ALL}", end="  ")
        for num in nums:
            slot = SLOT_MAP[num]
            status = slot_states[num]
            color = STATUS_COLORS.get(status, "")
            icon = STATUS_ICONS.get(status, "•")
            print(f"[{num}]{color}{slot['label']}{Style.RESET_ALL}{icon}  ", end="")
        print()

    print(f"\n  {Fore.GREEN}Available: {avail}{Style.RESET_ALL}  "
          f"{Fore.RED}Occupied: {occ}{Style.RESET_ALL}  "
          f"{Fore.YELLOW}Maintenance: {maint}{Style.RESET_ALL}")
    print(f"{Fore.WHITE}{'─'*51}{Style.RESET_ALL}")

def print_help():
    print(f"\n{Fore.WHITE}{Style.BRIGHT}Commands:{Style.RESET_ALL}")
    print(f"  {Fore.CYAN}<num> o{Style.RESET_ALL}   → OCCUPIED    (e.g., {Fore.CYAN}1 o{Style.RESET_ALL})")
    print(f"  {Fore.CYAN}<num> a{Style.RESET_ALL}   → AVAILABLE   (e.g., {Fore.CYAN}3 a{Style.RESET_ALL})")
    print(f"  {Fore.CYAN}<num> m{Style.RESET_ALL}   → MAINTENANCE (e.g., {Fore.CYAN}7 m{Style.RESET_ALL})")
    print(f"  {Fore.CYAN}auto{Style.RESET_ALL}      → Start/stop auto demo mode")
    print(f"  {Fore.CYAN}reset{Style.RESET_ALL}     → Set all slots AVAILABLE")
    print(f"  {Fore.CYAN}status{Style.RESET_ALL}    → Show current state")
    print(f"  {Fore.CYAN}quit{Style.RESET_ALL}      → Exit\n")

# ─────────────────────────────────────────────────────────────
#  AUTO DEMO MODE
# ─────────────────────────────────────────────────────────────

def auto_demo_loop():
    """Randomly toggle slots to simulate sensor detections."""
    global auto_mode
    statuses = ["OCCUPIED", "AVAILABLE", "AVAILABLE"]  # Bias toward OCCUPIED/AVAILABLE
    print(f"\n{Fore.YELLOW}⚡ Auto demo mode started (Ctrl+C or type 'auto' to stop){Style.RESET_ALL}")
    while auto_mode:
        num = random.choice(list(SLOT_MAP.keys()))
        current = slot_states[num]
        # Don't touch MAINTENANCE slots in auto mode
        if current != "MAINTENANCE":
            new_status = random.choice(statuses)
            if new_status != current:
                update_slot(num, new_status, random.randint(5, 45))
        time.sleep(random.uniform(1.5, 4.0))
    print(f"\n{Fore.YELLOW}⚡ Auto demo mode stopped{Style.RESET_ALL}")

# ─────────────────────────────────────────────────────────────
#  COMMAND PARSER
# ─────────────────────────────────────────────────────────────

STATUS_CODES = {
    "o": "OCCUPIED",
    "occupied": "OCCUPIED",
    "a": "AVAILABLE",
    "available": "AVAILABLE",
    "m": "MAINTENANCE",
    "maintenance": "MAINTENANCE",
}

def handle_command(cmd: str) -> bool:
    """Parse and execute a command. Returns False to quit."""
    global auto_mode, auto_thread
    cmd = cmd.strip().lower()

    if not cmd:
        return True

    if cmd in ("quit", "exit", "q"):
        return False

    if cmd == "status":
        print_status()
        return True

    if cmd == "help":
        print_help()
        return True

    if cmd == "reset":
        reset_all()
        print_status()
        return True

    if cmd == "auto":
        if auto_mode:
            auto_mode = False
        else:
            auto_mode = True
            auto_thread = threading.Thread(target=auto_demo_loop, daemon=True)
            auto_thread.start()
        return True

    # Parse "<num> <status>"
    parts = cmd.split()
    if len(parts) == 2:
        num, status_code = parts[0], parts[1]
        if num in SLOT_MAP and status_code in STATUS_CODES:
            update_slot(num, STATUS_CODES[status_code])
            return True

    print(f"  {Fore.RED}Unknown command: '{cmd}'. Type 'help' for commands.{Style.RESET_ALL}")
    return True

# ─────────────────────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────────────────────

def main():
    print_header()
    init_firebase()
    print_status()
    print_help()

    print(f"{Fore.GREEN}Ready! Firestore → parking_slots collection is being updated live.")
    print(f"{Fore.WHITE}Mobile app and dashboard will reflect changes in real time.\n{Style.RESET_ALL}")

    try:
        while True:
            try:
                cmd = input(f"{Fore.CYAN}parking>{Style.RESET_ALL} ").strip()
                if not handle_command(cmd):
                    break
            except EOFError:
                break
    except KeyboardInterrupt:
        pass

    # Cleanup
    auto_mode = False
    print(f"\n{Fore.YELLOW}Shutting down bridge...{Style.RESET_ALL}")
    print(f"{Fore.GREEN}✓ Done. Firebase connection closed.{Style.RESET_ALL}\n")

if __name__ == "__main__":
    main()

import os
import time
import statistics
import requests
import RPi.GPIO as GPIO

# ── Config ────────────────────────────────────────────────────────────────────
API_BASE    = os.getenv("API_BASE",    "http://172.20.10.7:5000")
API_KEY     = os.getenv("PI_API_KEY",  "dev-pi-key-change-in-prod")
POLL_SECS   = float(os.getenv("POLL_SECS", "1.0"))
THRESHOLD   = float(os.getenv("THRESHOLD_CM", "15.0"))

# ── GPIO pins (BCM numbering) ─────────────────────────────────────────────────
TRIG_1, ECHO_1 = 23, 24   # Spot 1 — confirmed 2026-05-24
TRIG_2, ECHO_2 = 20, 21   # Spot 2 — corrected 2026-06-04 (was 18/25; sensor is physically on GPIO20/21)

LED_RED   = 17   # GPIO17, Pin 11 — occupied
LED_GREEN = 27   # GPIO27, Pin 13 — free

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
for pin in (TRIG_1, TRIG_2, LED_RED, LED_GREEN):
    GPIO.setup(pin, GPIO.OUT, initial=GPIO.LOW)
for pin in (ECHO_1, ECHO_2):
    GPIO.setup(pin, GPIO.IN)

# ── Sensor reading ────────────────────────────────────────────────────────────
ECHO_TIMEOUT = 0.04  # 40 ms ≈ 6.8 m — anything beyond this is noise

def measure_distance(trig: int, echo: int) -> float | None:
    """Return distance in cm, or None on timeout."""
    GPIO.output(trig, True)
    time.sleep(0.00001)
    GPIO.output(trig, False)

    deadline = time.time() + ECHO_TIMEOUT
    while GPIO.input(echo) == 0:
        if time.time() > deadline:
            return None
    pulse_start = time.time()

    deadline = time.time() + ECHO_TIMEOUT
    while GPIO.input(echo) == 1:
        if time.time() > deadline:
            return None
    pulse_end = time.time()

    return ((pulse_end - pulse_start) * 34300) / 2

def stable_read(trig: int, echo: int, samples: int = 3) -> float | None:
    """Median of `samples` readings; returns None if any sample times out."""
    readings = [measure_distance(trig, echo) for _ in range(samples)]
    valid = [r for r in readings if r is not None]
    return statistics.median(valid) if valid else None

# ── API call ──────────────────────────────────────────────────────────────────
def post_update(spot_id: int, occupied: bool, raw_cm: float | None) -> None:
    payload = {
        "spot_id":     spot_id,
        "status":      "occupied" if occupied else "available",
        "raw_cm":      raw_cm,
        "sensor_type": "ultrasonic",
        "pi_device_id": "pi-node-01",
    }
    try:
        r = requests.post(
            f"{API_BASE}/api/spots/update",
            json=payload,
            headers={"X-Api-Key": API_KEY},
            timeout=3,
        )
        print(f"  → spot {spot_id} {payload['status']} ({raw_cm:.1f} cm)  HTTP {r.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"  ! POST failed for spot {spot_id}: {e}")

# ── Main loop ─────────────────────────────────────────────────────────────────
def main():
    print(f"ParkSmart sensor polling — API: {API_BASE}, threshold: {THRESHOLD} cm")
    prev = {1: None, 2: None}  # last known state per spot

    sensors = [
        (1, TRIG_1, ECHO_1),
        (2, TRIG_2, ECHO_2),
    ]

    try:
        while True:
            for spot_id, trig, echo in sensors:
                cm = stable_read(trig, echo)
                if cm is None:
                    print(f"  ? spot {spot_id} timeout — skipping")
                    continue

                occupied = cm < THRESHOLD

                # Update LED for Spot 1 only (one set of LEDs)
                if spot_id == 1:
                    GPIO.output(LED_RED,   GPIO.HIGH if occupied else GPIO.LOW)
                    GPIO.output(LED_GREEN, GPIO.LOW  if occupied else GPIO.HIGH)

                # Only POST on state change
                if occupied != prev[spot_id]:
                    post_update(spot_id, occupied, cm)
                    prev[spot_id] = occupied

            time.sleep(POLL_SECS)

    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        GPIO.cleanup()

if __name__ == "__main__":
    main()

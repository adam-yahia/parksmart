import RPi.GPIO as GPIO
import time

# ── Pins (BCM numbering) ──────────────────────────────────────────────────────
TRIG_1, ECHO_1 = 23, 24   # Spot 1 — confirmed 2026-05-24
TRIG_2, ECHO_2 = 20, 21   # Spot 2 — confirmed 2026-06-04
THRESHOLD_CM = 20.0       # < threshold = OCCUPIED

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
for trig in (TRIG_1, TRIG_2):
    GPIO.setup(trig, GPIO.OUT, initial=GPIO.LOW)
for echo in (ECHO_1, ECHO_2):
    GPIO.setup(echo, GPIO.IN)
time.sleep(0.3)


def measure(trig, echo):
    """Distance in cm, or None on timeout."""
    GPIO.output(trig, True)
    time.sleep(0.00001)
    GPIO.output(trig, False)

    deadline = time.time() + 0.05
    while GPIO.input(echo) == 0:
        if time.time() > deadline:
            return None
    start = time.time()

    deadline = time.time() + 0.05
    while GPIO.input(echo) == 1:
        if time.time() > deadline:
            return None
    end = time.time()
    return ((end - start) * 34300) / 2


def fmt(cm):
    if cm is None:
        return "  timeout  "
    state = "OCCUPIED" if cm < THRESHOLD_CM else "free    "
    return f"{cm:5.1f} cm {state}"


print("ParkSmart — both sensors live. Wave a hand over each. Ctrl+C to stop.")
print("-" * 48)
try:
    while True:
        d1 = measure(TRIG_1, ECHO_1)
        time.sleep(0.06)                 # let the first echo settle before pinging the second
        d2 = measure(TRIG_2, ECHO_2)
        print(f"Spot 1: {fmt(d1)}   |   Spot 2: {fmt(d2)}")
        time.sleep(0.4)
except KeyboardInterrupt:
    print("\nStopped.")
finally:
    GPIO.cleanup()

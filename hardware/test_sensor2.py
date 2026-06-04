import RPi.GPIO as GPIO
import time

# Sensor 2 — GPIO20 TRIG, GPIO21 ECHO (via voltage divider)
# If every reading times out, swap these two values: TRIG, ECHO = 21, 20
TRIG, ECHO = 20, 21

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(TRIG, GPIO.OUT, initial=GPIO.LOW)
GPIO.setup(ECHO, GPIO.IN)
time.sleep(0.3)

print(f"Testing Sensor 2 (GPIO{TRIG} TRIG, GPIO{ECHO} ECHO) — Ctrl+C to stop")


def measure():
    GPIO.output(TRIG, True)
    time.sleep(0.00001)
    GPIO.output(TRIG, False)

    deadline = time.time() + 0.05
    while GPIO.input(ECHO) == 0:
        if time.time() > deadline:
            return None  # ECHO never went HIGH — check TRIG wiring
    start = time.time()

    deadline = time.time() + 0.05
    while GPIO.input(ECHO) == 1:
        if time.time() > deadline:
            return None  # ECHO stuck HIGH — check voltage divider
    end = time.time()
    return ((end - start) * 34300) / 2


try:
    while True:
        d = measure()
        if d is None:
            print("timeout — no echo")
        else:
            print(f"{d:5.1f} cm  ->  {'OCCUPIED' if d < 20 else 'free'}")
        time.sleep(0.5)
except KeyboardInterrupt:
    print("\nStopped.")
finally:
    GPIO.cleanup()

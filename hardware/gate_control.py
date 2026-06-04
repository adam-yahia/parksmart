"""Gate controller — IR tracker opens the servo gate when a car is detected.

Wiring (BCM numbering):
  IR tracker  VCC -> 3.3V (Pin 1 or 17)   keeps OUT at a Pi-safe 3.3V
  IR tracker  GND -> GND
  IR tracker  OUT -> GPIO25 (Pin 22)
  Servo       signal(orange) -> GPIO19 (Pin 35)
  Servo       V+(red)        -> 5V   (see power warning in chat)
  Servo       GND(brown)     -> GND  (MUST share ground with the Pi)

Open is slow and graceful; close is fast. The loop is non-blocking, so a car
arriving at any moment (even mid-close) is reacted to immediately.
Runs independently of the parking sensors — does NOT touch sensor_polling.py.
"""
import time
import RPi.GPIO as GPIO

IR = 25      # GPIO25, Pin 22 — IR tracker OUT
SERVO = 19   # GPIO19, Pin 35 — servo signal

# These IR modules usually read LOW (0) when something is in front of them.
# If the gate behaves backwards, change this to GPIO.HIGH.
CAR_DETECTED = GPIO.LOW

CLOSED_ANGLE = 20
OPEN_ANGLE = 120
OPEN_HOLD = 3.0   # seconds the gate waits, after the car clears, before closing

# Movement speed = per-degree delay during the sweep. SMALLER = faster.
STEP_OPEN = 0.02    # slow open  (~2s over 100 deg)
STEP_CLOSE = 0.003  # fast close (~0.3s over 100 deg)

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(IR, GPIO.IN)
GPIO.setup(SERVO, GPIO.OUT)

pwm = GPIO.PWM(SERVO, 50)
pwm.start(0)

current_angle = CLOSED_ANGLE


def _duty(a):
    return 2.5 + (a / 180.0) * 10.0


def car_present():
    return GPIO.input(IR) == CAR_DETECTED


def sweep_to(target, step_delay, abort_on_car=False):
    """Move one degree at a time so motion is smooth and speed is controllable.
    If abort_on_car is set, stop early when a car appears (so a slow close can
    be interrupted and re-opened). Returns True if it reached the target."""
    global current_angle
    step = 1 if target >= current_angle else -1
    for a in range(current_angle, target + step, step):
        if abort_on_car and car_present():
            current_angle = a
            pwm.ChangeDutyCycle(0)
            return False
        pwm.ChangeDutyCycle(_duty(a))
        time.sleep(step_delay)
    pwm.ChangeDutyCycle(0)  # cut signal so it doesn't buzz at rest
    current_angle = target
    return True


# start closed
sweep_to(CLOSED_ANGLE, STEP_OPEN)
gate_open = False
clear_since = None   # timestamp the car cleared; None while a car is present

print("Gate ready (closed). Watching IR on GPIO25… Ctrl+C to stop.")

try:
    while True:
        if car_present():
            clear_since = None
            if not gate_open:
                print("car detected -> opening (slow)")
                sweep_to(OPEN_ANGLE, STEP_OPEN)
                gate_open = True
        elif gate_open:
            if clear_since is None:
                clear_since = time.time()
            elif time.time() - clear_since >= OPEN_HOLD:
                print("closing (fast)")
                reached = sweep_to(CLOSED_ANGLE, STEP_CLOSE, abort_on_car=True)
                if reached:
                    gate_open = False
                    clear_since = None
                    print("gate closed")
                else:
                    print("car returned -> reopening")
                    sweep_to(OPEN_ANGLE, STEP_OPEN)
                    clear_since = None
        time.sleep(0.05)
except KeyboardInterrupt:
    print("\nStopped.")
finally:
    pwm.stop()
    GPIO.cleanup()

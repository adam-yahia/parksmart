"""Servo calibration sweep — confirm wiring/power and find your open/closed angles.

SG90 micro-servo on GPIO18 (Pin 12). Run this FIRST, before gate_control.py.
Watch the arm: it should swing closed (0) <-> open (90) once per second.
If the Pi reboots or you see a lightning-bolt (undervoltage) icon, that's the
power problem — see the notes in chat. Ctrl+C to stop.
"""
import RPi.GPIO as GPIO
import time

SERVO = 19  # GPIO19, Pin 35

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(SERVO, GPIO.OUT)

pwm = GPIO.PWM(SERVO, 50)  # 50 Hz = standard servo frame (20 ms)
pwm.start(0)


def set_angle(a):
    # SG90 maps roughly: 0deg ~ 2.5% duty, 180deg ~ 12.5% duty.
    # Tune these two numbers if your arm under/over-shoots.
    duty = 2.5 + (a / 180.0) * 10.0
    pwm.ChangeDutyCycle(duty)
    time.sleep(0.4)
    pwm.ChangeDutyCycle(0)  # cut the signal to stop buzzing/jitter


try:
    while True:
        print("closed (20 deg)")
        set_angle(20)
        time.sleep(1)
        print("open (120 deg)")
        set_angle(120)
        time.sleep(1)
except KeyboardInterrupt:
    print("\nStopped.")
finally:
    pwm.stop()
    GPIO.cleanup()

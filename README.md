# ParkSmart

Smart parking detection system — Final Year Project, Ruppin Technological College.

## Structure

| Folder | Contents |
|---|---|
| `backend/` | Flask REST API + SQLite — runs on Raspberry Pi |
| `app/` | Flutter mobile app |
| `hardware/` | Python sensor scripts (HC-SR04 on Pi GPIO) |

## Stack

- **Sensing:** HC-SR04 ultrasonic sensors + Raspberry Pi Zero W
- **Backend:** Python 3 + Flask + SQLite (SQLAlchemy ORM)
- **Mobile:** Flutter (Dart), Provider state management
- **Comms:** HTTP REST over phone hotspot

## Quick Start (backend)

```bash
cd backend
pip install -r requirements.txt
py run.py
```

API runs at `http://localhost:5000/api`

from app import db
from datetime import datetime, timezone

def _now():
    return datetime.now(timezone.utc)

class ParkingSpot(db.Model):
    __tablename__ = 'parking_spots'
    spot_id      = db.Column(db.Integer, primary_key=True)
    status       = db.Column(db.String(20), nullable=False, default='available')
    last_updated = db.Column(db.DateTime, default=_now, onupdate=_now)
    logs         = db.relationship('SensorLog', backref='spot', lazy=True)

    def to_dict(self):
        return {
            'spot_id':      self.spot_id,
            'status':       self.status,
            'last_updated': self.last_updated.isoformat() if self.last_updated else None,
        }

class User(db.Model):
    __tablename__ = 'users'
    user_id       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    username      = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)

class SensorLog(db.Model):
    __tablename__ = 'sensor_log'
    log_id       = db.Column(db.Integer, primary_key=True, autoincrement=True)
    spot_id      = db.Column(db.Integer, db.ForeignKey('parking_spots.spot_id'), nullable=False)
    raw_cm       = db.Column(db.Float)
    status       = db.Column(db.String(20), nullable=False)
    sensor_type  = db.Column(db.String(20), default='ultrasonic')
    pi_device_id = db.Column(db.String(50))
    timestamp    = db.Column(db.DateTime, default=_now)

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from config import Config

db = SQLAlchemy()

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)

    from app.routes.spots import spots_bp
    from app.routes.auth import auth_bp

    app.register_blueprint(spots_bp, url_prefix='/api')
    app.register_blueprint(auth_bp, url_prefix='/api/auth')

    with app.app_context():
        db.create_all()
        _seed_spots()

    return app

def _seed_spots():
    from app.models import ParkingSpot
    if ParkingSpot.query.count() == 0:
        db.session.add_all([
            ParkingSpot(spot_id=1, status='available'),
            ParkingSpot(spot_id=2, status='available'),
        ])
        db.session.commit()

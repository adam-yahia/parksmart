from flask import Blueprint, request, jsonify
from app import db
from app.models import ParkingSpot, SensorLog
from app.utils.auth import require_api_key
from datetime import datetime, timezone

spots_bp = Blueprint('spots', __name__)

@spots_bp.route('/spots', methods=['GET'])
def get_spots():
    spots = ParkingSpot.query.all()
    return jsonify([s.to_dict() for s in spots])

@spots_bp.route('/spots/<int:spot_id>', methods=['GET'])
def get_spot(spot_id):
    spot = db.get_or_404(ParkingSpot, spot_id)
    return jsonify(spot.to_dict())

@spots_bp.route('/spots/update', methods=['POST'])
@require_api_key
def update_spot():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'JSON body required'}), 400

    spot_id = data.get('spot_id')
    status  = data.get('status')

    if spot_id is None or status not in ('occupied', 'available'):
        return jsonify({'error': 'spot_id and valid status (occupied|available) required'}), 400

    spot = db.session.get(ParkingSpot, spot_id)
    if not spot:
        return jsonify({'error': 'Spot not found', 'code': 404}), 404

    spot.status       = status
    spot.last_updated = datetime.now(timezone.utc)

    db.session.add(SensorLog(
        spot_id      = spot_id,
        raw_cm       = data.get('raw_cm'),
        status       = status,
        sensor_type  = data.get('sensor_type', 'ultrasonic'),
        pi_device_id = data.get('pi_device_id'),
    ))
    db.session.commit()

    return jsonify({'message': 'updated', 'spot_id': spot_id})

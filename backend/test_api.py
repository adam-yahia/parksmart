import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from app import create_app, db
from config import TestConfig
import json

VALID_KEY = 'dev-pi-key-change-in-prod'
INVALID_KEY = 'wrong-key'

def make_client():
    app = create_app(TestConfig)
    return app.test_client(), app

passed = 0
failed = 0

def check(name, condition, detail=''):
    global passed, failed
    if condition:
        print(f'  PASS  {name}')
        passed += 1
    else:
        print(f'  FAIL  {name}  {detail}')
        failed += 1

print('\n=== ParkSmart API Tests ===\n')

# ── Spots ──────────────────────────────────────────────────────────────────────
print('[ GET /api/spots ]')
client, app = make_client()
with app.app_context():
    r = client.get('/api/spots')
    data = r.get_json()
    check('returns 200',       r.status_code == 200)
    check('returns 2 spots',   len(data) == 2)
    check('both available',    all(s['status'] == 'available' for s in data))
    check('has last_updated',  all('last_updated' in s for s in data))

print()
print('[ GET /api/spots/1 ]')
with app.app_context():
    r = client.get('/api/spots/1')
    data = r.get_json()
    check('returns 200',     r.status_code == 200)
    check('correct spot_id', data['spot_id'] == 1)

print()
print('[ GET /api/spots/99 — not found ]')
with app.app_context():
    r = client.get('/api/spots/99')
    check('returns 404', r.status_code == 404)

print()
print('[ POST /api/spots/update — valid key ]')
client2, app2 = make_client()
with app2.app_context():
    r = client2.post('/api/spots/update',
        json={'spot_id': 1, 'status': 'occupied', 'raw_cm': 8.3,
              'sensor_type': 'ultrasonic', 'pi_device_id': 'pi-node-01'},
        headers={'X-API-Key': VALID_KEY})
    data = r.get_json()
    check('returns 200',          r.status_code == 200)
    check('message = updated',    data.get('message') == 'updated')
    check('spot_id echoed back',  data.get('spot_id') == 1)

    # Confirm the change persisted
    r2 = client2.get('/api/spots/1')
    check('spot 1 now occupied',  r2.get_json()['status'] == 'occupied')

print()
print('[ POST /api/spots/update — invalid API key ]')
client3, app3 = make_client()
with app3.app_context():
    r = client3.post('/api/spots/update',
        json={'spot_id': 1, 'status': 'occupied'},
        headers={'X-API-Key': INVALID_KEY})
    check('returns 401', r.status_code == 401)

print()
print('[ POST /api/spots/update — missing API key ]')
client4, app4 = make_client()
with app4.app_context():
    r = client4.post('/api/spots/update',
        json={'spot_id': 1, 'status': 'occupied'})
    check('returns 401', r.status_code == 401)

print()
print('[ POST /api/spots/update — bad status value ]')
client5, app5 = make_client()
with app5.app_context():
    r = client5.post('/api/spots/update',
        json={'spot_id': 1, 'status': 'banana'},
        headers={'X-API-Key': VALID_KEY})
    check('returns 400', r.status_code == 400)

print()
print('[ POST /api/auth/register + login ]')
client6, app6 = make_client()
with app6.app_context():
    r = client6.post('/api/auth/register',
        json={'username': 'adam', 'password': 'testpass123'})
    data = r.get_json()
    check('register returns 201',     r.status_code == 201)
    check('register returns token',   'access_token' in data)

    r2 = client6.post('/api/auth/login',
        json={'username': 'adam', 'password': 'testpass123'})
    data2 = r2.get_json()
    check('login returns 200',        r2.status_code == 200)
    check('login returns token',      'access_token' in data2)

    r3 = client6.post('/api/auth/login',
        json={'username': 'adam', 'password': 'wrongpassword'})
    check('wrong password returns 401', r3.status_code == 401)

    r4 = client6.post('/api/auth/register',
        json={'username': 'adam', 'password': 'testpass123'})
    check('duplicate username returns 409', r4.status_code == 409)

print()
print(f'=== Results: {passed} passed, {failed} failed ===\n')
sys.exit(0 if failed == 0 else 1)

import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-change-in-prod')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///parksmart.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    PI_API_KEY = os.environ.get('PI_API_KEY', 'dev-pi-key-change-in-prod')

class TestConfig(Config):
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

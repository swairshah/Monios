import os
from functools import lru_cache
from dataclasses import dataclass

# Load .env file for local development
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # dotenv not needed in production


@dataclass
class Settings:
    google_client_id: str
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 7
    host: str = "0.0.0.0"
    port: int = 8000


@lru_cache
def get_settings() -> Settings:
    return Settings(
        google_client_id=os.environ.get("GOOGLE_CLIENT_ID", ""),
        jwt_secret_key=os.environ.get("JWT_SECRET_KEY", "dev-secret-key"),
        jwt_algorithm=os.environ.get("JWT_ALGORITHM", "HS256"),
        jwt_access_token_expire_minutes=int(os.environ.get("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "30")),
        jwt_refresh_token_expire_days=int(os.environ.get("JWT_REFRESH_TOKEN_EXPIRE_DAYS", "7")),
        host=os.environ.get("HOST", "0.0.0.0"),
        port=int(os.environ.get("PORT", "8000")),
    )

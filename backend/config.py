from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Google OAuth
    google_client_id: str

    # JWT
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 7

    # Server
    host: str = "0.0.0.0"
    port: int = 8000

    class Config:
        env_file = ".env"  # Only used for local development
        env_file_encoding = "utf-8"
        extra = "ignore"  # Ignore extra env vars (Modal sets many)


@lru_cache
def get_settings() -> Settings:
    return Settings()

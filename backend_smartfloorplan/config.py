import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class Config:
    SUPABASE_URL: str = os.environ["SUPABASE_URL"]
    SUPABASE_KEY: str = os.environ["SUPABASE_KEY"]
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "smartfloorplan-secret-key")
    JWT_ACCESS_TOKEN_EXPIRES: timedelta = timedelta(hours=24)
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
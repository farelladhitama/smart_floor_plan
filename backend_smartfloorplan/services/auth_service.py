from werkzeug.security import generate_password_hash, check_password_hash
from supabase_client import get_supabase


def register_user(name: str, email: str, password: str) -> dict:
    sb = get_supabase()

    existing = sb.table("users").select("id").eq("email", email).execute()
    if existing.data:
        return {"error": "EMAIL_EXISTS"}

    hashed = generate_password_hash(password)

    result = sb.table("users").insert({
        "name": name,
        "email": email,
        "password": hashed
    }).execute()

    user = result.data[0]
    return {"user": user}


def login_user(email: str, password: str) -> dict:
    sb = get_supabase()

    result = sb.table("users").select("*").eq("email", email).execute()

    if not result.data:
        return {"error": "EMAIL_NOT_FOUND"}

    user = result.data[0]

    if not check_password_hash(user["password"], password):
        return {"error": "WRONG_PASSWORD"}

    return {"user": user}


def get_user_by_id(user_id: str) -> dict | None:
    sb = get_supabase()
    result = sb.table("users").select("id, name, email, created_at").eq("id", user_id).execute()
    if not result.data:
        return None
    return result.data[0]
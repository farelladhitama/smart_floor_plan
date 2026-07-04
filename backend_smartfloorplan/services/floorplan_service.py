from supabase_client import get_supabase


def create_floorplan(user_id: str, title: str, land_width, land_length, material: str, rooms: list) -> dict:
    sb = get_supabase()

    fp_result = sb.table("floorplans").insert({
        "user_id": user_id,
        "title": title,
        "land_width": land_width,
        "land_length": land_length,
        "material": material
    }).execute()

    floorplan = fp_result.data[0]
    floorplan_id = floorplan["id"]

    rooms_payload = []
    for room in rooms:
        rooms_payload.append({
            "floorplan_id": floorplan_id,
            "name": room["name"],
            "x": room["x"],
            "y": room["y"],
            "width": room["width"],
            "height": room["height"]
        })

    sb.table("rooms").insert(rooms_payload).execute()

    return {
        "id": floorplan_id,
        "title": title,
        "land_width": land_width,
        "land_length": land_length,
        "material": material,
        "rooms_count": len(rooms)
    }


def get_floorplans(user_id: str) -> list:
    sb = get_supabase()

    fp_result = sb.table("floorplans").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
    floorplans = fp_result.data

    result = []
    for fp in floorplans:
        rooms_count_result = sb.table("rooms").select("id", count="exact").eq("floorplan_id", fp["id"]).execute()
        result.append({
            "id": fp["id"],
            "title": fp["title"],
            "land_width": fp["land_width"],
            "land_length": fp["land_length"],
            "material": fp["material"],
            "rooms_count": rooms_count_result.count or 0,
            "created_at": fp["created_at"],
            "updated_at": fp["updated_at"]
        })

    return result


def get_floorplan_detail(floorplan_id: int, user_id: str) -> dict | None:
    sb = get_supabase()

    fp_result = sb.table("floorplans").select("*").eq("id", floorplan_id).eq("user_id", user_id).execute()
    if not fp_result.data:
        return None

    fp = fp_result.data[0]

    rooms_result = sb.table("rooms").select("id, name, x, y, width, height").eq("floorplan_id", floorplan_id).order("id").execute()

    return {
        "id": fp["id"],
        "title": fp["title"],
        "land_width": fp["land_width"],
        "land_length": fp["land_length"],
        "material": fp["material"],
        "created_at": fp["created_at"],
        "updated_at": fp["updated_at"],
        "rooms": rooms_result.data or []
    }


def update_floorplan(floorplan_id: int, user_id: str, title: str, land_width, land_length, material: str, rooms: list) -> dict | None:
    sb = get_supabase()

    existing = sb.table("floorplans").select("id").eq("id", floorplan_id).eq("user_id", user_id).execute()
    if not existing.data:
        return None

    sb.table("floorplans").update({
        "title": title,
        "land_width": land_width,
        "land_length": land_length,
        "material": material
    }).eq("id", floorplan_id).eq("user_id", user_id).execute()

    sb.table("rooms").delete().eq("floorplan_id", floorplan_id).execute()

    rooms_payload = []
    for room in rooms:
        rooms_payload.append({
            "floorplan_id": floorplan_id,
            "name": room["name"],
            "x": room["x"],
            "y": room["y"],
            "width": room["width"],
            "height": room["height"]
        })

    sb.table("rooms").insert(rooms_payload).execute()

    return {
        "id": floorplan_id,
        "title": title,
        "land_width": land_width,
        "land_length": land_length,
        "material": material,
        "rooms_count": len(rooms)
    }


def delete_floorplan(floorplan_id: int, user_id: str) -> bool:
    sb = get_supabase()

    existing = sb.table("floorplans").select("id").eq("id", floorplan_id).eq("user_id", user_id).execute()
    if not existing.data:
        return False

    sb.table("rabs").delete().eq("floorplan_id", floorplan_id).execute()
    sb.table("rooms").delete().eq("floorplan_id", floorplan_id).execute()
    sb.table("floorplans").delete().eq("id", floorplan_id).eq("user_id", user_id).execute()

    return True
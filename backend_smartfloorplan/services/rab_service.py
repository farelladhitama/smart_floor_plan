from supabase_client import get_supabase

SKALA = 20.0
HARGA_PER_METER = 3500000


def create_rab(floorplan_id: int, user_id: str) -> dict | str:
    sb = get_supabase()

    fp_result = sb.table("floorplans").select("id").eq("id", floorplan_id).eq("user_id", user_id).execute()
    if not fp_result.data:
        return "FLOORPLAN_NOT_FOUND"

    rooms_result = sb.table("rooms").select("width, height").eq("floorplan_id", floorplan_id).execute()
    rooms = rooms_result.data

    if not rooms:
        return "NO_ROOMS"

    total_area = sum((r["width"] / SKALA) * (r["height"] / SKALA) for r in rooms)
    total_price = total_area * HARGA_PER_METER

    foundation_cost = total_price * 0.25
    wall_cost = total_price * 0.20
    roof_cost = total_price * 0.15
    floor_cost = total_price * 0.15
    finishing_cost = total_price * 0.25

    sb.table("rabs").delete().eq("floorplan_id", floorplan_id).execute()

    rab_result = sb.table("rabs").insert({
        "floorplan_id": floorplan_id,
        "total_area": round(total_area, 2),
        "total_price": round(total_price, 2),
        "foundation_cost": round(foundation_cost, 2),
        "wall_cost": round(wall_cost, 2),
        "roof_cost": round(roof_cost, 2),
        "floor_cost": round(floor_cost, 2),
        "finishing_cost": round(finishing_cost, 2)
    }).execute()

    rab = rab_result.data[0]
    return rab


def get_rab(floorplan_id: int, user_id: str) -> dict | str:
    sb = get_supabase()

    fp_result = sb.table("floorplans").select("id").eq("id", floorplan_id).eq("user_id", user_id).execute()
    if not fp_result.data:
        return "FLOORPLAN_NOT_FOUND"

    rab_result = sb.table("rabs").select("*").eq("floorplan_id", floorplan_id).execute()
    if not rab_result.data:
        return "RAB_NOT_FOUND"

    return rab_result.data[0]
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.rab_service import create_rab, get_rab

rab_bp = Blueprint("rab", __name__, url_prefix="/api")


@rab_bp.route("/rab", methods=["POST"])
@jwt_required()
def create():
    try:
        user_id = get_jwt_identity()
        data = request.get_json(silent=True)

        if not data:
            return jsonify({"message": "Body request harus berupa JSON", "status": "error"}), 400

        floorplan_id = data.get("floorplan_id")
        if floorplan_id is None:
            return jsonify({"message": "floorplan_id wajib diisi", "status": "error"}), 400

        result = create_rab(floorplan_id, user_id)

        if result == "FLOORPLAN_NOT_FOUND":
            return jsonify({"message": "Denah tidak ditemukan atau bukan milik user ini", "status": "error"}), 404
        if result == "NO_ROOMS":
            return jsonify({"message": "Denah belum memiliki ruangan", "status": "error"}), 400

        return jsonify({"message": "RAB berhasil dibuat dan disimpan", "status": "success", "data": result}), 201

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat membuat RAB", "status": "error", "error": str(e)}), 500


@rab_bp.route("/rab/<int:floorplan_id>", methods=["GET"])
@jwt_required()
def get(floorplan_id):
    try:
        user_id = get_jwt_identity()
        result = get_rab(floorplan_id, user_id)

        if result == "FLOORPLAN_NOT_FOUND":
            return jsonify({"message": "Denah tidak ditemukan atau bukan milik user ini", "status": "error"}), 404
        if result == "RAB_NOT_FOUND":
            return jsonify({"message": "RAB belum dibuat untuk denah ini", "status": "error"}), 404

        return jsonify({
            "message": "Data RAB berhasil diambil",
            "status": "success",
            "data": {
                "id": result["id"],
                "floorplan_id": result["floorplan_id"],
                "total_area": result["total_area"],
                "total_price": result["total_price"],
                "foundation_cost": result["foundation_cost"],
                "wall_cost": result["wall_cost"],
                "roof_cost": result["roof_cost"],
                "floor_cost": result["floor_cost"],
                "finishing_cost": result["finishing_cost"],
                "created_at": result["created_at"]
            }
        }), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat mengambil RAB", "status": "error", "error": str(e)}), 500
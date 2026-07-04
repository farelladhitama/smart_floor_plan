from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from services.floorplan_service import (
    create_floorplan,
    get_floorplans,
    get_floorplan_detail,
    update_floorplan,
    delete_floorplan,
)

floorplan_bp = Blueprint("floorplans", __name__, url_prefix="/api")


@floorplan_bp.route("/floorplans", methods=["POST"])
@jwt_required()
def create():
    try:
        user_id = get_jwt_identity()
        data = request.get_json(silent=True)

        if not data:
            return jsonify({"message": "Body request harus berupa JSON", "status": "error"}), 400

        title = data.get("title")
        land_width = data.get("land_width")
        land_length = data.get("land_length")
        material = data.get("material")
        rooms = data.get("rooms", [])

        if not title or land_width is None or land_length is None or not material:
            return jsonify({"message": "title, land_width, land_length, dan material wajib diisi", "status": "error"}), 400

        if not isinstance(rooms, list) or len(rooms) == 0:
            return jsonify({"message": "rooms wajib berupa list dan minimal berisi 1 ruangan", "status": "error"}), 400

        for room in rooms:
            if any(room.get(k) is None for k in ["name", "x", "y", "width", "height"]):
                return jsonify({"message": "Setiap room wajib memiliki name, x, y, width, dan height", "status": "error"}), 400

        result = create_floorplan(user_id, title, land_width, land_length, material, rooms)

        return jsonify({"message": "Denah berhasil disimpan", "status": "success", "data": result}), 201

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat menyimpan denah", "status": "error", "error": str(e)}), 500


@floorplan_bp.route("/floorplans", methods=["GET"])
@jwt_required()
def get_all():
    try:
        user_id = get_jwt_identity()
        result = get_floorplans(user_id)
        return jsonify({"message": "Data denah berhasil diambil", "status": "success", "data": result}), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat mengambil data denah", "status": "error", "error": str(e)}), 500


@floorplan_bp.route("/floorplans/<int:floorplan_id>", methods=["GET"])
@jwt_required()
def get_detail(floorplan_id):
    try:
        user_id = get_jwt_identity()
        result = get_floorplan_detail(floorplan_id, user_id)

        if result is None:
            return jsonify({"message": "Denah tidak ditemukan", "status": "error"}), 404

        return jsonify({"message": "Detail denah berhasil diambil", "status": "success", "data": result}), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat mengambil detail denah", "status": "error", "error": str(e)}), 500


@floorplan_bp.route("/floorplans/<int:floorplan_id>", methods=["PUT"])
@jwt_required()
def update(floorplan_id):
    try:
        user_id = get_jwt_identity()
        data = request.get_json(silent=True)

        if not data:
            return jsonify({"message": "Body request harus berupa JSON", "status": "error"}), 400

        title = data.get("title")
        land_width = data.get("land_width")
        land_length = data.get("land_length")
        material = data.get("material")
        rooms = data.get("rooms", [])

        if not title or land_width is None or land_length is None or not material:
            return jsonify({"message": "title, land_width, land_length, dan material wajib diisi", "status": "error"}), 400

        if not isinstance(rooms, list) or len(rooms) == 0:
            return jsonify({"message": "rooms wajib berupa list dan minimal berisi 1 ruangan", "status": "error"}), 400

        for room in rooms:
            if any(room.get(k) is None for k in ["name", "x", "y", "width", "height"]):
                return jsonify({"message": "Setiap room wajib memiliki name, x, y, width, dan height", "status": "error"}), 400

        result = update_floorplan(floorplan_id, user_id, title, land_width, land_length, material, rooms)

        if result is None:
            return jsonify({"message": "Denah tidak ditemukan", "status": "error"}), 404

        return jsonify({"message": "Denah berhasil diperbarui", "status": "success", "data": result}), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat memperbarui denah", "status": "error", "error": str(e)}), 500


@floorplan_bp.route("/floorplans/<int:floorplan_id>", methods=["DELETE"])
@jwt_required()
def delete(floorplan_id):
    try:
        user_id = get_jwt_identity()
        success = delete_floorplan(floorplan_id, user_id)

        if not success:
            return jsonify({"message": "Denah tidak ditemukan", "status": "error"}), 404

        return jsonify({"message": "Denah berhasil dihapus", "status": "success"}), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat menghapus denah", "status": "error", "error": str(e)}), 500
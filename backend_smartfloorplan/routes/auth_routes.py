from flask import Blueprint, jsonify, request
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from services.auth_service import register_user, login_user, get_user_by_id

auth_bp = Blueprint("auth", __name__, url_prefix="/api")


@auth_bp.route("/register", methods=["POST"])
def register():
    try:
        data = request.get_json(silent=True)
        if not data:
            return jsonify({"message": "Body request harus berupa JSON dan tidak boleh kosong", "status": "error"}), 400

        name = data.get("name")
        email = data.get("email")
        password = data.get("password")

        if not name or not email or not password:
            return jsonify({"message": "Name, email, dan password wajib diisi", "status": "error"}), 400
        if len(password) < 6:
            return jsonify({"message": "Password minimal 6 karakter", "status": "error"}), 400

        result = register_user(name, email, password)

        if "error" in result:
            if result["error"] == "EMAIL_EXISTS":
                return jsonify({"message": "Email sudah terdaftar", "status": "error"}), 409

        user = result["user"]
        return jsonify({
            "message": "Register berhasil",
            "status": "success",
            "data": {"id": user["id"], "name": user["name"], "email": user["email"]}
        }), 201

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat register", "status": "error", "error": str(e)}), 500


@auth_bp.route("/login", methods=["POST"])
def login():
    try:
        data = request.get_json(silent=True)
        if not data:
            return jsonify({"message": "Body request harus berupa JSON dan tidak boleh kosong", "status": "error"}), 400

        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({"message": "Email dan password wajib diisi", "status": "error"}), 400

        result = login_user(email, password)

        if "error" in result:
            if result["error"] == "EMAIL_NOT_FOUND":
                return jsonify({"message": "Email tidak ditemukan", "status": "error"}), 404
            if result["error"] == "WRONG_PASSWORD":
                return jsonify({"message": "Password salah", "status": "error"}), 401

        user = result["user"]
        access_token = create_access_token(identity=str(user["id"]))

        return jsonify({
            "message": "Login berhasil",
            "status": "success",
            "token": access_token,
            "data": {"id": user["id"], "name": user["name"], "email": user["email"]}
        }), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat login", "status": "error", "error": str(e)}), 500


@auth_bp.route("/profile", methods=["GET"])
@jwt_required()
def profile():
    try:
        user_id = get_jwt_identity()
        user = get_user_by_id(user_id)

        if user is None:
            return jsonify({"message": "User tidak ditemukan", "status": "error"}), 404

        return jsonify({
            "message": "Data profile berhasil diambil",
            "status": "success",
            "data": {"id": user["id"], "name": user["name"], "email": user["email"], "created_at": user["created_at"]}
        }), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat mengambil profile", "status": "error", "error": str(e)}), 500
from flask import Blueprint, jsonify, request
from utils.cv_utils import scan_floorplan_image

cv_bp = Blueprint("cv", __name__, url_prefix="/api/cv")


@cv_bp.route("/scan-denah", methods=["POST", "OPTIONS"])
def scan_denah():
    try:
        if request.method == "OPTIONS":
            return jsonify({"message": "Preflight OK", "status": "success"}), 200

        if "image" not in request.files:
            return jsonify({"message": "File image wajib dikirim", "status": "error"}), 400

        file = request.files["image"]
        file_bytes = file.read()

        result = scan_floorplan_image(file_bytes)

        if result == "INVALID_IMAGE":
            return jsonify({"message": "File gambar tidak valid", "status": "error"}), 400
        if result == "NO_LINES_DETECTED":
            return jsonify({
                "message": "Garis denah tidak terdeteksi. Gunakan gambar dengan garis hitam jelas.",
                "status": "error"
            }), 400

        return jsonify({
            "message": "Scan sketsa denah berhasil diproses dengan OpenCV Advanced",
            "status": "success",
            "data": result
        }), 200

    except Exception as e:
        return jsonify({"message": "Terjadi kesalahan saat memproses gambar denah", "status": "error", "error": str(e)}), 500
from flask import Blueprint, jsonify, request
from utils.cv_utils import scan_floorplan_image
import os
import traceback

cv_bp = Blueprint("cv", __name__, url_prefix="/api/cv")

MAX_FILE_SIZE = 10 * 1024 * 1024
ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "webp", "bmp"}


def _allowed_file(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS


@cv_bp.route("/scan-denah", methods=["POST", "OPTIONS"])
def scan_denah():

    print("========== SCAN DENAH DIPANGGIL ==========")

    if request.method == "OPTIONS":
        return jsonify({
            "message": "Preflight OK",
            "status": "success"
        }), 200

    if "image" not in request.files:
        return jsonify({
            "status": "error",
            "message": "File image wajib dikirim"
        }), 400

    file = request.files["image"]

    if file.filename == "":
        return jsonify({
            "status": "error",
            "message": "Nama file tidak boleh kosong"
        }), 400

    if not _allowed_file(file.filename):
        return jsonify({
            "status": "error",
            "message": f"Format tidak didukung. Gunakan: {', '.join(ALLOWED_EXTENSIONS)}"
        }), 422

    file_bytes = file.read()

    if len(file_bytes) > MAX_FILE_SIZE:
        return jsonify({
            "status": "error",
            "message": "Ukuran file maksimal 10MB"
        }), 413

    if len(file_bytes) == 0:
        return jsonify({
            "status": "error",
            "message": "File kosong"
        }), 400

    try:
        result = scan_floorplan_image(file_bytes)

    except Exception as e:
        traceback.print_exc()

        return jsonify({
            "status": "error",
            "message": "Terjadi kesalahan internal saat memproses gambar",
            "error": str(e)
        }), 500

    if result == "INVALID_IMAGE":
        return jsonify({
            "status": "error",
            "message": "File gambar tidak dapat dibaca."
        }), 400

    if result == "NO_LINES_DETECTED":
        return jsonify({
            "status": "error",
            "message": "Garis denah tidak terdeteksi."
        }), 400

    if not result.get("valid", False):
        return jsonify({
            "status": "error",
            "message": "Gambar bukan merupakan denah arsitektur yang valid.",
            "data": result
        }), 400

    return jsonify({
        "status": "success",
        "message": "Scan sketsa denah berhasil diproses",
        "data": result
    }), 200


@cv_bp.route("/model-status", methods=["GET"])
def model_status():

    model = get_model()

    return jsonify({
        "status": "success",
        "data": {
            "model_loaded": model is not None,
            "model_file_exists": os.path.exists(MODEL_PATH),
            "model_path": MODEL_PATH,
            "mode": (
                "ai_opencv_hybrid"
                if model is not None
                else "opencv_only_fallback"
            )
        }
    }), 200
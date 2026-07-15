from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager

from config import Config
from routes.auth_routes import auth_bp
from routes.floorplan_routes import floorplan_bp
from routes.rab_routes import rab_bp
from routes.cv_routes import cv_bp

app = Flask(__name__)

# ============================================================
# CORS
# ============================================================
CORS(
    app,
    resources={
        r"/*": {
            "origins": "*",
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
        }
    },
)


@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Private-Network"] = "true"
    return response


# ============================================================
# JWT
# ============================================================
app.config["JWT_SECRET_KEY"] = Config.JWT_SECRET_KEY
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = Config.JWT_ACCESS_TOKEN_EXPIRES
jwt = JWTManager(app)

# ============================================================
# BLUEPRINTS
# ============================================================
app.register_blueprint(auth_bp)
app.register_blueprint(floorplan_bp)
app.register_blueprint(rab_bp)
app.register_blueprint(cv_bp)


# ============================================================
# BASIC ENDPOINTS
# ============================================================
@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "SmartFloorPlan API berjalan", "status": "success"}), 200


@app.route("/api/health", methods=["GET"])
def health_check():
    return jsonify({"message": "API aktif", "service": "SmartFloorPlan Web Service", "status": "healthy"}), 200


@app.route("/api/database/check", methods=["GET"])
def database_check():
    try:
        from supabase_client import get_supabase
        sb = get_supabase()
        sb.table("users").select("id").limit(1).execute()
        return jsonify({"message": "Database terkoneksi", "status": "success", "tables": ["users", "floorplans", "rooms", "rabs"]}), 200
    except Exception as e:
        return jsonify({"message": "Database gagal terkoneksi", "status": "error", "error": str(e)}), 500


# ============================================================
# ERROR HANDLERS
# ============================================================
@app.errorhandler(404)
def not_found(error):
    return jsonify({"message": "Endpoint tidak ditemukan", "status": "error"}), 404


@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({"message": "Method tidak diizinkan untuk endpoint ini", "status": "error"}), 405


# ============================================================
# RUN
# ============================================================
if __name__ == "__main__":
    import threading

    def _warmup():
        try:
            #from services.cv_service import get_model
            get_model()
            print("AI Model Warmup Success")
        except Exception as e:
            print(f"AI Warmup Failed: {e}")

    threading.Thread(
        target=_warmup,
        daemon=True
    ).start()

    app.run(
        host="0.0.0.0",
        port=5000,
        debug=Config.DEBUG
    )
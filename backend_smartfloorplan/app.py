from datetime import timedelta
import cv2
import numpy as np

from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager,
    create_access_token,
    jwt_required,
    get_jwt_identity,
)
from werkzeug.security import generate_password_hash, check_password_hash

from database import get_db_connection, init_database


app = Flask(__name__)

# ============================================================
# CORS CONFIG UNTUK FLUTTER WEB / CHROME
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
# JWT CONFIG
# ============================================================

app.config["JWT_SECRET_KEY"] = "smartfloorplan-secret-key"
app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=24)

jwt = JWTManager(app)


# ============================================================
# BASIC ENDPOINT
# ============================================================

@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "SmartFloorPlan API berjalan",
        "status": "success"
    }), 200


@app.route("/api/health", methods=["GET"])
def health_check():
    return jsonify({
        "message": "API aktif",
        "service": "SmartFloorPlan Web Service",
        "status": "healthy"
    }), 200


@app.route("/api/database/check", methods=["GET"])
def database_check():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()

        conn.close()

        table_names = [table["name"] for table in tables]

        return jsonify({
            "message": "Database terkoneksi",
            "status": "success",
            "tables": table_names
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Database gagal terkoneksi",
            "status": "error",
            "error": str(e)
        }), 500


# ============================================================
# AUTH ENDPOINT
# ============================================================

@app.route("/api/register", methods=["POST"])
def register():
    try:
        data = request.get_json(silent=True)

        if not data:
            return jsonify({
                "message": "Body request harus berupa JSON dan tidak boleh kosong",
                "status": "error"
            }), 400

        name = data.get("name")
        email = data.get("email")
        password = data.get("password")

        if not name or not email or not password:
            return jsonify({
                "message": "Name, email, dan password wajib diisi",
                "status": "error"
            }), 400

        if len(password) < 6:
            return jsonify({
                "message": "Password minimal 6 karakter",
                "status": "error"
            }), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT * FROM users WHERE email = ?",
            (email,)
        )

        existing_user = cursor.fetchone()

        if existing_user:
            conn.close()
            return jsonify({
                "message": "Email sudah terdaftar",
                "status": "error"
            }), 409

        hashed_password = generate_password_hash(password)

        cursor.execute("""
            INSERT INTO users (name, email, password)
            VALUES (?, ?, ?)
        """, (name, email, hashed_password))

        conn.commit()
        user_id = cursor.lastrowid
        conn.close()

        return jsonify({
            "message": "Register berhasil",
            "status": "success",
            "data": {
                "id": user_id,
                "name": name,
                "email": email
            }
        }), 201

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat register",
            "status": "error",
            "error": str(e)
        }), 500


@app.route("/api/login", methods=["POST"])
def login():
    try:
        data = request.get_json(silent=True)

        if not data:
            return jsonify({
                "message": "Body request harus berupa JSON dan tidak boleh kosong",
                "status": "error"
            }), 400

        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return jsonify({
                "message": "Email dan password wajib diisi",
                "status": "error"
            }), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT * FROM users WHERE email = ?",
            (email,)
        )

        user = cursor.fetchone()
        conn.close()

        if user is None:
            return jsonify({
                "message": "Email tidak ditemukan",
                "status": "error"
            }), 404

        if not check_password_hash(user["password"], password):
            return jsonify({
                "message": "Password salah",
                "status": "error"
            }), 401

        access_token = create_access_token(
            identity=str(user["id"])
        )

        return jsonify({
            "message": "Login berhasil",
            "status": "success",
            "token": access_token,
            "data": {
                "id": user["id"],
                "name": user["name"],
                "email": user["email"]
            }
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat login",
            "status": "error",
            "error": str(e)
        }), 500


@app.route("/api/profile", methods=["GET"])
@jwt_required()
def profile():
    try:
        user_id = get_jwt_identity()

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT id, name, email, created_at FROM users WHERE id = ?",
            (user_id,)
        )

        user = cursor.fetchone()
        conn.close()

        if user is None:
            return jsonify({
                "message": "User tidak ditemukan",
                "status": "error"
            }), 404

        return jsonify({
            "message": "Data profile berhasil diambil",
            "status": "success",
            "data": {
                "id": user["id"],
                "name": user["name"],
                "email": user["email"],
                "created_at": user["created_at"]
            }
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat mengambil profile",
            "status": "error",
            "error": str(e)
        }), 500


# ============================================================
# FLOORPLAN / DENAH CRUD ENDPOINT
# ============================================================

@app.route("/api/floorplans", methods=["POST"])
@jwt_required()
def create_floorplan():
    try:
        user_id = get_jwt_identity()
        data = request.get_json(silent=True)

        if not data:
            return jsonify({
                "message": "Body request harus berupa JSON",
                "status": "error"
            }), 400

        title = data.get("title")
        land_width = data.get("land_width")
        land_length = data.get("land_length")
        material = data.get("material")
        rooms = data.get("rooms", [])

        if not title or land_width is None or land_length is None or not material:
            return jsonify({
                "message": "title, land_width, land_length, dan material wajib diisi",
                "status": "error"
            }), 400

        if not isinstance(rooms, list) or len(rooms) == 0:
            return jsonify({
                "message": "rooms wajib berupa list dan minimal berisi 1 ruangan",
                "status": "error"
            }), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO floorplans (user_id, title, land_width, land_length, material)
            VALUES (?, ?, ?, ?, ?)
        """, (user_id, title, land_width, land_length, material))

        floorplan_id = cursor.lastrowid

        for room in rooms:
            room_name = room.get("name")
            x = room.get("x")
            y = room.get("y")
            width = room.get("width")
            height = room.get("height")

            if room_name is None or x is None or y is None or width is None or height is None:
                conn.rollback()
                conn.close()
                return jsonify({
                    "message": "Setiap room wajib memiliki name, x, y, width, dan height",
                    "status": "error"
                }), 400

            cursor.execute("""
                INSERT INTO rooms (floorplan_id, name, x, y, width, height)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (floorplan_id, room_name, x, y, width, height))

        conn.commit()
        conn.close()

        return jsonify({
            "message": "Denah berhasil disimpan",
            "status": "success",
            "data": {
                "id": floorplan_id,
                "title": title,
                "land_width": land_width,
                "land_length": land_length,
                "material": material,
                "rooms_count": len(rooms)
            }
        }), 201

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat menyimpan denah",
            "status": "error",
            "error": str(e)
        }), 500


@app.route("/api/floorplans", methods=["GET"])
@jwt_required()
def get_floorplans():
    try:
        user_id = get_jwt_identity()

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT 
                floorplans.id,
                floorplans.title,
                floorplans.land_width,
                floorplans.land_length,
                floorplans.material,
                floorplans.created_at,
                floorplans.updated_at,
                COUNT(rooms.id) AS rooms_count
            FROM floorplans
            LEFT JOIN rooms ON rooms.floorplan_id = floorplans.id
            WHERE floorplans.user_id = ?
            GROUP BY floorplans.id
            ORDER BY floorplans.created_at DESC
        """, (user_id,))

        floorplans = cursor.fetchall()
        conn.close()

        result = []

        for item in floorplans:
            result.append({
                "id": item["id"],
                "title": item["title"],
                "land_width": item["land_width"],
                "land_length": item["land_length"],
                "material": item["material"],
                "rooms_count": item["rooms_count"],
                "created_at": item["created_at"],
                "updated_at": item["updated_at"]
            })

        return jsonify({
            "message": "Data denah berhasil diambil",
            "status": "success",
            "data": result
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat mengambil data denah",
            "status": "error",
            "error": str(e)
        }), 500


@app.route("/api/floorplans/<int:floorplan_id>", methods=["GET"])
@jwt_required()
def get_floorplan_detail(floorplan_id):
    try:
        user_id = get_jwt_identity()

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT * FROM floorplans
            WHERE id = ? AND user_id = ?
        """, (floorplan_id, user_id))

        floorplan = cursor.fetchone()

        if floorplan is None:
            conn.close()
            return jsonify({
                "message": "Denah tidak ditemukan",
                "status": "error"
            }), 404

        cursor.execute("""
            SELECT id, name, x, y, width, height
            FROM rooms
            WHERE floorplan_id = ?
            ORDER BY id ASC
        """, (floorplan_id,))

        rooms = cursor.fetchall()
        conn.close()

        rooms_result = []

        for room in rooms:
            rooms_result.append({
                "id": room["id"],
                "name": room["name"],
                "x": room["x"],
                "y": room["y"],
                "width": room["width"],
                "height": room["height"]
            })

        return jsonify({
            "message": "Detail denah berhasil diambil",
            "status": "success",
            "data": {
                "id": floorplan["id"],
                "title": floorplan["title"],
                "land_width": floorplan["land_width"],
                "land_length": floorplan["land_length"],
                "material": floorplan["material"],
                "created_at": floorplan["created_at"],
                "updated_at": floorplan["updated_at"],
                "rooms": rooms_result
            }
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat mengambil detail denah",
            "status": "error",
            "error": str(e)
        }), 500


@app.route("/api/floorplans/<int:floorplan_id>", methods=["PUT"])
@jwt_required()
def update_floorplan(floorplan_id):
    try:
        user_id = get_jwt_identity()
        data = request.get_json(silent=True)

        if not data:
            return jsonify({
                "message": "Body request harus berupa JSON",
                "status": "error"
            }), 400

        title = data.get("title")
        land_width = data.get("land_width")
        land_length = data.get("land_length")
        material = data.get("material")
        rooms = data.get("rooms", [])

        if not title or land_width is None or land_length is None or not material:
            return jsonify({
                "message": "title, land_width, land_length, dan material wajib diisi",
                "status": "error"
            }), 400

        if not isinstance(rooms, list) or len(rooms) == 0:
            return jsonify({
                "message": "rooms wajib berupa list dan minimal berisi 1 ruangan",
                "status": "error"
            }), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT * FROM floorplans
            WHERE id = ? AND user_id = ?
        """, (floorplan_id, user_id))

        existing_floorplan = cursor.fetchone()

        if existing_floorplan is None:
            conn.close()
            return jsonify({
                "message": "Denah tidak ditemukan",
                "status": "error"
            }), 404

        cursor.execute("""
            UPDATE floorplans
            SET title = ?, land_width = ?, land_length = ?, material = ?, updated_at = CURRENT_TIMESTAMP
            WHERE id = ? AND user_id = ?
        """, (title, land_width, land_length, material, floorplan_id, user_id))

        cursor.execute("""
            DELETE FROM rooms
            WHERE floorplan_id = ?
        """, (floorplan_id,))

        for room in rooms:
            room_name = room.get("name")
            x = room.get("x")
            y = room.get("y")
            width = room.get("width")
            height = room.get("height")

            if room_name is None or x is None or y is None or width is None or height is None:
                conn.rollback()
                conn.close()
                return jsonify({
                    "message": "Setiap room wajib memiliki name, x, y, width, dan height",
                    "status": "error"
                }), 400

            cursor.execute("""
                INSERT INTO rooms (floorplan_id, name, x, y, width, height)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (floorplan_id, room_name, x, y, width, height))

        conn.commit()
        conn.close()

        return jsonify({
            "message": "Denah berhasil diperbarui",
            "status": "success",
            "data": {
                "id": floorplan_id,
                "title": title,
                "land_width": land_width,
                "land_length": land_length,
                "material": material,
                "rooms_count": len(rooms)
            }
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat memperbarui denah",
            "status": "error",
            "error": str(e)
        }), 500


@app.route("/api/floorplans/<int:floorplan_id>", methods=["DELETE"])
@jwt_required()
def delete_floorplan(floorplan_id):
    try:
        user_id = get_jwt_identity()

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT * FROM floorplans
            WHERE id = ? AND user_id = ?
        """, (floorplan_id, user_id))

        existing_floorplan = cursor.fetchone()

        if existing_floorplan is None:
            conn.close()
            return jsonify({
                "message": "Denah tidak ditemukan",
                "status": "error"
            }), 404

        cursor.execute("""
            DELETE FROM rabs
            WHERE floorplan_id = ?
        """, (floorplan_id,))

        cursor.execute("""
            DELETE FROM rooms
            WHERE floorplan_id = ?
        """, (floorplan_id,))

        cursor.execute("""
            DELETE FROM floorplans
            WHERE id = ? AND user_id = ?
        """, (floorplan_id, user_id))

        conn.commit()
        conn.close()

        return jsonify({
            "message": "Denah berhasil dihapus",
            "status": "success"
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat menghapus denah",
            "status": "error",
            "error": str(e)
        }), 500


# ============================================================
# RAB ENDPOINT
# ============================================================

@app.route("/api/rab", methods=["POST"])
@jwt_required()
def create_rab():
    try:
        user_id = get_jwt_identity()
        data = request.get_json(silent=True)

        if not data:
            return jsonify({
                "message": "Body request harus berupa JSON",
                "status": "error"
            }), 400

        floorplan_id = data.get("floorplan_id")

        if floorplan_id is None:
            return jsonify({
                "message": "floorplan_id wajib diisi",
                "status": "error"
            }), 400

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT * FROM floorplans
            WHERE id = ? AND user_id = ?
        """, (floorplan_id, user_id))

        floorplan = cursor.fetchone()

        if floorplan is None:
            conn.close()
            return jsonify({
                "message": "Denah tidak ditemukan atau bukan milik user ini",
                "status": "error"
            }), 404

        cursor.execute("""
            SELECT width, height
            FROM rooms
            WHERE floorplan_id = ?
        """, (floorplan_id,))

        rooms = cursor.fetchall()

        if len(rooms) == 0:
            conn.close()
            return jsonify({
                "message": "Denah belum memiliki ruangan",
                "status": "error"
            }), 400

        skala = 20.0
        harga_per_meter = 3500000

        total_area = 0

        for room in rooms:
            luas_room = (room["width"] / skala) * (room["height"] / skala)
            total_area += luas_room

        total_price = total_area * harga_per_meter

        foundation_cost = total_price * 0.25
        wall_cost = total_price * 0.20
        roof_cost = total_price * 0.15
        floor_cost = total_price * 0.15
        finishing_cost = total_price * 0.25

        cursor.execute("""
            DELETE FROM rabs
            WHERE floorplan_id = ?
        """, (floorplan_id,))

        cursor.execute("""
            INSERT INTO rabs (
                floorplan_id,
                total_area,
                total_price,
                foundation_cost,
                wall_cost,
                roof_cost,
                floor_cost,
                finishing_cost
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            floorplan_id,
            total_area,
            total_price,
            foundation_cost,
            wall_cost,
            roof_cost,
            floor_cost,
            finishing_cost
        ))

        rab_id = cursor.lastrowid

        conn.commit()
        conn.close()

        return jsonify({
            "message": "RAB berhasil dibuat dan disimpan",
            "status": "success",
            "data": {
                "id": rab_id,
                "floorplan_id": floorplan_id,
                "total_area": round(total_area, 2),
                "total_price": round(total_price, 2),
                "foundation_cost": round(foundation_cost, 2),
                "wall_cost": round(wall_cost, 2),
                "roof_cost": round(roof_cost, 2),
                "floor_cost": round(floor_cost, 2),
                "finishing_cost": round(finishing_cost, 2)
            }
        }), 201

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat membuat RAB",
            "status": "error",
            "error": str(e)
        }), 500


@app.route("/api/rab/<int:floorplan_id>", methods=["GET"])
@jwt_required()
def get_rab(floorplan_id):
    try:
        user_id = get_jwt_identity()

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT * FROM floorplans
            WHERE id = ? AND user_id = ?
        """, (floorplan_id, user_id))

        floorplan = cursor.fetchone()

        if floorplan is None:
            conn.close()
            return jsonify({
                "message": "Denah tidak ditemukan atau bukan milik user ini",
                "status": "error"
            }), 404

        cursor.execute("""
            SELECT * FROM rabs
            WHERE floorplan_id = ?
        """, (floorplan_id,))

        rab = cursor.fetchone()
        conn.close()

        if rab is None:
            return jsonify({
                "message": "RAB belum dibuat untuk denah ini",
                "status": "error"
            }), 404

        return jsonify({
            "message": "Data RAB berhasil diambil",
            "status": "success",
            "data": {
                "id": rab["id"],
                "floorplan_id": rab["floorplan_id"],
                "total_area": rab["total_area"],
                "total_price": rab["total_price"],
                "foundation_cost": rab["foundation_cost"],
                "wall_cost": rab["wall_cost"],
                "roof_cost": rab["roof_cost"],
                "floor_cost": rab["floor_cost"],
                "finishing_cost": rab["finishing_cost"],
                "created_at": rab["created_at"]
            }
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat mengambil RAB",
            "status": "error",
            "error": str(e)
        }), 500


# ============================================================
# COMPUTER VISION ENDPOINT - OPENCV SCAN DENAH
# ============================================================


@app.route("/api/cv/scan-denah", methods=["POST", "OPTIONS"])
def scan_denah_cv():
    try:
        if request.method == "OPTIONS":
            return jsonify({
                "message": "Preflight OK",
                "status": "success"
            }), 200

        if "image" not in request.files:
            return jsonify({
                "message": "File image wajib dikirim",
                "status": "error"
            }), 400

        file = request.files["image"]

        image_bytes = np.frombuffer(file.read(), np.uint8)
        image = cv2.imdecode(image_bytes, cv2.IMREAD_COLOR)

        if image is None:
            return jsonify({
                "message": "File gambar tidak valid",
                "status": "error"
            }), 400

        original_height, original_width = image.shape[:2]

        # OpenCV Advanced: resolusi lebih besar supaya garis denah lebih kebaca
        target_width = 900
        scale = target_width / original_width
        target_height = int(original_height * scale)

        resized = cv2.resize(
            image,
            (target_width, target_height),
            interpolation=cv2.INTER_AREA
        )

        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
        blur = cv2.GaussianBlur(gray, (3, 3), 0)

        # Threshold adaptive lebih aman untuk gambar denah kosong
        wall_mask = cv2.adaptiveThreshold(
            blur,
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV,
            31,
            9
        )

        # Hapus noise kecil
        noise_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2))
        wall_mask = cv2.morphologyEx(
            wall_mask,
            cv2.MORPH_OPEN,
            noise_kernel,
            iterations=1
        )

        # Crop area denah, supaya margin putih luar tidak ikut dihitung
        coords = cv2.findNonZero(wall_mask)

        if coords is None:
            return jsonify({
                "message": "Garis denah tidak terdeteksi. Gunakan gambar dengan garis hitam jelas.",
                "status": "error"
            }), 400

        x, y, w, h = cv2.boundingRect(coords)

        margin = 16
        x1 = max(x - margin, 0)
        y1 = max(y - margin, 0)
        x2 = min(x + w + margin, target_width)
        y2 = min(y + h + margin, target_height)

        cropped_wall = wall_mask[y1:y2, x1:x2]
        crop_h, crop_w = cropped_wall.shape[:2]

        # ============================================================
        # OPEN CV ADVANCED PART
        # 1. Tebalkan dinding
        # 2. Tutup celah kecil pintu sementara
        # 3. Cari area ruang tertutup
        # ============================================================

        close_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (11, 11))
        closed_wall = cv2.morphologyEx(
            cropped_wall,
            cv2.MORPH_CLOSE,
            close_kernel,
            iterations=2
        )

        dilate_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (4, 4))
        solid_wall = cv2.dilate(
            closed_wall,
            dilate_kernel,
            iterations=2
        )

        # Ruang kosong adalah area putih di antara dinding
        free_space = cv2.bitwise_not(solid_wall)

        # Buang area luar bangunan dengan flood fill dari pinggir
        flood = free_space.copy()
        fh, fw = flood.shape[:2]
        mask = np.zeros((fh + 2, fw + 2), np.uint8)

        cv2.floodFill(flood, mask, (0, 0), 0)

        contours, _ = cv2.findContours(
            flood,
            cv2.RETR_EXTERNAL,
            cv2.CHAIN_APPROX_SIMPLE
        )

        boxes = _extract_room_boxes_cv(
            contours=contours,
            crop_w=crop_w,
            crop_h=crop_h,
            min_area_ratio=0.004,
            max_area_ratio=0.65,
        )

        # Fallback kalau hasil terlalu sedikit
        if len(boxes) < 4:
            fallback_wall = cv2.dilate(
                cropped_wall,
                cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3)),
                iterations=1
            )

            fallback_free = cv2.bitwise_not(fallback_wall)
            fallback_flood = fallback_free.copy()
            mask = np.zeros((crop_h + 2, crop_w + 2), np.uint8)
            cv2.floodFill(fallback_flood, mask, (0, 0), 0)

            fallback_contours, _ = cv2.findContours(
                fallback_flood,
                cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE
            )

            fallback_boxes = _extract_room_boxes_cv(
                contours=fallback_contours,
                crop_w=crop_w,
                crop_h=crop_h,
                min_area_ratio=0.003,
                max_area_ratio=0.75,
            )

            if len(fallback_boxes) > len(boxes):
                boxes = fallback_boxes

        boxes = _merge_similar_boxes_cv(boxes)
        boxes = _remove_outer_or_invalid_boxes_cv(boxes, crop_w, crop_h)

        boxes.sort(key=lambda item: (item["y"], item["x"]))

        rooms = []

        for index, box in enumerate(boxes[:12]):
            rooms.append({
                "name": f"Ruang {index + 1}",
                "x": box["x"],
                "y": box["y"],
                "width": box["width"],
                "height": box["height"]
            })

        return jsonify({
            "message": "Scan sketsa denah berhasil diproses dengan OpenCV Advanced",
            "status": "success",
            "data": {
                "total_rooms": len(rooms),
                "image_width": crop_w,
                "image_height": crop_h,
                "rooms": rooms,
                "debug": {
                    "method": "opencv_advanced",
                    "original_width": original_width,
                    "original_height": original_height,
                    "target_width": target_width,
                    "target_height": target_height,
                    "crop_x": x1,
                    "crop_y": y1,
                    "crop_width": crop_w,
                    "crop_height": crop_h
                }
            }
        }), 200

    except Exception as e:
        return jsonify({
            "message": "Terjadi kesalahan saat memproses gambar denah",
            "status": "error",
            "error": str(e)
        }), 500


def _extract_room_boxes_cv(
    contours,
    crop_w,
    crop_h,
    min_area_ratio=0.004,
    max_area_ratio=0.65,
):
    boxes = []
    crop_area = crop_w * crop_h

    min_area = max(700, crop_area * min_area_ratio)
    max_area = crop_area * max_area_ratio

    for contour in contours:
        area = cv2.contourArea(contour)
        x, y, bw, bh = cv2.boundingRect(contour)

        if area < min_area:
            continue

        if area > max_area:
            continue

        if bw < 24 or bh < 24:
            continue

        aspect_ratio = bw / max(bh, 1)

        if aspect_ratio < 0.16 or aspect_ratio > 6.5:
            continue

        fill_ratio = area / max(float(bw * bh), 1.0)

        if fill_ratio < 0.20:
            continue

        # Hindari area super tipis yang biasanya cuma garis/noise
        if bw < crop_w * 0.04 and bh < crop_h * 0.04:
            continue

        boxes.append({
            "x": float(x),
            "y": float(y),
            "width": float(bw),
            "height": float(bh),
            "area": float(area),
            "fill_ratio": float(fill_ratio)
        })

    return boxes


def _merge_similar_boxes_cv(boxes):
    if not boxes:
        return []

    boxes = sorted(boxes, key=lambda item: item["area"], reverse=True)
    merged = []

    for box in boxes:
        duplicate = False

        for existing in merged:
            if _box_iou_cv(box, existing) > 0.50:
                duplicate = True
                break

            # Kalau satu box hampir di dalam box lain, ambil yang lebih besar
            if _box_inside_ratio_cv(box, existing) > 0.70:
                duplicate = True
                break

        if not duplicate:
            merged.append(box)

    return merged


def _remove_outer_or_invalid_boxes_cv(boxes, crop_w, crop_h):
    if not boxes:
        return []

    result = []
    crop_area = crop_w * crop_h

    for box in boxes:
        area = box["width"] * box["height"]

        # buang box terlalu besar yang kemungkinan area tengah/luar
        if area > crop_area * 0.80:
            continue

        # buang box yang terlalu nempel seluruh sisi
        touches_left = box["x"] <= 3
        touches_top = box["y"] <= 3
        touches_right = box["x"] + box["width"] >= crop_w - 3
        touches_bottom = box["y"] + box["height"] >= crop_h - 3

        touch_count = sum([touches_left, touches_top, touches_right, touches_bottom])

        if touch_count >= 3:
            continue

        result.append(box)

    return result


def _box_iou_cv(a, b):
    ax1 = a["x"]
    ay1 = a["y"]
    ax2 = a["x"] + a["width"]
    ay2 = a["y"] + a["height"]

    bx1 = b["x"]
    by1 = b["y"]
    bx2 = b["x"] + b["width"]
    by2 = b["y"] + b["height"]

    ix1 = max(ax1, bx1)
    iy1 = max(ay1, by1)
    ix2 = min(ax2, bx2)
    iy2 = min(ay2, by2)

    iw = max(0, ix2 - ix1)
    ih = max(0, iy2 - iy1)

    inter = iw * ih
    area_a = max(1, a["width"] * a["height"])
    area_b = max(1, b["width"] * b["height"])

    return inter / (area_a + area_b - inter)


def _box_inside_ratio_cv(inner, outer):
    ix1 = max(inner["x"], outer["x"])
    iy1 = max(inner["y"], outer["y"])
    ix2 = min(inner["x"] + inner["width"], outer["x"] + outer["width"])
    iy2 = min(inner["y"] + inner["height"], outer["y"] + outer["height"])

    iw = max(0, ix2 - ix1)
    ih = max(0, iy2 - iy1)

    inter = iw * ih
    inner_area = max(1, inner["width"] * inner["height"])

    return inter / inner_area


# ============================================================
# ERROR HANDLER
# ============================================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "message": "Endpoint tidak ditemukan",
        "status": "error"
    }), 404


@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({
        "message": "Method tidak diizinkan untuk endpoint ini",
        "status": "error"
    }), 405


# ============================================================
# RUN SERVER
# ============================================================

if __name__ == "__main__":
    init_database()
    app.run(host="0.0.0.0", port=5000, debug=True)
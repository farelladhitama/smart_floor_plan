from pathlib import Path
import re

path = Path(r"backend_smartfloorplan\app.py")

if not path.exists():
    raise SystemExit("ERROR: backend_smartfloorplan\\app.py tidak ditemukan.")

backup = path.with_suffix(path.suffix + ".before-opencv-advanced.bak")
backup.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

text = path.read_text(encoding="utf-8").replace("\r\n", "\n")

new_route = r'''
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
'''

pattern = r'@app\.route\("/api/cv/scan-denah", methods=\["POST", "OPTIONS"\]\)\ndef scan_denah_cv\(\):.*?\n\n# ============================================================\n# ERROR HANDLER'

replacement = new_route + "\n\n# ============================================================\n# ERROR HANDLER"

new_text, count = re.subn(pattern, replacement, text, count=1, flags=re.S)

if count == 0:
    raise SystemExit("ERROR: route /api/cv/scan-denah tidak ketemu.")

path.write_text(new_text, encoding="utf-8")

print("PATCH BERHASIL: backend sekarang pakai OpenCV Advanced.")

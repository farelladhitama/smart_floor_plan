"""
OpenCV Floorplan Reconstruction Pipeline
==========================================

Tugas modul ini HANYA:
    - deteksi garis dinding
    - deteksi batas ruangan
    - rekonstruksi layout sesuai gambar input
    - menghasilkan posisi & ukuran (+ bentuk asli) ruangan

Modul ini TIDAK menentukan jenis ruangan (itu tugas Rule Based Engine
terpisah) dan TIDAK bergantung pada image classifier — semua validasi
"apakah ini benar-benar denah" dilakukan lewat analisis struktur
geometris murni (garis, sudut, bentuk kontur), bukan machine learning.

Strategi anti-false-positive (mis. foto kucing/motor/manusia yang bisa
lolos jadi "ruangan"):
    1. Structural gate di level gambar: denah didominasi garis lurus
       horizontal/vertikal (dinding). Objek organik (hewan, manusia,
       kendaraan) punya kontur melengkung/diagonal acak — rasio garis
       axis-aligned-nya jauh lebih rendah. Gambar yang tidak lolos gate
       ini ditolak SEBELUM sampai ke tahap ekstraksi ruangan.
    2. Structural gate per-kontur: kandidat "ruangan" wajib berbentuk
       polygon rectilinear (jumlah sudut wajar & mayoritas sudutnya
       mendekati 90°). Siluet organik akan gagal di sini walau lolos
       filter area/aspect/fill.
    3. Grid/tabel-pattern rejection: screenshot tabel/spreadsheet bisa
       punya banyak kotak kecil seragam — ini bukan pola denah rumah
       (ruangan biasanya bervariasi ukurannya), jadi ditolak jika
       terlalu banyak kotak dengan ukuran nyaris identik.
"""

import cv2
import numpy as np
from dataclasses import dataclass
from typing import List


# ─────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────

def scan_floorplan_image(file_bytes: bytes) -> dict | str:
    image_bytes = np.frombuffer(file_bytes, np.uint8)
    image = cv2.imdecode(image_bytes, cv2.IMREAD_COLOR)

    if image is None:
        return "INVALID_IMAGE"

    original_height, original_width = image.shape[:2]

    target_width = 900
    scale = target_width / original_width
    target_height = int(original_height * scale)
    resized = cv2.resize(image, (target_width, target_height), interpolation=cv2.INTER_AREA)

    # ── Preprocessing kuat: CLAHE + dual detection (adaptive + Canny) ──
    wall_mask = _build_wall_mask(resized)

    coords = cv2.findNonZero(wall_mask)
    if coords is None:
        return "NO_LINES_DETECTED"

    x, y, w, h = cv2.boundingRect(coords)
    margin = 16
    x1 = max(x - margin, 0)
    y1 = max(y - margin, 0)
    x2 = min(x + w + margin, target_width)
    y2 = min(y + h + margin, target_height)

    cropped_wall = wall_mask[y1:y2, x1:x2]
    crop_h, crop_w = cropped_wall.shape[:2]

    

    # ── GATE 1: Structural check di level gambar ──────────────────
    # Menolak objek non-denah (foto, ikon, dsb) sebelum ekstraksi ruangan.
    is_structural, structural_reason = _looks_like_floorplan_structure(cropped_wall)
    if not is_structural:
        return "NOT_FLOORPLAN_STRUCTURE"

    # ── Ekstraksi ruangan: coba beberapa kekuatan wall-closing ─────
    # Kekuatan closing yang pas beda-beda tergantung ketebalan garis
    # dan lebar celah pintu/jendela pada tiap denah, jadi kita coba
    # beberapa konfigurasi dan pilih yang paling masuk akal.
    best_boxes = []
    closing_configs = [
        {"close": 9,  "close_iter": 2, "dilate": 3, "dilate_iter": 2},
        {"close": 13, "close_iter": 2, "dilate": 4, "dilate_iter": 2},
        {"close": 17, "close_iter": 3, "dilate": 5, "dilate_iter": 2},
        {"close": 6,  "close_iter": 1, "dilate": 2, "dilate_iter": 1},
    ]

    for cfg in closing_configs:
        boxes = _segment_rooms(cropped_wall, crop_w, crop_h, cfg)
        if _is_better_result(boxes, best_boxes):
            best_boxes = boxes

    boxes = _merge_similar_boxes(best_boxes)
    boxes = _remove_outer_or_invalid_boxes(boxes, crop_w, crop_h)

    # ── GATE 3: Pola grid/tabel (screenshot, dokumen) ──────────────
    if _looks_like_grid_pattern(boxes):
        return "NOT_FLOORPLAN_STRUCTURE"

    if len(boxes) == 0:
        return "NOT_FLOORPLAN_STRUCTURE"

    boxes.sort(key=lambda item: (item["y"], item["x"]))

    rooms = []
    for index, box in enumerate(boxes[:12]):
        rooms.append({
            "name": f"Ruang {index + 1}",
            "x": box["x"],
            "y": box["y"],
            "width": box["width"],
            "height": box["height"],
            "points": box["points"],   # bentuk poligon asli, bukan cuma kotak
            "fill_ratio": round(box["fill_ratio"], 3),
        })

    return {
        "total_rooms": len(rooms),
        "image_width": crop_w,
        "image_height": crop_h,
        "rooms": rooms,
        "debug": {
            "method": "opencv_structural_v2",
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


# ─────────────────────────────────────────────
# PREPROCESSING
# ─────────────────────────────────────────────

def _build_wall_mask(resized_bgr: np.ndarray) -> np.ndarray:
    """
    Bangun mask dinding yang robust terhadap garis tipis, denah
    berwarna, dan kontras rendah.
    """
    gray = cv2.cvtColor(resized_bgr, cv2.COLOR_BGR2GRAY)

    # CLAHE — naikkan kontras lokal supaya garis tipis/pudar lebih tegas
    clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
    gray_eq = clahe.apply(gray)

    # Bilateral filter — kurangi noise TANPA mengaburkan tepi garis
    # (beda dengan GaussianBlur yang bisa menghilangkan garis 1-2px)
    smooth = cv2.bilateralFilter(gray_eq, d=5, sigmaColor=45, sigmaSpace=45)

    # Sinyal 1: adaptive threshold — kuat untuk garis solid/tebal
    adaptive_mask = cv2.adaptiveThreshold(
        smooth, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY_INV,
        31, 9
    )

    # Sinyal 2: Canny — menangkap garis tipis/lemah yang sering lolos
    # dari adaptive threshold, terutama pada denah berwarna
    edges = cv2.Canny(smooth, 40, 120)
    edges = cv2.dilate(edges, cv2.getStructuringElement(cv2.MORPH_RECT, (2, 2)), iterations=1)

    combined = cv2.bitwise_or(adaptive_mask, edges)

    # Tutup celah kecil akibat noise scan
    close_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    combined = cv2.morphologyEx(combined, cv2.MORPH_CLOSE, close_kernel, iterations=1)

    # Buang blob noise kecil TANPA menghapus garis panjang tipis.
    # Morphological opening klasik bisa menghilangkan garis 1-2px lewat
    # erosi; connected-components filtering lebih aman (garis panjang
    # tipis tetap punya area total besar meski lebarnya kecil).
    return _remove_small_blobs(combined, min_area=6)


def _remove_small_blobs(mask: np.ndarray, min_area: int = 6) -> np.ndarray:
    num_labels, labels, stats, _ = cv2.connectedComponentsWithStats(mask, connectivity=8)
    clean = np.zeros_like(mask)
    for i in range(1, num_labels):
        if stats[i, cv2.CC_STAT_AREA] >= min_area:
            clean[labels == i] = 255
    return clean


# ─────────────────────────────────────────────
# GATE 1: STRUCTURAL CHECK (level gambar)
# ─────────────────────────────────────────────

def _looks_like_floorplan_structure(wall_mask: np.ndarray) -> tuple[bool, str]:
    """
    Cek apakah gambar didominasi struktur garis lurus horizontal/
    vertikal seperti denah, atau kontur organik/acak seperti foto
    kucing, motor, manusia, dsb.

    Denah (bahkan sketsa tangan sederhana) didominasi garis dinding
    yang relatif axis-aligned. Foto objek nyata didominasi tepi
    melengkung/diagonal tak beraturan.
    """
    h, w = wall_mask.shape[:2]

    lines = cv2.HoughLinesP(
        wall_mask, 1, np.pi / 180,
        threshold=40, minLineLength=max(20, int(min(h, w) * 0.03)), maxLineGap=8
    )

    if lines is None or len(lines) < 6:
        return False, "too_few_structural_lines"

    total_len = 0.0
    aligned_len = 0.0
    for line in lines:
        lx1, ly1, lx2, ly2 = line[0]
        length = float(np.hypot(lx2 - lx1, ly2 - ly1))
        if length < 1:
            continue
        angle = abs(np.degrees(np.arctan2(ly2 - ly1, lx2 - lx1)))
        angle = angle if angle <= 90 else 180 - angle
        total_len += length
        if angle <= 14 or angle >= 76:   # dekat horizontal atau vertikal
            aligned_len += length

    if total_len <= 0:
        return False, "no_line_length"

    axis_ratio = aligned_len / total_len
    if axis_ratio < 0.45:
        return False, "low_axis_aligned_ratio"

    return True, "ok"


# ─────────────────────────────────────────────
# ROOM SEGMENTATION (multi-pass, adaptif)
# ─────────────────────────────────────────────

def _segment_rooms(cropped_wall: np.ndarray, crop_w: int, crop_h: int, cfg: dict) -> list[dict]:
    close_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (cfg["close"], cfg["close"]))
    closed_wall = cv2.morphologyEx(cropped_wall, cv2.MORPH_CLOSE, close_kernel, iterations=cfg["close_iter"])

    dilate_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (cfg["dilate"], cfg["dilate"]))
    solid_wall = cv2.dilate(closed_wall, dilate_kernel, iterations=cfg["dilate_iter"])

    free_space = cv2.bitwise_not(solid_wall)
    flood = free_space.copy()
    fh, fw = flood.shape[:2]
    mask = np.zeros((fh + 2, fw + 2), np.uint8)
    cv2.floodFill(flood, mask, (0, 0), 0)

    contours, _ = cv2.findContours(flood, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    return _extract_room_boxes(contours, crop_w, crop_h)


def _is_better_result(candidate: list[dict], current_best: list[dict]) -> bool:
    """
    Pilih hasil dengan jumlah ruangan paling masuk akal untuk denah
    rumah tinggal (2-14 ruangan) dan fill_ratio rata-rata tinggi,
    bukan sekadar jumlah kotak terbanyak (yang biasanya noise).
    """
    def score(boxes):
        n = len(boxes)
        if n == 0:
            return -1.0
        avg_fill = sum(b["fill_ratio"] for b in boxes) / n
        count_score = 1.0 - min(1.0, abs(n - 6) / 10.0)
        return count_score * 0.5 + avg_fill * 0.5

    return score(candidate) > score(current_best)


def _extract_room_boxes(contours, crop_w, crop_h, min_area_ratio=0.004, max_area_ratio=0.65):
    boxes = []
    crop_area = crop_w * crop_h
    min_area = max(700, crop_area * min_area_ratio)
    max_area = crop_area * max_area_ratio

    for contour in contours:
        area = cv2.contourArea(contour)
        x, y, bw, bh = cv2.boundingRect(contour)

        if area < min_area or area > max_area:
            continue
        if bw < 24 or bh < 24:
            continue

        aspect_ratio = bw / max(bh, 1)
        if aspect_ratio < 0.16 or aspect_ratio > 6.5:
            continue

        fill_ratio = area / max(float(bw * bh), 1.0)
        if fill_ratio < 0.45:
            # dinaikkan dari 0.20 — ruangan denah nyaris selalu mengisi
            # sebagian besar bounding box-nya; blob organik (siluet
            # hewan/manusia) biasanya jauh lebih longgar dari ini
            continue
        if bw < crop_w * 0.04 and bh < crop_h * 0.04:
            continue

        # ── GATE 2: validasi bentuk polygon rectilinear ────────────
        is_room_shape, points = _is_room_like_polygon(contour)
        if not is_room_shape:
            continue

        boxes.append({
            "x": float(x),
            "y": float(y),
            "width": float(bw),
            "height": float(bh),
            "area": float(area),
            "fill_ratio": float(fill_ratio),
            "points": points,
        })

    return boxes


def _is_room_like_polygon(
    contour,
    min_vertices: int = 4,
    max_vertices: int = 10,
    min_right_angle_ratio: float = 0.5,
) -> tuple[bool, list]:
    """
    Validasi bahwa kontur berbentuk polygon rectilinear seperti
    ruangan (jumlah sudut wajar & mayoritas mendekati 90°), bukan
    kontur organik/melengkung dari objek non-denah.
    """
    peri = cv2.arcLength(contour, True)
    if peri <= 0:
        return False, []

    approx = cv2.approxPolyDP(contour, 0.02 * peri, True)
    pts = approx.reshape(-1, 2)
    n = len(pts)

    if n < min_vertices or n > max_vertices:
        return False, []

    right_count = 0
    for i in range(n):
        p0 = pts[i - 1].astype(np.float64)
        p1 = pts[i].astype(np.float64)
        p2 = pts[(i + 1) % n].astype(np.float64)
        v1 = p0 - p1
        v2 = p2 - p1
        norm1 = np.linalg.norm(v1)
        norm2 = np.linalg.norm(v2)
        if norm1 < 1e-6 or norm2 < 1e-6:
            continue
        cos_ang = np.dot(v1, v2) / (norm1 * norm2)
        ang = np.degrees(np.arccos(np.clip(cos_ang, -1.0, 1.0)))
        if 70 <= ang <= 110:
            right_count += 1

    if n == 0:
        return False, []

    if (right_count / n) < min_right_angle_ratio:
        return False, []

    points = [[float(p[0]), float(p[1])] for p in pts]
    return True, points


# ─────────────────────────────────────────────
# GATE 3: GRID / TABLE PATTERN REJECTION
# ─────────────────────────────────────────────

def _looks_like_grid_pattern(boxes: list[dict]) -> bool:
    """
    Tolak jika kotak yang terdeteksi terlalu banyak dan seragam
    ukurannya — pola khas tabel/spreadsheet/grid UI, bukan denah
    rumah (ruangan pada denah nyata bervariasi ukurannya).
    """
    if len(boxes) < 15:
        return False

    areas = [b["area"] for b in boxes]
    mean_area = sum(areas) / len(areas)
    if mean_area <= 0:
        return False

    variance = sum((a - mean_area) ** 2 for a in areas) / len(areas)
    std_dev = variance ** 0.5
    coeff_variation = std_dev / mean_area

    return coeff_variation < 0.15


# ─────────────────────────────────────────────
# MERGE & FILTER
# ─────────────────────────────────────────────

def _merge_similar_boxes(boxes):
    if not boxes:
        return []
    boxes = sorted(boxes, key=lambda item: item["area"], reverse=True)
    merged = []
    for box in boxes:
        duplicate = False
        for existing in merged:
            if _box_iou(box, existing) > 0.50 or _box_inside_ratio(box, existing) > 0.70:
                duplicate = True
                break
        if not duplicate:
            merged.append(box)
    return merged


def _remove_outer_or_invalid_boxes(boxes, crop_w, crop_h):
    result = []
    crop_area = crop_w * crop_h
    for box in boxes:
        area = box["width"] * box["height"]
        if area > crop_area * 0.80:
            continue
        touches_left = box["x"] <= 3
        touches_top = box["y"] <= 3
        touches_right = box["x"] + box["width"] >= crop_w - 3
        touches_bottom = box["y"] + box["height"] >= crop_h - 3
        if sum([touches_left, touches_top, touches_right, touches_bottom]) >= 3:
            continue
        result.append(box)
    return result


def _box_iou(a, b):
    ax1, ay1 = a["x"], a["y"]
    ax2, ay2 = ax1 + a["width"], ay1 + a["height"]
    bx1, by1 = b["x"], b["y"]
    bx2, by2 = bx1 + b["width"], by1 + b["height"]
    iw = max(0, min(ax2, bx2) - max(ax1, bx1))
    ih = max(0, min(ay2, by2) - max(ay1, by1))
    inter = iw * ih
    area_a = max(1, a["width"] * a["height"])
    area_b = max(1, b["width"] * b["height"])
    return inter / (area_a + area_b - inter)


def _box_inside_ratio(inner, outer):
    ix1 = max(inner["x"], outer["x"])
    iy1 = max(inner["y"], outer["y"])
    ix2 = min(inner["x"] + inner["width"], outer["x"] + outer["width"])
    iy2 = min(inner["y"] + inner["height"], outer["y"] + outer["height"])
    iw = max(0, ix2 - ix1)
    ih = max(0, iy2 - iy1)
    return (iw * ih) / max(1, inner["width"] * inner["height"])
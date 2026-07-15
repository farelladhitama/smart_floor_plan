"""
CV Service — Orchestrator utama sistem.

Alur:
1. Decode gambar
2. Preprocess OpenCV
3. Ekstraksi fitur visual
4. Klasifikasi AI (MobileNetV2) → valid/tidak valid
5. Intelligent gating: gabungkan skor AI + fitur visual
6. Deteksi ruangan (jika valid)
7. Return hasil terstruktur

INTELLIGENT SYSTEM:
    Keputusan "valid/tidak valid" tidak hanya dari model AI,
    tetapi digabung dengan sinyal dari fitur visual:
    - line_density tinggi → kemungkinan denah tinggi
    - corner_density tinggi → banyak sudut → kemungkinan denah
    - edge_ratio sedang → bukan foto polos/acak

    Combinasi ini menghasilkan keputusan yang lebih robust
    dibanding classifier tunggal.
"""

import os
import numpy as np
import cv2
import threading
import tensorflow as tf

from utils.cv_utils import (
    preprocess_image,
    extract_visual_features,
    detect_rooms,
    compute_floorplan_signals,
    is_likely_floorplan,
    PreprocessResult,
)
from models.floorplan_classifier import load_trained_model, predict_single, IMG_SIZE

# ─────────────────────────────────────────────
# KONSTANTA THRESHOLD
# ─────────────────────────────────────────────
AI_CONFIDENCE_THRESHOLD    = 0.96 # Skor minimum AI untuk diterima SEBAGAI floorplan
LINE_DENSITY_THRESHOLD     = 1.5   # Minimum line density untuk denah (filter TAMBAHAN, bukan booster)
CORNER_DENSITY_THRESHOLD   = 0.003 # Minimum corner density untuk denah
MIN_RECTANGULARITY         = 0.25  # Denah harus punya struktur persegi minimal
MODEL_PATH                 = os.getenv("MODEL_PATH", "models/saved/classifier_v1.h5")

# Singleton model (thread-safe)
_model       = None
_model_lock  = threading.Lock()


def get_model():
    """Load model sekali, cache di memory."""
    global _model
    if _model is None:
        with _model_lock:
            if _model is None:
                if os.path.exists(MODEL_PATH):
                    _model = load_trained_model(MODEL_PATH)
                    print(f"[CV Service] Model loaded dari: {MODEL_PATH}")
                else:
                    print(f"[CV Service] WARNING: Model tidak ditemukan di {MODEL_PATH}")
                    print("[CV Service] Fallback ke OpenCV-only mode")
    return _model


def scan_floorplan(file_bytes: bytes) -> dict | str:
    """
    Pipeline lengkap: validasi + deteksi ruangan.

    Args:
        file_bytes: bytes gambar dari request.files["image"].read()

    Returns:
        dict berisi hasil deteksi, atau string error code
    """
    # ─── Decode ───────────────────────────────
    image_array = np.frombuffer(file_bytes, np.uint8)
    image       = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

    if image is None:
        return "INVALID_IMAGE"

    # ─── Preprocessing OpenCV ─────────────────
    prep = preprocess_image(image, target_width=900)
    if prep is None:
        return "NO_LINES_DETECTED"

    # ─── Ekstraksi Fitur Visual ───────────────
    visual_features = extract_visual_features(prep)

    # ─── Gatekeeper CV Independen (kedua) ─────
    # Sinyal ini SEBELUMNYA sudah diimplementasikan di cv_utils.py
    # (compute_floorplan_signals + is_likely_floorplan) tapi tidak
    # pernah dipanggil di sini -> ini penyebab utama gambar random
    # (poster/motor/screenshot/foto orang) masih bisa lolos, karena
    # keputusan akhir hanya bergantung pada satu model AI.
    cv_signals = compute_floorplan_signals(image, prep, visual_features)
    cv_is_plan, cv_score, cv_reasons = is_likely_floorplan(cv_signals)

    # ─── Klasifikasi AI ───────────────────────
    model = get_model()
    ai_label      = "unknown"
    ai_confidence = 0.0
    ai_available  = model is not None

    if ai_available:
        # Resize untuk MobileNetV2
        img_for_model = cv2.resize(
            prep.resized,
            (IMG_SIZE, IMG_SIZE),
            interpolation=cv2.INTER_AREA
        )
        ai_label, ai_confidence = predict_single(model, img_for_model)
        

    # ─── Intelligent Gating ───────────────────
    is_valid, decision_reason = _intelligent_gate(
        ai_label, ai_confidence, visual_features, ai_available
    )

    # ─── Veto dari gatekeeper CV independen ───
    # Model AI dilatih dari dataset kecil (~200 gambar/kelas) dan
    # accuracy validasi 99% pada dataset SEKECIL itu rawan overfit ke
    # distribusi data latih -> tidak menjamin generalisasi ke foto
    # random dunia nyata. cv_is_plan tidak bergantung pada model AI
    # sama sekali (warna & orientasi garis), jadi dipakai sebagai
    # veto satu arah: kalau AI bilang "valid" tapi sinyal CV sangat
    # tidak meyakinkan sebagai denah, tetap tolak (fail-closed).
    if is_valid and not cv_is_plan:
        is_valid = False
        decision_reason = "cv_gatekeeper_reject"

    print("\n========== AI DEBUG ==========")
    print("AI Label      :", ai_label)
    print("AI Confidence :", ai_confidence)
    print("Visual Feature:", visual_features)
    print("CV Gatekeeper :", cv_is_plan, "score=", round(cv_score, 3), cv_reasons)
    print("Decision      :", decision_reason)
    print("Valid         :", is_valid)
    print("==============================\n")

    if not is_valid:
        return {
            "valid": False,
            "ai_label": ai_label,
            "ai_confidence": round(ai_confidence, 4),
            "decision_reason": decision_reason,
            "visual_features": visual_features,
            "cv_gatekeeper_score": round(cv_score, 4),
            "rooms": [],
            "total_rooms": 0,
            "image_width": prep.crop_w,
            "image_height": prep.crop_h,
        }

    # ─── Deteksi Ruangan ─────────────────────
    rooms = detect_rooms(prep)

    rooms_output = [
        {
            "name": r.name,
            "x": r.x,
            "y": r.y,
            "width": r.width,
            "height": r.height,
            "confidence": round(r.confidence, 3),
        }
        for r in rooms
    ]

    return {
        "valid": True,
        "ai_label": ai_label,
        "ai_confidence": round(ai_confidence, 4),
        "decision_reason": decision_reason,
        "visual_features": visual_features,
        "total_rooms": len(rooms_output),
        "image_width": prep.crop_w,
        "image_height": prep.crop_h,
        "rooms": rooms_output,
        "debug": {
            "method": "mobilenetv2_opencv_hybrid",
            "original_width":  prep.original_w,
            "original_height": prep.original_h,
            "target_width":    prep.target_w,
            "target_height":   prep.target_h,
            "crop_x":  prep.crop_x1,
            "crop_y":  prep.crop_y1,
            "crop_width":  prep.crop_w,
            "crop_height": prep.crop_h,
        }
    }


def _intelligent_gate(
    ai_label: str,
    ai_confidence: float,
    features: dict,
    ai_available: bool,
) -> tuple[bool, str]:

    line_density = features.get("line_density", 0)
    corner_density = features.get("corner_density", 0)
    rect_score = features.get("rectangularity", 0)

    # =====================================================
    # TANPA AI -> TOLAK SEMUA
    # =====================================================
    if not ai_available:
        return False, "ai_unavailable_fail_closed"

    # =====================================================
    # AI BILANG BUKAN FLOORPLAN -> LANGSUNG TOLAK
    # =====================================================
    if ai_label == "not_floorplan":
        return False, "ai_negative"

    # =====================================================
    # AI RAGU-RAGU -> TOLAK
    # =====================================================
    if ai_confidence < AI_CONFIDENCE_THRESHOLD:
        return False, "ai_uncertain"

    # =====================================================
    # AI CONFIDENT FLOORPLAN
    # CEK STRUKTUR VISUAL SEBAGAI FILTER TAMBAHAN
    # =====================================================
    if line_density < LINE_DENSITY_THRESHOLD:
        return False, "low_line_density"

    if corner_density < CORNER_DENSITY_THRESHOLD:
        return False, "low_corner_density"

    if rect_score < MIN_RECTANGULARITY:
        return False, "low_rectangularity"

    # =====================================================
    # SEMUA LOLOS
    # =====================================================
    return True, "ai_confident_positive"
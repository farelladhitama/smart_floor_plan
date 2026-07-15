"""
Pre-validation cepat sebelum inferensi model berat.
Filter gambar jelas tidak valid tanpa memanggil neural network.
Ini menghemat ~200ms per request untuk gambar invalid.
"""

import cv2
import numpy as np


class ImageValidator:
    """
    Validasi ringan berbasis aturan sebelum memanggil AI model.
    
    Checks:
    1. Ukuran minimum — terlalu kecil tidak mungkin denah detail
    2. Rasio warna putih — denah harus dominan putih (latar)
    3. Variance piksel — gambar solid/blank tidak bermanfaat
    4. Presence of edges — harus ada garis/kontur
    """

    MIN_WIDTH  = 100
    MIN_HEIGHT = 100
    MIN_WHITE_RATIO = 0.20    # Minimal 20% piksel putih
    MAX_WHITE_RATIO = 0.97    # Maksimal 97% (hampir kosong)
    MIN_EDGE_DENSITY = 0.005  # Minimal 0.5% piksel tepi
    MIN_VARIANCE = 100.0      # Minimal variance (bukan gambar solid)

    def validate(self, image: np.ndarray) -> tuple[bool, str]:
        """
        Returns:
            (is_valid, reason)
        """
        h, w = image.shape[:2]

        # Check 1: Ukuran minimum
        if w < self.MIN_WIDTH or h < self.MIN_HEIGHT:
            return False, f"Gambar terlalu kecil ({w}x{h}). Minimal {self.MIN_WIDTH}x{self.MIN_HEIGHT}."

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Check 2: Rasio piksel putih
        white_pixels = np.sum(gray > 220)
        white_ratio  = white_pixels / (h * w)
        if white_ratio < self.MIN_WHITE_RATIO:
            return False, f"Gambar terlalu gelap (white_ratio={white_ratio:.2f}). Denah biasanya berlatar putih."
        if white_ratio > self.MAX_WHITE_RATIO:
            return False, f"Gambar terlalu kosong (white_ratio={white_ratio:.2f}). Tidak ada konten terdeteksi."

        # Check 3: Variance (gambar solid/blank)
        variance = float(np.var(gray))
        if variance < self.MIN_VARIANCE:
            return False, f"Gambar tidak memiliki variasi konten (variance={variance:.1f})."

        # Check 4: Edge density
        edges        = cv2.Canny(gray, 50, 150)
        edge_pixels  = np.count_nonzero(edges)
        edge_density = edge_pixels / (h * w)
        if edge_density < self.MIN_EDGE_DENSITY:
            return False, f"Hampir tidak ada tepi/garis (edge_density={edge_density:.4f}). Denah harus memiliki garis jelas."

        return True, "ok"


# Singleton
_validator = ImageValidator()


def quick_validate(image: np.ndarray) -> tuple[bool, str]:
    """Fungsi shortcut untuk validasi cepat."""
    return _validator.validate(image)
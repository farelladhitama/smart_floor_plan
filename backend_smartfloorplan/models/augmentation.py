"""
Data augmentation untuk memperkuat generalisasi model.
Denah bisa datang dalam berbagai orientasi, kualitas scan,
dan kondisi pencahayaan — augmentasi mempersiapkan model
untuk semua variasi tersebut.
"""

import tensorflow as tf

def build_augmentation_layer():
    """
    Sequential augmentation layer yang di-apply saat training.
    Nilai dipilih konservatif agar tidak merusak struktur garis denah.
    """
    return tf.keras.Sequential([
        # Flip horizontal — denah bisa mirror
        tf.keras.layers.RandomFlip("horizontal"),

        # Rotasi ±15° — denah tidak selalu tegak lurus sempurna
        tf.keras.layers.RandomRotation(0.04),

        # Zoom ringan — variasi jarak scan
        tf.keras.layers.RandomZoom(0.1),

        # Brightness — variasi kualitas scan/foto
        tf.keras.layers.RandomBrightness(0.15),

        # Contrast — variasi kualitas printer/scanner
        tf.keras.layers.RandomContrast(0.15),
    ], name="augmentation")
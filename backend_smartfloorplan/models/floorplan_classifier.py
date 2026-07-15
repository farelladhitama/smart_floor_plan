"""
FloorPlan Classifier berbasis MobileNetV2

Arsitektur:
    ImageNet Pretrained MobileNetV2 (feature extractor, frozen)
    → GlobalAveragePooling2D
    → Dense(128, relu) + Dropout(0.4)
    → Dense(64, relu) + Dropout(0.3)
    → Dense(1, sigmoid)   ← binary: floorplan / not_floorplan

Alasan MobileNetV2:
    - Ringan: 3.4M parameter vs ResNet50 (25M)
    - Cocok untuk deployment ke Render/cloud terbatas
    - Akurasi tinggi untuk binary classification sederhana
    - Transfer learning dari ImageNet sangat efektif
      karena fitur tepi & tekstur relevan untuk denah
"""

import tensorflow as tf
from tensorflow.keras import layers, Model
from tensorflow.keras.applications import MobileNetV2


IMG_SIZE    = 224
NUM_CLASSES = 1   
MODEL_THRESHOLD = 0.96      
DROPOUT_1   = 0.4
DROPOUT_2   = 0.3
DENSE_1     = 128
DENSE_2     = 64


def build_classifier(trainable_base: bool = False) -> Model:
    """
    Bangun model classifier.

    Args:
        trainable_base: False = frozen (Phase 1 training)
                        True  = fine-tune top layers (Phase 2)
    Returns:
        Compiled Keras Model
    """
    # Base model: MobileNetV2 pretrained ImageNet
    base = MobileNetV2(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,           # Hapus dense head asli
        weights="imagenet"
    )
    base.trainable = trainable_base  # Freeze semua layer base

    # Fine-tune: unfreeze hanya 30 layer terakhir
    if trainable_base:
        for layer in base.layers[:-30]:
            layer.trainable = False

    # Input
    inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3), name="image_input")

    # Normalisasi: [0,255] → [-1,1] (sesuai preprocessing MobileNetV2)
    x = tf.keras.layers.Rescaling(1.0 / 127.5, offset=-1.0, name="rescaling")(inputs)

    # Feature extraction
    x = base(x, training=False)

    # Classification head
    x = layers.GlobalAveragePooling2D(name="gap")(x)
    x = layers.Dense(DENSE_1, activation="relu", name="dense_1")(x)
    x = layers.Dropout(DROPOUT_1, name="dropout_1")(x)
    x = layers.Dense(DENSE_2, activation="relu", name="dense_2")(x)
    x = layers.Dropout(DROPOUT_2, name="dropout_2")(x)
    outputs = layers.Dense(NUM_CLASSES, activation="sigmoid", name="output")(x)

    model = Model(inputs, outputs, name="FloorPlanClassifier")

    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
        loss="binary_crossentropy",
        metrics=[
            "accuracy",
            tf.keras.metrics.Precision(name="precision"),
            tf.keras.metrics.Recall(name="recall"),
            tf.keras.metrics.AUC(name="auc"),
        ]
    )

    return model


def load_trained_model(path: str = "models/saved/classifier_v1.h5") -> Model:
    """
    Load model terlatih dari disk.
    """
    return tf.keras.models.load_model(path)


def predict_single(
    model: Model,
    image_rgb: "np.ndarray"
) -> tuple[str, float]:

    img = tf.image.resize(image_rgb, [IMG_SIZE, IMG_SIZE])
    img = tf.expand_dims(img, axis=0)

    prob = float(model.predict(img, verbose=0)[0][0])

    label = (
        "floorplan"
        if prob >= MODEL_THRESHOLD
        else "not_floorplan"
    )

    return label, prob
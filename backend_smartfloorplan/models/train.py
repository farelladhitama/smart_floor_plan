"""
Training pipeline dua fase untuk FloorPlan Classifier.

FASE 1 (Epoch 0–20):
    Base MobileNetV2 FROZEN.
    Hanya melatih classification head.
    LR tinggi: 1e-3

FASE 2 (Epoch 20–40):
    Unfreeze 30 layer terakhir MobileNetV2.
    Fine-tune seluruh network.
    LR rendah: 1e-5 (mencegah catastrophic forgetting)

Strategi ini menghasilkan akurasi lebih tinggi
dibanding fine-tune langsung dari awal.
"""

import os
import tensorflow as tf
import matplotlib.pyplot as plt
from floorplan_classifier import build_classifier, IMG_SIZE

# ─────────────────────────
# KONFIGURASI
# ─────────────────────────
DATASET_DIR  = "dataset"
SAVE_PATH    = "models/saved/classifier_v1.h5"
BATCH_SIZE   = 32
PHASE1_EPOCH = 20
PHASE2_EPOCH = 20
SEED         = 42


def build_datasets():
    """Buat train & val dataset dari folder."""
    train_ds = tf.keras.utils.image_dataset_from_directory(
        os.path.join(DATASET_DIR, "train"),
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        label_mode="binary",
        shuffle=True,
        seed=SEED,
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        os.path.join(DATASET_DIR, "val"),
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        label_mode="binary",
        shuffle=False,
        seed=SEED,
    )

    # Prefetch untuk performa GPU/CPU
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
    val_ds   = val_ds.prefetch(buffer_size=AUTOTUNE)

    # Augmentasi hanya di training set
    from augmentation import build_augmentation_layer
    aug = build_augmentation_layer()

    def apply_aug(images, labels):
        images = aug(images, training=True)
        return images, labels

    train_ds = train_ds.map(apply_aug, num_parallel_calls=AUTOTUNE)

    return train_ds, val_ds


def build_callbacks(phase: int) -> list:
    """Callbacks untuk monitoring dan early stopping."""
    return [
        tf.keras.callbacks.EarlyStopping(
            monitor="val_auc",
            patience=5,
            restore_best_weights=True,
            mode="max",
            verbose=1,
        ),
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=3,
            min_lr=1e-7,
            verbose=1,
        ),
        tf.keras.callbacks.ModelCheckpoint(
            filepath=f"models/saved/ckpt_phase{phase}.h5",
            monitor="val_auc",
            save_best_only=True,
            mode="max",
            verbose=1,
        ),
        tf.keras.callbacks.TensorBoard(
            log_dir=f"logs/phase{phase}",
            histogram_freq=1,
        ),
    ]


def plot_history(h1, h2, save_path="training_history.png"):
    """Plot training curves kedua fase."""
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle("Training History — SmartFloorPlan Classifier", fontsize=14)

    metrics = ["loss", "accuracy", "auc", "precision"]
    titles  = ["Loss", "Accuracy", "AUC", "Precision"]

    for ax, metric, title in zip(axes.flat, metrics, titles):
        # Phase 1
        p1_train = h1.history.get(metric, [])
        p1_val   = h1.history.get(f"val_{metric}", [])
        # Phase 2 (offset epoch)
        p2_train = h2.history.get(metric, [])
        p2_val   = h2.history.get(f"val_{metric}", [])

        offset = len(p1_train)
        ax.plot(p1_train, label="Phase1 Train")
        ax.plot(p1_val,   label="Phase1 Val")
        ax.plot(range(offset, offset + len(p2_train)), p2_train, "--", label="Phase2 Train")
        ax.plot(range(offset, offset + len(p2_val)),   p2_val,   "--", label="Phase2 Val")
        ax.set_title(title)
        ax.legend(fontsize=8)
        ax.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(save_path, dpi=120)
    print(f"Training history tersimpan: {save_path}")


def train():
    os.makedirs("models/saved", exist_ok=True)
    os.makedirs("logs",         exist_ok=True)

    print("=" * 60)
    print("FASE 1: Training classification head (base frozen)")
    print("=" * 60)

    train_ds, val_ds = build_datasets()

    # FASE 1: Base frozen
    model = build_classifier(trainable_base=False)
    model.summary()

    history1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=PHASE1_EPOCH,
        callbacks=build_callbacks(phase=1),
    )

    # FASE 2: Fine-tune
    print("\n" + "=" * 60)
    print("FASE 2: Fine-tuning (unfreeze 30 layer terakhir MobileNetV2)")
    print("=" * 60)

    # Rebuild dengan base trainable, load bobot fase 1
    model_ft = build_classifier(trainable_base=True)
    model_ft.set_weights(model.get_weights())

    # LR jauh lebih kecil untuk fase fine-tune
    model_ft.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
        loss="binary_crossentropy",
        metrics=[
            "accuracy",
            tf.keras.metrics.Precision(name="precision"),
            tf.keras.metrics.Recall(name="recall"),
            tf.keras.metrics.AUC(name="auc"),
        ]
    )

    history2 = model_ft.fit(
        train_ds,
        validation_data=val_ds,
        epochs=PHASE2_EPOCH,
        callbacks=build_callbacks(phase=2),
    )

    # Simpan model final
    model_ft.save(SAVE_PATH)
    print(f"\nModel tersimpan: {SAVE_PATH}")

    plot_history(history1, history2)

    # Print metrik final
    results = model_ft.evaluate(val_ds, verbose=0)
    metrics = ["loss", "accuracy", "precision", "recall", "auc"]
    print("\n=== HASIL EVALUASI FASE 2 ===")
    for m, v in zip(metrics, results):
        print(f"  {m:12s}: {v:.4f}")


if __name__ == "__main__":
    train()
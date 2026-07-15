"""
Evaluasi model pada validation set.
Menghasilkan:
- Classification report
- Confusion matrix
- ROC Curve
- Sample predictions
"""

import os
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    roc_curve,
    auc,
)
from floorplan_classifier import load_trained_model, IMG_SIZE

DATASET_DIR = "dataset/val"
MODEL_PATH  = "models/saved/classifier_v1.h5"
BATCH_SIZE  = 32


def evaluate():
    # Load model
    model = load_trained_model(MODEL_PATH)

    # Load val dataset
    val_ds = tf.keras.utils.image_dataset_from_directory(
        DATASET_DIR,
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE,
        label_mode="binary",
        shuffle=False,
    )

    # Prediksi semua
    y_true, y_pred_prob = [], []
    for images, labels in val_ds:
        preds = model.predict(images, verbose=0)
        y_true.extend(labels.numpy().flatten())
        y_pred_prob.extend(preds.flatten())

    y_true      = np.array(y_true)
    y_pred_prob = np.array(y_pred_prob)
    y_pred      = (y_pred_prob >= 0.5).astype(int)

    # ─── Classification Report ───────────────
    print("=" * 60)
    print("CLASSIFICATION REPORT")
    print("=" * 60)
    print(classification_report(y_true, y_pred, target_names=["not_floorplan", "floorplan"]))

    # ─── Confusion Matrix ────────────────────
    cm = confusion_matrix(y_true, y_pred)
    print("Confusion Matrix:")
    print(f"  TN={cm[0,0]:4d}  FP={cm[0,1]:4d}")
    print(f"  FN={cm[1,0]:4d}  TP={cm[1,1]:4d}")

    # ─── ROC Curve ───────────────────────────
    fpr, tpr, thresholds = roc_curve(y_true, y_pred_prob)
    roc_auc = auc(fpr, tpr)

    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, color="darkorange", lw=2,
             label=f"ROC curve (AUC = {roc_auc:.3f})")
    plt.plot([0, 1], [0, 1], color="navy", lw=1, linestyle="--")
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("ROC Curve — FloorPlan Classifier")
    plt.legend(loc="lower right")
    plt.grid(True, alpha=0.3)
    plt.savefig("roc_curve.png", dpi=120)
    print(f"\nROC AUC: {roc_auc:.4f}")
    print("ROC curve tersimpan: roc_curve.png")

    # ─── Cari threshold optimal ──────────────
    optimal_idx = np.argmax(tpr - fpr)
    optimal_threshold = thresholds[optimal_idx]
    print(f"\nThreshold optimal: {optimal_threshold:.4f}")
    print(f"TPR pada threshold optimal: {tpr[optimal_idx]:.4f}")
    print(f"FPR pada threshold optimal: {fpr[optimal_idx]:.4f}")

    return {
        "roc_auc": roc_auc,
        "optimal_threshold": float(optimal_threshold),
        "confusion_matrix": cm.tolist(),
    }


if __name__ == "__main__":
    evaluate()
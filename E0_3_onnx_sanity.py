#!/usr/bin/env python3
"""
E0.3 — QONNX Model Sanity Check (onnxruntime inference)
Track E, Project STREAMSENSE

What this script does (in plain English):
    Track A gave us an ONNX model file (streamsense_model_fp32.onnx).
    This script:
        1. Loads the model using onnxruntime
        2. Takes each of the 10 golden normalized tensors (already computed
           by Track A as ground truth)
        3. Feeds them into the model
        4. Checks that the top-1 predicted label matches the expected label
           (yes/no/up/down/left/right/on/off/stop/go)

    If all 10 predictions are correct → E0.3 PASS.
    The model is working correctly and we can use it.

Requirements:
    pip install onnxruntime numpy

Usage:
    python3 E0_3_onnx_sanity.py

    Run from the folder containing deployment_package/
"""

import sys, json, numpy as np
from pathlib import Path

DEPLOY_DIR = Path("deployment_package")
LABELS = ['yes','no','up','down','left','right','on','off','stop','go']

try:
    import onnxruntime as ort
except ImportError:
    print("ERROR: onnxruntime not installed.")
    print("Run:   pip install onnxruntime")
    sys.exit(1)


def main():
    model_path = DEPLOY_DIR / "models" / "streamsense_model_fp32.onnx"
    if not model_path.exists():
        print(f"ERROR: model not found at {model_path}")
        sys.exit(1)

    # Load the ONNX model
    # onnxruntime is like a player for the AI model file
    sess = ort.InferenceSession(str(model_path))
    input_name  = sess.get_inputs()[0].name    # "input"
    output_name = sess.get_outputs()[0].name   # "logits"

    print("=" * 65)
    print("E0.3 — QONNX Model Sanity Check (FP32)")
    print("=" * 65)
    print(f"Model:        {model_path.name}")
    print(f"Input name:   {input_name}  shape: {sess.get_inputs()[0].shape}")
    print(f"Output name:  {output_name}  shape: {sess.get_outputs()[0].shape}")
    print()

    gv_dir   = DEPLOY_DIR / "golden_vectors"
    all_pass = True

    for i, label in enumerate(LABELS):
        name = f"GV_{i:02d}_{label}"

        # Load normalized tensor from golden vectors
        # Shape: (64, 97) — needs to be reshaped to (1, 1, 64, 97) for the model
        norm = np.frombuffer(
            open(gv_dir / "normalized" / f"{name}_norm.bin", "rb").read(),
            dtype=np.float32).reshape(1, 1, 64, 97)

        # Run inference
        # The model takes [1, 1, 64, 97] and outputs [1, 10] (10 class scores)
        outputs = sess.run([output_name], {input_name: norm})
        logits  = outputs[0][0]          # shape (10,) — one score per class

        # Top-1 = class with the highest score
        top1_idx   = int(np.argmax(logits))
        top1_label = LABELS[top1_idx]
        correct    = (top1_idx == i)

        if not correct:
            all_pass = False

        status = "PASS" if correct else "FAIL"
        score_str = "  ".join(f"{LABELS[j]}:{logits[j]:.2f}" for j in range(10))
        print(f"  [{i}] {name:18s}  "
              f"top1={top1_label:5s} (idx={top1_idx})  "
              f"expected={label:5s}  → {status}")

    print()
    print("=" * 65)
    if all_pass:
        print("RESULT: ALL 10 TOP-1 LABELS CORRECT ✓")
        print("        FP32 model produces expected predictions on all golden vectors")
        print("        E0.3 COMPLETE")
    else:
        print("RESULT: FAIL — some predictions do not match expected labels")
    print("=" * 65)
    return all_pass


if __name__ == "__main__":
    ok = main()
    sys.exit(0 if ok else 1)

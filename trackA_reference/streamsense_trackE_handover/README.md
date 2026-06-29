# STREAMSENSE — Track E Handover Package

**From:** Ksheeraja (Track A — Host Model, Preprocessing & Feature Engine)
**To:** Prikshit (Track E — Acceleration Path / FINN Flow)
**Date:** 2026-06-24
**Document:** OSL-PRG-2026-SE-WPA Rev 2.0 · Scope 2 QONNX Extension

---

## What is in this package

This package directly answers your Track E requirements email (22 Jun 2026):

| Your request | Delivered as |
|---|---|
| QONNX model file (*.qonnx) | `models/streamsense_multihead.qonnx` |
| FP32 ONNX model file (*.onnx) | `models/streamsense_multihead_fp32.onnx` |
| Expected top-1 output/class for each golden vector | `golden_vectors/manifest.json` → `expected_top1_index` field per vector |
| Python preprocessing/reference implementation | `preprocessing/mel_pipeline.py` |

Additionally included for your E0.3 and E3 integration work:
- The 10 hand-picked golden vectors in all three forms: raw, mel, and normalized
- Machine-readable MPIC v1.0 spec (`config/mpic_v1.0.json`)
- Normalization statistics (`config/normalization_stats.json`)
- Class label mapping (`config/class_labels.json`)
- QONNX GV1K gate evaluation report (1000 vectors, ≥90% threshold)
- Full test-set accuracy report (FP32 and INT8, 5779 samples)

---

## Folder structure

```
streamsense_trackE_handover/
├── models/
│   ├── streamsense_multihead.qonnx          ← QONNX (FINN target, Brevitas QAT)
│   └── streamsense_multihead_fp32.onnx      ← FP32 reference (OnnxRuntime)
├── golden_vectors/
│   ├── raw/           GV_0X_<label>.bin          10 files, float32 [16000]
│   ├── mel/           GV_0X_<label>_mel.bin       10 files, float32 [64, 97]
│   ├── normalized/    GV_0X_<label>_norm.bin      10 files, float32 [64, 97]  ← feed to model
│   └── manifest.json                              expected_top1_index populated
├── preprocessing/
│   └── mel_pipeline.py                            MPIC v1.0 reference impl
├── config/
│   ├── class_labels.json
│   ├── normalization_stats.json
│   └── mpic_v1.0.json                             machine-readable full spec
├── evaluation/
│   ├── qonnx_evaluation_report.txt                QONNX GV1K gate result
│   └── multihead_onnx_evaluation_report.txt       FP32+INT8 test-set accuracy
├── manifest.json                                  package inventory
└── README.md                                      this file
```

---

## Model I/O contract — ERR v1.0 (frozen)

Both the QONNX and FP32 models implement the same three-output contract.

### Input

| Name | Shape | dtype | Notes |
|---|---|---|---|
| `input` | `[1, 1, 64, 97]` | float32 | MPIC v1.0 normalised log-mel spectrogram. **Fully static — no dynamic axes.** |

### Outputs

| Name | Shape | dtype | Description |
|---|---|---|---|
| `logits` | `[1, 10]` | float32 | Raw classifier logits. Apply softmax externally for probabilities. |
| `embedding` | `[1, 128]` | float32 | Linear projection of 128-dim GAP feature vector. For Track C ANN index. |
| `novelty_score` | `[1, 1]` | float32 | 1 − max(softmax(logits)). Bounded [0, 1]. **Must stay 2-D `[1,1]`, never squeeze.** |

### Class index mapping (logits axis 1)

```
0=yes  1=no  2=up  3=down  4=left  5=right  6=on  7=off  8=stop  9=go
```

### ⚠ QONNX-specific note — output names

When loading `streamsense_multihead.qonnx` via the **qonnx runtime**, the output
node names in the graph are auto-generated integers (e.g. `'143'`, `'147'`), not
the human-readable strings above. **Always access outputs by index (0, 1, 2),
not by name string.** The FP32 `.onnx` model uses named outputs and can be
accessed by name via OnnxRuntime.

```python
# QONNX — correct access pattern (qonnx executor)
from qonnx.core.modelwrapper import ModelWrapper
from qonnx.core.onnx_exec import execute_onnx
from qonnx.transformation.infer_shapes import InferShapes
import numpy as np

model = ModelWrapper('models/streamsense_multihead.qonnx')
model = model.transform(InferShapes())   # MANDATORY before execute_onnx

input_name   = model.graph.input[0].name
output_names = [o.name for o in model.graph.output]

inp   = np.fromfile('golden_vectors/normalized/GV_00_yes_norm.bin', dtype='<f4').reshape(1,1,64,97)
odict = execute_onnx(model, {input_name: inp})

logits        = odict[output_names[0]]   # [1, 10]
embedding     = odict[output_names[1]]   # [1, 128]
novelty_score = odict[output_names[2]]   # [1,  1]
pred_class    = int(np.argmax(logits[0]))
print(f"Predicted: {pred_class} ({['yes','no','up','down','left','right','on','off','stop','go'][pred_class]})")
```

```python
# FP32 ONNX — access by name via OnnxRuntime
import onnxruntime as ort
import numpy as np

session = ort.InferenceSession('models/streamsense_multihead_fp32.onnx')
inp     = np.fromfile('golden_vectors/normalized/GV_00_yes_norm.bin', dtype='<f4').reshape(1,1,64,97)
results = session.run(['logits', 'embedding', 'novelty_score'], {'input': inp})
logits, embedding, novelty_score = results
pred_class = int(np.argmax(logits[0]))
```

---

## Golden vectors — what they are and how to use them

The `golden_vectors/` folder contains the **10 hand-picked reference inputs**,
one per class, used as the integration acceptance gate.

### Expected top-1 predictions

These are in `golden_vectors/manifest.json` under the `expected_top1_index` field.
Quick reference:

| Vector | True class | expected_top1_index | expected_top1_label |
|---|---|---|---|
| GV_00_yes   | yes   | Read from manifest.json | Read from manifest.json |
| GV_01_no    | no    | Read from manifest.json | Read from manifest.json |
| GV_02_up    | up    | Read from manifest.json | Read from manifest.json |
| GV_03_down  | down  | Read from manifest.json | Read from manifest.json |
| GV_04_left  | left  | Read from manifest.json | Read from manifest.json |
| GV_05_right | right | Read from manifest.json | Read from manifest.json |
| GV_06_on    | on    | Read from manifest.json | Read from manifest.json |
| GV_07_off   | off   | Read from manifest.json | Read from manifest.json |
| GV_08_stop  | stop  | Read from manifest.json | Read from manifest.json |
| GV_09_go    | go    | Read from manifest.json | Read from manifest.json |

The `expected_top1_index` values were generated by running the FP32 multihead
ONNX model (the canonical authority) on the normalized binary files.

### Binary file spec

| Property | Value |
|---|---|
| dtype | float32 |
| endianness | little-endian |
| layout | row-major C order |
| raw shape | [16000] = 64000 bytes |
| mel/norm shape | [64, 97] = 24832 bytes |
| feed to model as | reshape to [1, 1, 64, 97] |

### How to load and feed a normalized GV

```python
import numpy as np

gv = np.fromfile('golden_vectors/normalized/GV_00_yes_norm.bin', dtype='<f4')
assert gv.size == 64 * 97   # 6208 floats = 24832 bytes
inp = gv.reshape(1, 1, 64, 97)   # ready to feed to model
```

The normalized GVs are **already fully preprocessed** — do not apply the MPIC
pipeline again. Feed them directly to the model input.

---

## Preprocessing pipeline — MPIC v1.0

If you need to preprocess new raw audio, use `preprocessing/mel_pipeline.py`.

### Quick reference

```python
import numpy as np
from preprocessing.mel_pipeline import preprocess  # or sys.path.insert(0, 'preprocessing')

# raw: float32 numpy array, [16000] samples (1 second @ 16 kHz)
inp = preprocess(raw)   # returns np.ndarray [1, 1, 64, 97] float32
```

### Frozen parameters (from `config/mpic_v1.0.json`)

| Parameter | Value | Notes |
|---|---|---|
| Sample rate | 16 000 Hz | |
| Frame length | 16 000 samples | Pad right with zeros / crop right |
| n_fft | 512 | |
| hop_length | 160 | 10 ms stride |
| n_mels | 64 | |
| **center** | **False** | **Critical — gives T=97, not T=98** |
| power | 2.0 | power spectrogram |
| window | Hann (periodic) | |
| Log scaling | 10 × log₁₀(mel + 1e-10) | |
| Floor clip | −80.0 dB | |
| global_mean | **−30.785545 dB** | From `config/normalization_stats.json` |
| global_std | **22.157099 dB** | From `config/normalization_stats.json` |
| Normalisation | (mel − global_mean) / global_std | |
| Output shape | [1, 1, 64, 97] float32 | |

Expected T = (16000 − 512) / 160 + 1 = **97**

---

## Model accuracy

### QONNX model (streamsense_multihead.qonnx)

- Architecture: StreamSenseWrapper (Brevitas QAT — Int8 weights + activations)
- GV1K gate (1000 vectors, 100 per class from Speech Commands v2 test split):
  see `evaluation/qonnx_evaluation_report.txt`
- Pass threshold: **≥90.0% top-1 accuracy**
- Format: QONNX (Brevitas custom ops). **Do NOT load with vanilla onnxruntime.**
  Use the `qonnx` executor: `pip install qonnx`

### FP32 ONNX model (streamsense_multihead_fp32.onnx)

- Architecture: StreamSenseWrapper (FP32, all 3 heads, MPIC v1.0 + ERR v1.0)
- Test accuracy: **95.97%** (5546/5779, Speech Commands v2 test split)
- Opset: 17 (fully static — no dynamic axes)
- GV1K: 1000/1000 pipeline parity PASS (max absolute error = 0.00e+00)
- Runtime: OnnxRuntime (`pip install onnxruntime`)
- Full report: `evaluation/multihead_onnx_evaluation_report.txt`

---

## Known limitations

**Embedding head is untrained.** The `embed_head` (`nn.Linear(128,128)`) is
Xavier-uniform initialised and has not been fine-tuned on labelled data. The
shape contract (`[1, 128]`) is met and the output is structurally valid, but the
embedding space is not semantically meaningful for fingerprint matching until
QAT fine-tuning is complete. This does not affect logit-based classification.

**INT8 novelty_score stays FP32 internally.** The Softmax + ReduceMax + Sub ops
are kept at FP32 by ORT's default exclude list. This is correct and intentional —
the output tensor is still `float32 [1,1]`.

---

## MPIC v1.0 and ERR v1.0 version guard

Both contracts are frozen. Any change requires an explicit version bump and
Track A sign-off. If you find a mismatch between this package and the FINN
flow requirements, raise it with Track A (Ksheeraja) before proceeding.

---

## Questions

Contact: **Ksheeraja (Track A)** — bodasingiksheeraja.osl@outlook.com

*Package assembled: 2026-06-24 15:38:51*
*Assembler: training/assemble_trackE_handover.py*

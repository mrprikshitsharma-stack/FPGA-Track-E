# E0.4 — On-Target Source Swap-Point Note
**Track E, Project STREAMSENSE**
**Document:** OSL-PRG-2026-SE-WPE-E0.4
**Date:** June 2026

---

## 1. What is the "Swap Point"?

During the **software sprint** (Days 1–15), the audio signal source
is a **TCP/IP stream** implemented by Track B. Audio frames arrive over
a network connection as NSP v1.2 packets.

After the sprint, when running on real FPGA hardware (**post-sprint
hardware phase**), the TCP/IP source is **replaced** by a physical
hardware interface — a microphone, ADC, or other sensor connected
directly to the Zynq-7000 board.

The **swap point** is the exact software/hardware boundary where this
replacement happens — the interface that both the current TCP source
and the future hardware source must present identically, so that
everything downstream (feature extraction, AI inference) does not
change at all.

---

## 2. Current Software Path (Sprint)

```
Microphone/signal source (remote)
        ↓
  TCP/IP network (NSP v1.2)
        ↓
  nsp_receiver.py (Track B)    ← software swap point
        ↓
  Raw audio frame: float32[16000]
        ↓
  mel_pipeline.py (MPIC preprocessing)
        ↓
  Tensor [1, 1, 64, 97] float32
        ↓
  ONNX model (onnxruntime on CPU)
        ↓
  Top-1 label
```

---

## 3. Post-Sprint Hardware Path

```
On-board sensor (microphone/ADC)
        ↓
  Hardware driver (P5 — freelancer)
        ↓
  AXI4-Stream @ 16 kHz         ← hardware swap point
        ↓
  HLS feature-extraction block (PL)
        ↓
  AXI-DMA → DDR               (PL → PS)
        ↓
  ARM Linux userspace
        ↓
  FINN inference accelerator (PL)
        ↓
  Top-1 label
```

---

## 4. The Swap Point Interface Definition

The swap point is the **raw audio frame buffer** handed off from the
signal source to the preprocessing stage. Both the TCP receiver and
the hardware driver must deliver:

| Field | Value |
|---|---|
| Data type | float32 (little-endian) |
| Frame length | 16,000 samples (exactly 1 second at 16 kHz) |
| Sample range | approximately [-1.0, +1.0] (normalized) |
| Layout | 1D contiguous array, mono (single channel) |
| NSP header field | dtype=0x03 (FLOAT32), frame_length=16000 |

In the NSP v1.2 protocol this corresponds to:
- `payload_bytes = 64,000` (16,000 samples × 4 bytes each)
- `sample_rate = 16000`
- `dtype = 0x03` (FLOAT32)

**Nothing downstream of this interface changes between sprint and
post-sprint.** The mel_pipeline.py / HLS feature block receives the
same float32[16000] buffer regardless of whether it came from TCP or
from a hardware ADC.

---

## 5. What the Hardware Driver Must Implement (P5)

When the on-target source driver is provided (prerequisite P5,
assigned to freelancer / mentor), it must:

1. Sample audio at **exactly 16,000 Hz**
2. Accumulate exactly **16,000 samples** per frame
3. Normalize to **float32 in [-1.0, +1.0]** range
4. **For the software path:** pack into an NSP v1.2 packet and send
   over TCP to the receiver
5. **For the hardware path:** write to an AXI4-Stream DMA buffer in
   the Zynq PS DDR, then signal the feature-extraction PL block via
   the AXI-DMA interrupt

The swap point is therefore the **DMA buffer address + interrupt** on
hardware, replacing the **TCP socket `recv()` call** in software.

---

## 6. Interface Files from Track B

The following files in the deployment package implement the current
(software-sprint) side of the swap point:

| File | Role |
|---|---|
| `protocol/nsp_protocol.py` | NSP v1.2 header pack/unpack |
| `protocol/nsp_receiver.py` | TCP receiver — receives frames, validates header, extracts float32[16000] |
| `protocol/nsp_sender.py` | TCP sender — packs float32[16000] into NSP frame, transmits |
| `protocol/nsp_node.py` | Dual-role node (send + receive for loopback testing) |

---

## 7. Acceptance Criterion

E0.4 is complete when this document is reviewed and accepted by the
mentor, confirming that:

- The swap point interface is unambiguously defined
- The hardware driver spec (P5) is clear enough for the
  freelancer to implement
- Track E's HLS feature block and FINN accelerator require no
  changes when transitioning from TCP source to hardware source

---

*E0.4 COMPLETE*

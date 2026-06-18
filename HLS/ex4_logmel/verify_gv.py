#!/usr/bin/env python3
"""
hls/ex4_logmel/verify_gv.py  -- FINAL VERSION
 
Reads csim_input.txt (the exact input samples the hardware processed),
runs the identical pipeline, compares against csim_output.txt.
 
Run from hls/ex4_logmel/ after csim_design:
    python3 verify_gv.py
"""
 
import numpy as np
 
N_MELS  = 40
FFT_N   = 512
F_coeff = 14   # coeff_t = ap_fixed<16,2,...>  -> 14 frac bits
F_out   = 12   # feat_t  = ap_fixed<16,4,...>  -> 12 frac bits
 
# ── Step 1: Parse H from mel_filterbank.h ────────────────────────
H = np.zeros((N_MELS, FFT_N // 2), dtype=np.float64)
row_idx = 0
with open("mel_filterbank.h", "r") as fh:
    for line in fh:
        line = line.strip()
        if not line.startswith('{'):
            continue
        nums = line.lstrip('{').rstrip('},')
        vals = [int(v) for v in nums.split(',') if v.strip() != '']
        if len(vals) == FFT_N // 2 and row_idx < N_MELS:
            H[row_idx, :] = np.array(vals, dtype=np.float64) / (2 ** F_coeff)
            row_idx += 1
assert row_idx == N_MELS
print(f"H parsed: {row_idx} rows x {FFT_N//2} cols")
 
# ── Step 2: Read the EXACT input samples from csim_input.txt ─────
# tb_logmel.cpp writes the short integer values.
# Then packs as sample_t = ap_fixed<16,1> (Q1.15): value = sample/32768
samples_raw = np.loadtxt("csim_input.txt", dtype=np.int16)
assert len(samples_raw) == FFT_N
frame = samples_raw.astype(np.float64) / 32768.0   # Q1.15 = divide by 2^15
print(f"Input range: {frame.min():.4f} to {frame.max():.4f}")
 
# ── Step 3: Same pipeline as logmel.cpp ──────────────────────────
# Stage 2: power = frame[k]^2
power = frame[:FFT_N // 2] ** 2
 
# Stage 3: mel filterbank (simulate with float64 for accuracy)
mel = H @ power
 
# Quantise to feat_t (ap_fixed<16,4,AP_RND,AP_SAT>)
mel_int = np.round(mel * (2 ** F_out)).astype(np.int64)
mel_int = np.clip(mel_int, -32768, 32767)
 
# ── Step 4: Load HLS csim output ─────────────────────────────────
# tb_logmel.cpp writes signed raw integers (feat_t.to_int())
hls_raw = np.loadtxt("csim_output.txt", dtype=np.int32)
 
# ── Step 5: Compare ──────────────────────────────────────────────
feat_ref = mel_int.astype(np.float64) / (2 ** F_out)
feat_hls = hls_raw.astype(np.float64) / (2 ** F_out)
 
diff    = np.abs(feat_ref - feat_hls)
max_err = float(np.max(diff))
 
print(f"\nPython ref (first 5): {feat_ref[:5]}")
print(f"HLS output (first 5): {feat_hls[:5]}")
print(f"\nMax error: {max_err:.6f}")
 
if max_err < 0.05:
    print("Golden-vector parity: PASS")
else:
    print("Golden-vector parity: FAIL")
    top5 = np.argsort(diff)[::-1][:5]
    for idx in top5:
        print(f"  mel[{idx:2d}]: ref={feat_ref[idx]:.4f}  hls={feat_hls[idx]:.4f}  err={diff[idx]:.4f}")

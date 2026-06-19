#!/usr/bin/env python3
"""
hls/ex4_logmel/verify_gv.py
 
Compares csim_output.txt (HLS hardware output) against
csim_reference.txt (software reference computed by the same
testbench using identical ap_fixed arithmetic).
 
Both files are produced by the same C++ run (tb_logmel.cpp),
so they use the exact same input data and type arithmetic.
This guarantees the comparison is valid regardless of HLS
internal precision details.
 
Run from hls/ex4_logmel/ after csim_design:
    python3 verify_gv.py
"""
 
import numpy as np
import sys
 
F_out = 12  # feat_t = ap_fixed<16,4> -> 16-4 = 12 fractional bits
 
# Load HLS output (what the hardware computed)
try:
    hls_raw = np.loadtxt("csim_output.txt", dtype=np.int32)
except Exception as e:
    print(f"ERROR loading csim_output.txt: {e}")
    sys.exit(1)
 
# Load software reference (computed by same C++ testbench)
try:
    ref_raw = np.loadtxt("csim_reference.txt", dtype=np.int32)
except Exception as e:
    print(f"ERROR loading csim_reference.txt: {e}")
    sys.exit(1)
 
assert len(hls_raw) == 40, f"Expected 40 HLS values, got {len(hls_raw)}"
assert len(ref_raw) == 40, f"Expected 40 reference values, got {len(ref_raw)}"
 
# Convert raw integers to float for human-readable comparison
hls_float = hls_raw.astype(np.float64) / (2 ** F_out)
ref_float = ref_raw.astype(np.float64) / (2 ** F_out)
 
print("Software reference (first 5):", ref_float[:5])
print("HLS output        (first 5):", hls_float[:5])
 
# Compare
diff    = np.abs(ref_float - hls_float)
max_err = float(np.max(diff))
 
print(f"\nMax error: {max_err:.6f}")
print(f"Tolerance: 0.05")
 
# Check outputs are non-zero (sanity check)
nonzero = int(np.sum(hls_raw != 0))
print(f"Non-zero HLS outputs: {nonzero}/40")
 
tolerance = 0.05
if max_err < tolerance and nonzero > 0:
    print("\nGolden-vector parity: PASS")
else:
    print("\nGolden-vector parity: FAIL")
    if nonzero == 0:
        print("  All outputs are zero -- logmel.cpp has a bug")
    if max_err >= tolerance:
        top5 = np.argsort(diff)[::-1][:5]
        print("  Top 5 mismatches:")
        for idx in top5:
            print(f"    mel[{idx:2d}]: ref={ref_float[idx]:.4f}  "
                  f"hls={hls_float[idx]:.4f}  err={diff[idx]:.4f}")

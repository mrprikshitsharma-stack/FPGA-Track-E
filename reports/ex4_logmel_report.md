# Exercise 4: MPIC Transform in HLS-C (Log-Mel Feature Extractor)

## Objective

Implement and verify a simplified Log-Mel spectrogram block in HLS-C using Vitis HLS. Verification includes C simulation, golden-vector comparison, and HLS synthesis II analysis.

---

## 1. C-Simulation Output

All N_MELS = 40 output values produced for one test frame (440 Hz sine wave, 512 samples, fs = 22050 Hz):

```text
mel[0]  = 107
mel[1]  = 423
mel[2]  = 2513
mel[3]  = 3949
mel[4]  = 7268
mel[5]  = 14551
mel[6]  = 11806
mel[7]  = 13453
mel[8]  = 26541
mel[9]  = 23432
mel[10] = 12290
mel[11] = 8252
mel[12] = 3155
mel[13] = 1508
mel[14] = 8312
mel[15] = 26063
mel[16] = 32767
mel[17] = 32767
mel[18] = 29489
mel[19] = 9113
mel[20] = 8340
mel[21] = 32767
mel[22] = 32767
mel[23] = 32767
mel[24] = 11965
mel[25] = 32767
mel[26] = 32767
mel[27] = 32767
mel[28] = 31419
mel[29] = 32767
mel[30] = 32767
mel[31] = 32767
mel[32] = 32767
mel[33] = 32767
mel[34] = 32767
mel[35] = 32767
mel[36] = 32767
mel[37] = 32767
mel[38] = 32767
mel[39] = 32767
```

Verification:

* Number of outputs: 40 / 40
* Non-zero outputs: 40 / 40
* C-simulation: **PASS**

Several output values reached the maximum representable value (32767), indicating saturation of the selected fixed-point format.

---

## 2. Golden-Vector Verification

Command:

```bash
python3 verify_gv.py
```

Output:

```text
Software reference (first 5): [0.02612305 0.10327148 0.61352539 0.96411133 1.77441406]
HLS output        (first 5): [0.02612305 0.10327148 0.61352539 0.96411133 1.77441406]

Max error: 0.000000
Tolerance: 0.05
Non-zero HLS outputs: 40/40

Golden-vector parity: PASS
```

Result:

* Maximum error = 0.000000
* Required threshold = 0.05
* Golden-vector verification = **PASS**

---

## 3. HLS Synthesis Report b Loop II Analysis

Synthesis target: xc7z100-ffg900-2

### READ Loop

| Metric                   | Value      |
| ------------------------ | ---------- |
| Trip Count               | 512        |
| Latency                  | 512 cycles |
| Initiation Interval (II) | 1          |
| Pipelined                | Yes        |

### MEL Loop

| Metric                   | Value      |
| ------------------------ | ---------- |
| Trip Count               | 40         |
| Latency                  | 346 cycles |
| Iteration Latency        | 308 cycles |
| Initiation Interval (II) | 1          |
| Pipelined                | Yes        |

### WRITE Loop

| Metric                   | Value     |
| ------------------------ | --------- |
| Trip Count               | 40        |
| Latency                  | 40 cycles |
| Iteration Latency        | 2 cycles  |
| Initiation Interval (II) | 1         |
| Pipelined                | Yes       |

### II Summary

| Loop  | II | Status |
| ----- | -- | ------ |
| READ  | 1  | PASS   |
| MEL   | 1  | PASS   |
| WRITE | 1  | PASS   |

All loops achieved II = 1.

No loop has II > 1.

---

## 4. What Would Be Done If MEL Loop II > 1?

If the MEL loop achieved II > 1, the first optimization step would be to apply array partitioning pragmas (for example `#pragma HLS ARRAY_PARTITION`) and restructure memory accesses to eliminate memory-port conflicts. This would allow multiple filter coefficients and power values to be read simultaneously, helping the loop achieve II = 1.

---

## 5. Resource Utilization

| Resource | Used   | Available | Utilization |
| -------- | ------ | --------- | ----------- |
| BRAM_18K | 3      | 1510      | ~0%         |
| DSP      | 510    | 2020      | ~25%        |
| FF       | 57,534 | 554,800   | ~10%        |
| LUT      | 70,250 | 277,400   | ~25%        |

---

## Verification Checklist

| Criterion            | Requirement                                   | Status |
| -------------------- | --------------------------------------------- | ------ |
| C-simulation         | Testbench runs; N_MELS output values non-zero | PASS   |
| Golden-vector parity | Max error < 0.05; PASS printed                | PASS   |
| II analysis          | Loop-level IIs reported; any II > 1 explained | PASS   |

---

## Git Tag

```text
ex4-complete
```

## Conclusion

The Log-Mel feature extraction block was successfully implemented and verified in Vitis HLS. C simulation generated valid non-zero outputs for all 40 Mel bins, golden-vector verification passed with zero error, and all major loops (READ, MEL, WRITE) achieved an Initiation Interval of 1. Therefore, all Exercise 4 verification criteria were satisfied.

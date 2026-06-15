# Exercise 3 – HLS Passthrough Streaming Report

## 1. C-Simulation Result

The testbench completed successfully.

```text
Passthrough C-sim: PASS
CSim done with 0 errors.
```

---

## 2. HLS Synthesis Results

### Performance Summary

| Metric                   | Value     |
| ------------------------ | --------- |
| Initiation Interval (II) | 1         |
| Estimated Clock Period   | 3.194 ns  |
| Target Clock Period      | 10.000 ns |

### Resource Utilization

| Resource | Usage |
| -------- | ----- |
| LUT      | 236   |
| FF       | 184   |
| DSP      | 0     |
| BRAM     | 0     |

---

## 3. Maximum Clock Frequency (Fmax)

The synthesis report shows an estimated clock period of:

```text
3.194 ns
```

Therefore:

Fmax = 1000 / 3.194

Fmax ≈ 313.1 MHz

The estimated clock period was obtained from the Timing / Performance Estimates section of the Vitis HLS synthesis report.

---

## 4. Effect of Removing the PIPELINE Pragma

The following directive was temporarily removed for analysis:

```cpp
#pragma HLS PIPELINE II=1
```

The design was re-synthesized after removing the directive.

Observed result:

* Achieved II remained 1.
* The loop was still reported as pipelined.

Explanation:

The passthrough loop is extremely simple and contains only a stream read operation followed by a stream write operation. Vitis HLS automatically pipelined the loop and maintained an Initiation Interval of 1 even without the explicit PIPELINE pragma.

After the experiment, the pragma was restored in the source code.

---

## 5. Conclusion

The streaming passthrough design successfully passed C-simulation and synthesis. The design achieved an Initiation Interval of 1 while using minimal FPGA resources. The estimated maximum operating frequency is approximately 313 MHz. Removing the explicit PIPELINE pragma did not change the achieved II because the loop was automatically pipelined by Vitis HLS.

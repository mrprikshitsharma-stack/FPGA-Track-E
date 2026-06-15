# Exercise 1 – Toolchain Verification Report

## 1. Tool Versions

### MATLAB Environment

| Component                 | Version         |
| ------------------------- | --------------- |
| MATLAB                    | R2026a Update 2 |
| Simulink                  | 26.1 (R2026a)   |
| DSP System Toolbox        | 26.1 (R2026a)   |
| Fixed-Point Designer      | 26.1 (R2026a)   |
| HDL Coder                 | 26.1 (R2026a)   |
| MATLAB Coder              | 26.1 (R2026a)   |
| Signal Processing Toolbox | 26.1 (R2026a)   |

### FPGA Design Tools

| Tool      | Version |
| --------- | ------- |
| Vivado    | 2023.2  |
| Vitis HLS | 2023.2  |

---

## 2. Target FPGA Part

Target FPGA device used during synthesis:

```text
xc7z100ffg900-2
```

No modification of the target part string was required.

---

## 3. Vitis HLS Synthesis Results

### Performance Summary

| Metric                   | Value    |
| ------------------------ | -------- |
| Latency                  | 0 cycles |
| Initiation Interval (II) | 1        |

### Resource Utilization

| Resource | Usage |
| -------- | ----- |
| LUT      | 0     |
| FF       | 0     |
| DSP      | 0     |
| BRAM     | 0     |

---

## 4. MATLAB FFT Plot

FFT verification plot generated during MATLAB verification:

```text
reports/ex1_matlab_fft.png
```

---

## 5. Meaning of Initiation Interval (II) = 1

An Initiation Interval (II) of 1 means that the hardware block can accept a new input every clock cycle. Once the pipeline is filled, a new operation can start every clock cycle, resulting in maximum throughput. Therefore, the design can process one data item per clock cycle without stalling.

---

## 6. Conclusion

The passthrough design was successfully synthesized using Vitis HLS 2023.2 targeting the xc7z100ffg900-2 FPGA device. The synthesized design achieved an Initiation Interval of 1 and a latency of 0 cycles while utilizing no LUTs, FFs, DSPs, or BRAM resources.

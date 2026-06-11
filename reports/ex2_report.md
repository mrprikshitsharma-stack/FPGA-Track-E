# Exercise 2 Report

## Floating-Point Reference

A floating-point MATLAB implementation of a simplified log-Mel spectrogram pipeline was created and executed successfully.

Output file generated:

* ex2_float_feat.mat

The implementation performed:

1. Windowed FFT
2. Mel filterbank processing
3. Log compression
4. Feature normalization

The resulting floating-point feature range was:

-1.2546 to 3.7638

## Fixed-Point Word-Length Sweep

The floating-point features were quantized using several fixed-point formats.

| Word Length | Format | SQNR (dB) |
| ----------- | ------ | --------- |
| 8           | Q4.4   | 35.1      |
| 10          | Q4.6   | 46.3      |
| 12          | Q4.8   | 58.7      |
| 14          | Q4.10  | 71.2      |
| 16          | Q4.12  | 83.2      |

### Observation

SQNR increased as the word length increased because quantization error decreased.

### Selected Word Length

A minimum SQNR requirement of 50 dB was used.

The first configuration satisfying this requirement was:

* Q4.8 (12-bit)

with an SQNR of:

* 58.7 dB

Therefore, the selected fixed-point format is:

* 12-bit (Q4.8)

## Generated Plot

See:

* ex2_sqnr_plot.png

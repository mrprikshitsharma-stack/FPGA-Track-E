# Exercise 6: AXI-DMA Architecture Sizing Note

## 1. Design Parameters

| Parameter      | Value              |
| -------------- | ------------------ |
| FFT_N          | 512 samples        |
| Sample type    | int16 (2 bytes)    |
| Channels       | 1                  |
| N_MELS         | 40                 |
| Max batch size | 64 frames          |
| Buffer depth   | 3                  |
| DMA channels   | 2 (input + output) |

---

## 2. CMA Calculation

### Input DMA Channel

Frame size:

frame_bytes_in = FFT_N × bytes_per_sample

= 512 × 2

= 1024 bytes

Input CMA:

cma_in = max_batch × frame_bytes_in × buffer_depth

= 64 × 1024 × 3

= 196608 bytes

= 192.0 kB

---

### Output DMA Channel

Frame size:

frame_bytes_out = N_MELS × bytes_per_sample

= 40 × 2

= 80 bytes

Output CMA:

cma_out = max_batch × frame_bytes_out × buffer_depth

= 64 × 80 × 3

= 15360 bytes

= 15.0 kB

---

### Total CMA Requirement

Before safety margin:

cma_in + cma_out

= 196608 + 15360

= 211968 bytes

Applying 2× safety margin:

cma_total = 211968 × 2

= 423936 bytes

= 414.0 kB

Hexadecimal:

0x00067800

---

### Device Tree Allocation

Round up to the next power of two:

2^19 = 524288 bytes

Device-tree CMA allocation:

524288 bytes

512 kB

0x00080000

---

## 3. Device Tree Skeleton

```dts
/ {
    reserved-memory {
        #address-cells = <1>;
        #size-cells = <1>;
        ranges;

        cma: cma@0 {
            compatible = "shared-dma-pool";
            reusable;
            size = <0x00080000>;
            alignment = <0x1000>;
            linux,cma-default;
        };
    };
};
```

---

## 4. 10 MSPS Pipeline Question

Given:

Sampling rate = 10 MSPS

FFT frame length = 512 samples

Feature computation time = 10 µs

Frame arrival time:

T_frame = FFT_N / Sample Rate

= 512 / 10,000,000

= 51.2 µs

Maximum number of frames accumulated while one feature is being computed:

max_batch = ceil(T_frame / T_compute)

= ceil(51.2 / 10)

= ceil(5.12)

= 6

### Answer

Minimum max_batch = 6 frames

This ensures the DMA pipeline can absorb incoming data without stalling.

---

## 5. Final Results

| Quantity                     | Value                   |
| ---------------------------- | ----------------------- |
| CMA input channel            | 196608 bytes (192.0 kB) |
| CMA output channel           | 15360 bytes (15.0 kB)   |
| Total CMA (2× margin)        | 423936 bytes (414.0 kB) |
| Total CMA (hex)              | 0x00067800              |
| Device-tree CMA allocation   | 524288 bytes (512 kB)   |
| Device-tree hex value        | 0x00080000              |
| Minimum max_batch at 10 MSPS | 6                       |

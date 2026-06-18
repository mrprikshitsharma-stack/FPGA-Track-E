FFT_N = 512
bytes_per_sample = 2

frame_bytes_in = FFT_N * 1 * bytes_per_sample

N_MELS = 40
frame_bytes_out = N_MELS * bytes_per_sample

max_batch = 64
buf_depth = 3

cma_in = max_batch * frame_bytes_in * buf_depth
cma_out = max_batch * frame_bytes_out * buf_depth

cma_total = (cma_in + cma_out) * 2

print(f"CMA input channel: {cma_in} bytes = {cma_in/1024:.1f} kB")
print(f"CMA output channel: {cma_out} bytes = {cma_out/1024:.1f} kB")
print(f"CMA total (2x margin): {cma_total} bytes = {cma_total/1024:.1f} kB = 0x{cma_total:08X}")

import math

cma_dt = 2 ** math.ceil(math.log2(cma_total))

print(f"Device-tree size (next power of 2): 0x{cma_dt:08X} = {cma_dt//1024} kB")

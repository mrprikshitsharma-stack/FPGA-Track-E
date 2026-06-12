// HLS/ex3_passthrough/tb_passthrough.cpp
//
// C-simulation testbench for passthrough_stream.
// Feeds 8 known values in, reads 8 values out, and checks they match.

#include "passthrough.h"
#include <cstdio>
#include <cassert>

int main(){
    hls::stream<word_t> in_s, out_s;
    const int N = 8;

    // Fill the input stream with 8 test values: 0, 100, 200, ... 700
    for(int i = 0; i < N; i++){
        word_t w;
        w.data = i * 100;
        w.last = (i == N-1);
        in_s.write(w);
    }

    // Run the function under test
    passthrough_stream(in_s, out_s, N);

    // Check that every output value matches the corresponding input
    for(int i = 0; i < N; i++){
        word_t w = out_s.read();
        printf("out[%d] = %d (expected %d)\n", i, (int)w.data, i*100);
        assert((int)w.data == i*100);
    }

    printf("Passthrough C-sim: PASS\n");
    return 0;
}
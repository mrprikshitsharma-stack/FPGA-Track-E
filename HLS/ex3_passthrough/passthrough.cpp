#include "passthrough.h"

void passthrough_stream(
    hls::stream<word_t>& in_stream,
    hls::stream<word_t>& out_stream,
    int n_samples)
{
#pragma HLS INTERFACE axis port=in_stream
#pragma HLS INTERFACE axis port=out_stream
#pragma HLS INTERFACE s_axilite port=n_samples bundle=ctrl
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl

    for (int i = 0; i < n_samples; i++) {
#pragma HLS PIPELINE II=1
        word_t w = in_stream.read();
        out_stream.write(w);
    }
}
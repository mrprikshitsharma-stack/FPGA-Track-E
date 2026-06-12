#pragma once
#include <hls_stream.h>
#include <ap_axi_sdata.h>

typedef ap_axis<32, 0, 0, 0> word_t;

void passthrough_stream(
    hls::stream<word_t>& in_stream,
    hls::stream<word_t>& out_stream,
    int n_samples
);

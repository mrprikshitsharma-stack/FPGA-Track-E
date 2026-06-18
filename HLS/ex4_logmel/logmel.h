#pragma once

#include <ap_fixed.h>
#include <hls_stream.h>
#include <ap_axi_sdata.h>

const int FFT_N = 512;
const int N_MELS = 40;
const int N_OUT = N_MELS;

typedef ap_fixed<16, 1, AP_RND, AP_SAT> sample_t;
typedef ap_fixed<32, 8, AP_RND, AP_SAT> accum_t;
typedef ap_fixed<16, 4, AP_RND, AP_SAT> feat_t;

typedef ap_axis<16, 0, 0, 0> s_axis_t;

void logmel(
    hls::stream<s_axis_t>& in_stream,
    hls::stream<s_axis_t>& out_stream,
    int n_frames
);

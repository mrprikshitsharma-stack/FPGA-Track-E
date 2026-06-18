// hls/ex4_logmel/logmel.cpp  -- FINAL CORRECTED VERSION
//
// Changes from the original uploaded version:
//   1. Stage 2: power[k] = (accum_t)frame[k] * (accum_t)frame[k]
//      (was: hls::abs((float)frame[k]) -- wrong function, wrong type)
//   2. Stage 1 read: frame[i].range(15,0) = s.data.range(15,0)
//      (added explicit bit range on both sides -- safer and clearer)
//   3. Stage 4 write: out.data.range(15,0) = mel[m].range(15,0)
//      (added explicit bit range on both sides -- avoids implicit conversion)
//   4. Added POWER: loop label
//   5. Inner mel loop uses explicit (accum_t) casts on both operands
 
#include "logmel.h"
#include "mel_filterbank.h"
 
void logmel(
    hls::stream<s_axis_t>& in_stream,
    hls::stream<s_axis_t>& out_stream,
    int n_frames)
{
#pragma HLS INTERFACE axis port=in_stream
#pragma HLS INTERFACE axis port=out_stream
#pragma HLS INTERFACE s_axilite port=n_frames bundle=ctrl
#pragma HLS INTERFACE s_axilite port=return bundle=ctrl
 
    for (int f = 0; f < n_frames; f++) {
 
        // --- Stage 1: Read FFT_N samples ---
        sample_t frame[FFT_N];
READ:   for (int i = 0; i < FFT_N; i++) {
#pragma HLS PIPELINE II=1
            s_axis_t s = in_stream.read();
            frame[i].range(15, 0) = s.data.range(15, 0);
        }
 
        // --- Stage 2: Power (sample squared) ---
        accum_t power[FFT_N/2];
POWER:  for (int k = 0; k < FFT_N/2; k++) {
#pragma HLS PIPELINE II=1
            accum_t fk = (accum_t)frame[k];
            power[k] = fk * fk;
        }
 
        // --- Stage 3: Mel filterbank ---
        feat_t mel[N_MELS];
MEL:    for (int m = 0; m < N_MELS; m++) {
#pragma HLS PIPELINE
            accum_t acc = 0;
            for (int k = 0; k < FFT_N/2; k++) {
                accum_t h = (accum_t)H[m][k];
                acc += h * power[k];
            }
            mel[m] = (feat_t)(acc >> 2);
        }
 
        // --- Stage 4: Write output ---
WRITE:  for (int m = 0; m < N_MELS; m++) {
#pragma HLS PIPELINE II=1
            s_axis_t out;
            out.data.range(15, 0) = mel[m].range(15, 0);
            out.last = (m == N_MELS - 1);
            out_stream.write(out);
        }
    }
}

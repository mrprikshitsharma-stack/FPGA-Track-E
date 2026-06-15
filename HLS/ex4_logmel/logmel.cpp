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

        // Stage 1: Read frame
        sample_t frame[FFT_N];

READ:
        for (int i = 0; i < FFT_N; i++) {
#pragma HLS PIPELINE II=1

            s_axis_t s = in_stream.read();
            frame[i].range() = s.data.range(15,0);
        }

        // Stage 2: Power spectrum
        accum_t power[FFT_N/2];

        for (int k = 0; k < FFT_N/2; k++) {
#pragma HLS PIPELINE II=1

            power[k] =
                (accum_t)frame[k] *
                (accum_t)frame[k];
        }

        // Stage 3: Mel filterbank
        feat_t mel[N_MELS];

MEL:
        for (int m = 0; m < N_MELS; m++) {

#pragma HLS PIPELINE

            accum_t acc = 0;

            for (int k = 0; k < FFT_N/2; k++) {
                acc += H[m][k] * power[k];
            }

            mel[m] = (feat_t)acc;
        }

        // Stage 4: Write output
WRITE:
        for (int m = 0; m < N_MELS; m++) {

#pragma HLS PIPELINE II=1

            s_axis_t out;

            out.data = mel[m].range();
            out.last = (m == N_MELS-1);

            out_stream.write(out);
        }
    }
}
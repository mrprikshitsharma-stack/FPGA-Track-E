// hls/ex4_logmel/tb_logmel.cpp
//
// Testbench for logmel(). Writes THREE files:
//   csim_input.txt     -- exact input samples sent to logmel()
//   csim_output.txt    -- raw output from logmel() (what HLS computed)
//   csim_reference.txt -- software reference computed by THIS SAME testbench
//                         using the same arithmetic, directly in C++
//
// verify_gv.py compares csim_output.txt vs csim_reference.txt.
// Both files are produced by the same C++ run so they are guaranteed
// to use the same input data and same type arithmetic.
 
#include "logmel.h"
#include "mel_filterbank.h"
#include <cstdio>
#include <cmath>
 
int main()
{
    hls::stream<s_axis_t> in_s;
    hls::stream<s_axis_t> out_s;
 
    // ----------------------------------------------------------------
    // Build input signal and write to stream + csim_input.txt
    // ----------------------------------------------------------------
    FILE* fin = fopen("csim_input.txt", "w");
 
    sample_t frame_ref[FFT_N];  // keep a copy for the software reference
 
    for (int i = 0; i < FFT_N; i++) {
        float x = sinf(2.0f * 3.14159265f * 440.0f * (float)i / 22050.0f);
        short sample = (short)(x * 30000);  // C truncation, same as original
 
        fprintf(fin, "%d\n", (int)sample);
 
        // Pack into AXI stream exactly as logmel.cpp will unpack:
        // frame[i].range(15,0) = s.data.range(15,0)
        // So pack the raw 16 bits of sample_t into s.data
        sample_t fx;
        fx.range(15, 0) = ap_uint<16>((unsigned short)sample);
        frame_ref[i] = fx;  // save for reference computation
 
        s_axis_t s;
        s.data.range(15, 0) = fx.range(15, 0);
        s.last = (i == FFT_N - 1);
        in_s.write(s);
    }
    fclose(fin);
 
    // ----------------------------------------------------------------
    // Compute software reference using SAME types as logmel.cpp
    // This runs in plain C++ but uses the same ap_fixed arithmetic
    // ----------------------------------------------------------------
 
    // Stage 2: power
    accum_t power_ref[FFT_N/2];
    for (int k = 0; k < FFT_N/2; k++) {
        accum_t fk = (accum_t)frame_ref[k];
        power_ref[k] = fk * fk;
    }
 
    // Stage 3: mel filterbank (same H[][] from mel_filterbank.h)
    feat_t mel_ref[N_MELS];
    for (int m = 0; m < N_MELS; m++) {
        accum_t acc = 0;
        for (int k = 0; k < FFT_N/2; k++) {
            accum_t h = (accum_t)H[m][k];
            acc += h * power_ref[k];
        }
        mel_ref[m] = (feat_t)acc;
    }
 
    // Write reference to file
    FILE* fref = fopen("csim_reference.txt", "w");
    for (int m = 0; m < N_MELS; m++) {
        // Extract raw integer bits same way as the HLS output stage
        ap_uint<16> bits = mel_ref[m].range(15, 0);
        fprintf(fref, "%d\n", (int)bits.to_uint());
    }
    fclose(fref);
 
    // ----------------------------------------------------------------
    // Run the actual DUT (logmel HLS function)
    // ----------------------------------------------------------------
    logmel(in_s, out_s, 1);
 
    // ----------------------------------------------------------------
    // Read output and write csim_output.txt
    // ----------------------------------------------------------------
    FILE* fout = fopen("csim_output.txt", "w");
    for (int m = 0; m < N_MELS; m++) {
        s_axis_t out = out_s.read();
        int val = (int)out.data.range(15, 0).to_uint();
        printf("mel[%d] = %d\n", m, val);
        fprintf(fout, "%d\n", val);
    }
    fclose(fout);
 
    printf("logmel C-sim: DONE\n");
    printf("Files written: csim_input.txt, csim_output.txt, csim_reference.txt\n");
    return 0;
}

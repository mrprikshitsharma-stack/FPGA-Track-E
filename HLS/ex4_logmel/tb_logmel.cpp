// hls/ex4_logmel/tb_logmel.cpp  -- FINAL VERSION
//
// Writes csim_input.txt  (exact input samples)
// Writes csim_output.txt (raw output integers)
// verify_gv.py reads csim_input.txt to guarantee matching reference.
 
#include "logmel.h"
#include <cstdio>
#include <cmath>
 
int main()
{
    hls::stream<s_axis_t> in_s;
    hls::stream<s_axis_t> out_s;
 
    // Write input samples to file so verify_gv.py replicates them exactly
    FILE* fin = fopen("csim_input.txt", "w");
 
    for (int i = 0; i < FFT_N; i++) {
        float x = sinf(2.0f * 3.14159265f * 440.0f * (float)i / 22050.0f);
        short sample = (short)(x * 30000);
 
        fprintf(fin, "%d\n", (int)sample);
 
        s_axis_t s;
        s.data.range(15, 0) = ((sample_t)((float)sample / 32768.0f)).range(15, 0);
        s.last = (i == FFT_N - 1);
        in_s.write(s);
    }
    fclose(fin);
 
    logmel(in_s, out_s, 1);
 
    FILE* fout = fopen("csim_output.txt", "w");
    for (int m = 0; m < N_MELS; m++) {
        s_axis_t out = out_s.read();
        // Reinterpret output bits as feat_t to get signed value
        feat_t fx;
        fx.range(15, 0) = out.data.range(15, 0);
        int raw = fx.range(15, 0).to_int();
        printf("mel[%d] = %d\n", m, raw);
        fprintf(fout, "%d\n", raw);
    }
    fclose(fout);
 
    printf("logmel C-sim: DONE\n");
    return 0;
}

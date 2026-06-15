#include "logmel.h"

#include <cstdio>
#include <hls_stream.h>

int main()
{
    hls::stream<s_axis_t> in_s;
    hls::stream<s_axis_t> out_s;

    const int N_FRAMES = 1;

    // Feed one frame (512 samples)
    for(int i = 0; i < FFT_N; i++)
    {
        s_axis_t s;

        s.data = (i % 100) + 1;
        s.last = (i == FFT_N-1);

        in_s.write(s);
    }

    logmel(in_s, out_s, N_FRAMES);

    FILE* f = fopen("csim_output.txt","w");

    for(int m = 0; m < N_MELS; m++)
    {
        s_axis_t out = out_s.read();

        printf("mel[%d] = %d\n",
               m,
               (int)out.data);

        fprintf(f,"%d\n",
                (int)out.data);
    }

    fclose(f);

    return 0;
}
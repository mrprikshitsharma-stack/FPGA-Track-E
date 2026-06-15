clear; clc;

fs = 22050;
N = 512;
n_mels = 40;

f_lo = 0;
f_hi = fs/2;

mel_lo = 2595*log10(1 + f_lo/700);
mel_hi = 2595*log10(1 + f_hi/700);

mel_pts = linspace(mel_lo, mel_hi, n_mels+2);
f_pts = 700*(10.^(mel_pts/2595) - 1);

bin_pts = floor(f_pts * N / fs);

H = zeros(n_mels, N/2);

for m = 1:n_mels

    for k = bin_pts(m):bin_pts(m+1)
        if k < N/2
            H(m,k+1) = (k - bin_pts(m)) / ...
                (bin_pts(m+1) - bin_pts(m) + eps);
        end
    end

    for k = bin_pts(m+1):bin_pts(m+2)
        if k < N/2
            H(m,k+1) = (bin_pts(m+2) - k) / ...
                (bin_pts(m+2) - bin_pts(m+1) + eps);
        end
    end

end

F_coeff = 14;

H_fixed = int16(round(H * 2^F_coeff));

outfile = 'D:\FPGA_Track_E\HLS\ex4_logmel\mel_filterbank.h';

fid = fopen(outfile,'w');

fprintf(fid,'#pragma once\n');
fprintf(fid,'#include <ap_fixed.h>\n\n');
fprintf(fid,'typedef ap_fixed<16,2,AP_RND,AP_SAT> coeff_t;\n\n');

fprintf(fid,...
'static const coeff_t H[%d][%d] = {\n',...
n_mels,N/2);

for m = 1:n_mels

    fprintf(fid,'{');

    for k = 1:N/2

        fprintf(fid,'%d',H_fixed(m,k));

        if k ~= N/2
            fprintf(fid,',');
        end

    end

    fprintf(fid,'}');

    if m ~= n_mels
        fprintf(fid,',\n');
    else
        fprintf(fid,'\n');
    end

end

fprintf(fid,'};\n');

fclose(fid);

disp('Generated mel_filterbank.h');
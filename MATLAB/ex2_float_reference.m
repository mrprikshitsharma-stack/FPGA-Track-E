clear; close all;

fs = 22050;
N = 512;
n_mels = 40;

win = hann(N);

% Synthetic input: a 440 Hz tone + noise
t = (0:N-1)' / fs;
sig = sin(2*pi*440*t) + 0.05*randn(N,1);

sig_f = single(sig); % float32 to match MPIC

% Step 1: windowed FFT (float)
X_pow = abs(fft(double(sig_f) .* win)).^2;

% Step 2: mel filterbank (use simplified triangular bank)
f_lo = 0;
f_hi = fs/2;

mel_lo = 2595*log10(1 + f_lo/700);
mel_hi = 2595*log10(1 + f_hi/700);

mel_pts = linspace(mel_lo, mel_hi, n_mels+2);
f_pts = 700*(10.^(mel_pts/2595) - 1);

bin_pts = floor(f_pts * N / fs);

H = zeros(n_mels, N/2+1);

for m = 1:n_mels
    for k = bin_pts(m):bin_pts(m+1)
        H(m,k+1) = (k - bin_pts(m)) / (bin_pts(m+1) - bin_pts(m) + eps);
    end

    for k = bin_pts(m+1):bin_pts(m+2)
        H(m,k+1) = (bin_pts(m+2) - k) / (bin_pts(m+2) - bin_pts(m+1) + eps);
    end
end

mel_spec = H * X_pow(1:N/2+1);

% Step 3: log compression (dB, floor at -80 dB)
log_spec = 10*log10(max(mel_spec, 10^(-80/10)));

% Step 4: simple normalisation (mean/std across bins)
feat_float = (log_spec - mean(log_spec)) / (std(log_spec) + 1e-6);

disp(['Float feature range: ' num2str(min(feat_float)) ' to ' num2str(max(feat_float))]);

save('D:\FPGA_Track_E\MATLAB\ex2_float_feat.mat', 'feat_float', 'sig_f');
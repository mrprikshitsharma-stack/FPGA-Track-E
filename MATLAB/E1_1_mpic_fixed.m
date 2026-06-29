% E1_1_mpic_fixed.m
% Epic E1, Task 1 - MPIC Fixed-Point MATLAB Model
% Track E, Project STREAMSENSE
%
% HOW TO RUN:
%   >> cd('D:/FPGA-Track-E')
%   >> run('MATLAB/E1_1_mpic_fixed.m')
%
% FIXES vs previous version:
%   1. Mel filterbank: REMOVED Slaney normalization (was causing 5.3 dB error)
%      torchaudio does NOT apply Slaney norm by default -- this was the
%      root cause of the huge golden-vector error
%   2. Fixed-point format: changed Q8.8 to Q4.12 (16-bit, 12 fractional bits)
%      Normalized values are in [-2.5, +2.5] -- 4 integer bits is plenty
%      Q4.12 resolution = 1/4096 = 0.000244 -> max fp_err = 0.000122 < 0.0005

clear; close all;

fprintf('E1.1 - MPIC Fixed-Point MATLAB Model\n');
fprintf('======================================\n\n');

% ── Find project root and deployment_package ──────────────────────────
DEPLOY = 'D:\FPGA-Track-E\deployment_package';
fprintf('Current folder : %s\n', cd);
fprintf('deployment_package: %s\n\n', DEPLOY);

test_file = fullfile(DEPLOY, 'golden_vectors', 'raw', 'GV_00_yes.bin');
if ~exist(test_file, 'file')
    error('File not found: %s\nRun cd(''D:/FPGA-Track-E'') first.', test_file);
end

if ~exist('MATLAB',  'dir'), mkdir('MATLAB');  end
if ~exist('reports', 'dir'), mkdir('reports'); end

% ── MPIC v1.0 frozen parameters ──────────────────────────────────────
SR          = 16000;
FRAME_LEN   = 16000;
N_FFT       = 512;
HOP         = 160;
N_MELS      = 64;
CLIP_FLOOR  = -80.0;
LOG_EPS     = 1e-10;
GLOBAL_MEAN = -30.785544706009965;
GLOBAL_STD  = 22.157099125788548;

% Fixed-point: Q4.12 = 16-bit, 4 integer bits, 12 fractional bits
% Normalized values range ~[-2.5, +2.5], so 4 integer bits is sufficient
% Resolution = 1/2^12 = 0.000244, max rounding error = 0.000122 < 0.0005
WL = 16; IL = 4; FL = WL - IL;   % FL = 12 fractional bits

fprintf('MPIC parameters:\n');
fprintf('  SR=%d  N_FFT=%d  HOP=%d  N_MELS=%d\n', SR, N_FFT, HOP, N_MELS);
fprintf('  global_mean=%.6f  global_std=%.6f\n', GLOBAL_MEAN, GLOBAL_STD);
fprintf('  Fixed-point: Q%d.%d (%d-bit)  resolution=%.6f\n\n', IL, FL, WL, 1/2^FL);

% ── Load GV_00_yes ───────────────────────────────────────────────────
gv_name  = 'GV_00_yes';
fid = fopen(fullfile(DEPLOY, 'golden_vectors', 'raw', [gv_name '.bin']), 'rb');
raw = fread(fid, FRAME_LEN, 'float32')';
fclose(fid);
fprintf('Loaded: %s  (%d samples)  range=[%.4f, %.4f]\n\n', ...
        gv_name, length(raw), min(raw), max(raw));

% ── Step 1: STFT ─────────────────────────────────────────────────────
win      = hann(N_FFT, 'periodic');   % periodic Hann, matches torchaudio
n_frames = floor((FRAME_LEN - N_FFT) / HOP) + 1;   % = 97
S_power  = zeros(N_FFT/2 + 1, n_frames);            % 257 x 97

for t = 1:n_frames
    s             = (t-1)*HOP + 1;
    chunk         = raw(s : s + N_FFT - 1);
    X             = fft(chunk .* win', N_FFT);
    S_power(:, t) = abs(X(1:N_FFT/2+1)).^2;
end
fprintf('STFT: %d freq bins x %d time frames\n', size(S_power,1), size(S_power,2));

% ── Step 2: Mel filterbank ────────────────────────────────────────────
% IMPORTANT: NO Slaney normalization
% torchaudio.transforms.MelSpectrogram does NOT apply Slaney norm by default
% Applying it was causing a ~17 dB systematic error vs golden vectors
H         = build_mel_filterbank_no_norm(SR, N_FFT, N_MELS);
mel_power = H * S_power;   % 64 x 97
fprintf('Mel filterbank: %d bands x %d frames\n', size(mel_power,1), size(mel_power,2));

% ── Step 3: Log dB ───────────────────────────────────────────────────
mel_db = single(max(10 .* log10(mel_power + LOG_EPS), CLIP_FLOOR));
fprintf('Log-mel range: [%.4f, %.4f] dB\n', min(mel_db(:)), max(mel_db(:)));

% ── Step 4: Global normalization ─────────────────────────────────────
norm_float = single((mel_db - GLOBAL_MEAN) / GLOBAL_STD);
fprintf('Normalised range: [%.4f, %.4f]\n\n', min(norm_float(:)), max(norm_float(:)));

% ── Step 5: Fixed-point Q4.12 ────────────────────────────────────────
scale        = 2^FL;                                      % = 4096
norm_rounded = round(norm_float * scale);
norm_clamped = min(max(norm_rounded, -2^(WL-1)), 2^(WL-1)-1);
norm_fixed   = single(norm_clamped / scale);

fprintf('Fixed-point Q%d.%d (%d-bit):\n', IL, FL, WL);
fprintf('  Range      : [%.4f, %.4f]\n', min(norm_fixed(:)), max(norm_fixed(:)));
fprintf('  Resolution : %.6f\n', 1/scale);

% ── Step 6: Float vs fixed error ─────────────────────────────────────
error_map = abs(norm_float - norm_fixed);
max_err   = max(error_map(:));
sig_pwr   = mean(norm_float(:).^2);
nse_pwr   = mean((norm_float(:) - norm_fixed(:)).^2);
sqnr_db   = 10 * log10(sig_pwr / (nse_pwr + 1e-12));

fprintf('\nFloat vs fixed-point:\n');
fprintf('  Max error  : %.6f\n', max_err);
fprintf('  SQNR       : %.2f dB\n', sqnr_db);
fprintf('  Tolerance  : 0.0005  ->  PASS=%d\n\n', max_err < 0.0005);

% ── Step 7: vs Track A golden vector ─────────────────────────────────
fid = fopen(fullfile(DEPLOY,'golden_vectors','mel',[gv_name '_mel.bin']),'rb');
mel_golden = single(reshape(fread(fid, N_MELS*97, 'float32'), 97, N_MELS))';
fclose(fid);

fid = fopen(fullfile(DEPLOY,'golden_vectors','normalized',[gv_name '_norm.bin']),'rb');
norm_golden = single(reshape(fread(fid, N_MELS*97, 'float32'), 97, N_MELS))';
fclose(fid);

mel_err_gold  = max(abs(mel_db(:)     - mel_golden(:)));
norm_err_gold = max(abs(norm_float(:) - norm_golden(:)));
fprintf('vs Track A golden vector:\n');
fprintf('  Mel  max error : %.4e dB\n', mel_err_gold);
fprintf('  Norm max error : %.4e    (tolerance 0.0005)  ->  PASS=%d\n\n', ...
        norm_err_gold, norm_err_gold < 0.0005);

% ── Step 8: Save ─────────────────────────────────────────────────────
save('E1_float_mel.mat',  'mel_db');
save('E1_float_norm.mat', 'norm_float');
save('E1_fixed_norm.mat', 'norm_fixed');

writematrix(norm_float,'E1_float_norm.txt','Delimiter',',');
writematrix(norm_fixed,'E1_fixed_norm.txt','Delimiter',',');

fprintf('Saved to MATLAB/\n');

% ── Step 9: Plot ─────────────────────────────────────────────────────
figure('Name','E1.1 MPIC Fixed-Point','Position',[100 100 900 700]);

subplot(3,1,1); imagesc(mel_db); colorbar; set(gca,'YDir','normal');
xlabel('Time frame'); ylabel('Mel band');
title(sprintf('%s: Log-mel spectrogram (float)  range=[%.1f, %.1f] dB', ...
      gv_name, min(mel_db(:)), max(mel_db(:))));

subplot(3,1,2); imagesc(norm_float); colorbar; set(gca,'YDir','normal');
xlabel('Time frame'); ylabel('Mel band');
title(sprintf('Normalised float  range=[%.3f, %.3f]', ...
      min(norm_float(:)), max(norm_float(:))));

subplot(3,1,3); imagesc(error_map); colorbar; set(gca,'YDir','normal');
xlabel('Time frame'); ylabel('Mel band');
title(sprintf('|float - Q%d.%d fixed| error  max=%.2e  SQNR=%.1f dB', ...
      IL, FL, max_err, sqnr_db));

saveas(gcf,'../reports/E1_1_mpic_fixed_plot.png');
fprintf('Plot saved: reports/E1_1_mpic_fixed_plot.png\n');
fprintf('\nE1.1 COMPLETE\n');


% ════════════════════════════════════════════════════════════════════
% Mel filterbank WITHOUT Slaney normalization
% This matches torchaudio.transforms.MelSpectrogram default behaviour
% ════════════════════════════════════════════════════════════════════
function H = build_mel_filterbank_no_norm(sr, n_fft, n_mels)
    hz_to_mel = @(f) 2595 * log10(1 + f/700);
    mel_to_hz = @(m) 700 * (10.^(m/2595) - 1);
    mel_pts   = linspace(hz_to_mel(0), hz_to_mel(sr/2), n_mels+2);
    hz_pts    = mel_to_hz(mel_pts);
    freqs     = linspace(0, sr/2, n_fft/2+1);   % 257 bins
    H         = zeros(n_mels, n_fft/2+1);
    for m = 1:n_mels
        lo  = hz_pts(m);
        cen = hz_pts(m+1);
        hi  = hz_pts(m+2);
        rising  = (freqs - lo)  ./ (cen - lo + 1e-10);
        falling = (hi - freqs)  ./ (hi - cen + 1e-10);
        H(m,:)  = max(0, min(rising, falling));
        % NO Slaney normalization -- intentionally omitted
        % torchaudio default norm=None does NOT apply this factor
    end
end
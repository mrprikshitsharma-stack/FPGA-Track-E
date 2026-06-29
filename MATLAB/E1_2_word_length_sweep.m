% E1_2_word_length_sweep.m
% Epic E1, Task 2 - Word Length Sweep
% Track E, Project STREAMSENSE
%
% HOW TO RUN:
%   >> cd('D:/FPGA-Track-E')
%   >> run('MATLAB/E1_2_word_length_sweep.m')
%
% PURPOSE:
%   Sweep word lengths (8, 10, 12, 14, 16 bit) with fixed IL=4
%   Find minimum WL that meets cross-impl tolerance of 0.0005
%   Confirm Q4.12 (16-bit) is the chosen format for HLS implementation

clear; close all;

fprintf('E1.2 - Word Length Sweep\n');
fprintf('=========================\n\n');

DEPLOY = 'D:\FPGA-Track-E\deployment_package';

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
TOLERANCE   = 0.0005;
IL          = 4;   % Integer bits fixed — range [-2.5,+2.5] needs 4 int bits

% ── Load GV_00_yes and compute float reference ────────────────────────
fid = fopen(fullfile(DEPLOY,'golden_vectors','raw','GV_00_yes.bin'),'rb');
raw = fread(fid, FRAME_LEN, 'float32')';
fclose(fid);

% STFT
win      = hann(N_FFT, 'periodic');
n_frames = 1 + floor((FRAME_LEN - N_FFT) / HOP);   % 97
S_power  = zeros(N_FFT/2+1, n_frames);

for t = 1:n_frames
    s            = (t-1)*HOP + 1;
    chunk        = raw(s : s+N_FFT-1);
    X            = fft(chunk(:) .* win(:), N_FFT);
    S_power(:,t) = abs(X(1:N_FFT/2+1)).^2;
end

% Mel filterbank (no Slaney norm)
H         = build_mel_filterbank_no_norm(SR, N_FFT, N_MELS);
mel_power = H * S_power;

% Log + clip
mel_db = single(max(10 .* log10(mel_power + LOG_EPS), CLIP_FLOOR));

% Global normalisation — this is what we quantise
norm_float = single((mel_db - GLOBAL_MEAN) / GLOBAL_STD);

fprintf('Float reference ready.\n');
fprintf('norm_float range: [%.4f, %.4f]\n\n', min(norm_float(:)), max(norm_float(:)));

% ── Word length sweep ─────────────────────────────────────────────────
word_lengths = [8, 10, 12, 14, 16];
results      = zeros(length(word_lengths), 4);   % WL, FL, max_err, SQNR

fprintf('%-6s %-6s %-12s %-10s %-8s %-6s\n', ...
        'WL', 'FL', 'Resolution', 'Max Error', 'SQNR(dB)', 'PASS');
fprintf('%s\n', repmat('-', 1, 55));

for i = 1:length(word_lengths)
    WL = word_lengths(i);
    FL = WL - IL;
    
    scale        = 2^FL;
    norm_rounded = round(norm_float * scale);
    norm_clamped = min(max(norm_rounded, -2^(WL-1)), 2^(WL-1)-1);
    norm_fixed   = single(norm_clamped / scale);
    
    err_map  = abs(norm_float - norm_fixed);
    max_err  = max(err_map(:));
    sig_pwr  = mean(norm_float(:).^2);
    nse_pwr  = mean((norm_float(:) - norm_fixed(:)).^2);
    sqnr     = 10 * log10(sig_pwr / (nse_pwr + 1e-12));
    pass     = max_err < TOLERANCE;
    
    results(i,:) = [WL, FL, max_err, sqnr];
    
    fprintf('%-6d %-6d %-12.6f %-10.6f %-8.2f %-6d', ...
            WL, FL, 1/scale, max_err, sqnr, pass);
    if WL == 16
        fprintf('  <- CHOSEN (Q4.12)');
    end
    fprintf('\n');
end

fprintf('\nTolerance: %.4f\n', TOLERANCE);

% Find minimum passing WL
min_pass_WL = word_lengths(find(results(:,3) < TOLERANCE, 1, 'first'));
fprintf('Minimum WL meeting tolerance: %d-bit (Q%d.%d)\n', ...
        min_pass_WL, IL, min_pass_WL - IL);
fprintf('Chosen WL for HLS: 16-bit Q4.12\n\n');

% ── Plot ──────────────────────────────────────────────────────────────
figure('Name','E1.2 Word Length Sweep','Position',[100 100 800 500]);

subplot(1,2,1);
max_errors = results(:,3);
bar(word_lengths, max_errors, 'FaceColor', [0.2 0.5 0.8]);
hold on;
yline(TOLERANCE, 'r--', 'LineWidth', 2, 'Label', 'Tolerance 0.0005');
set(gca, 'YScale', 'log');
xlabel('Word Length (bits)');
ylabel('Max Error (log scale)');
title('Max Quantisation Error vs Word Length');
xticks(word_lengths);
grid on;

subplot(1,2,2);
sqnr_vals = results(:,4);
bar(word_lengths, sqnr_vals, 'FaceColor', [0.2 0.7 0.4]);
hold on;
yline(50, 'r--', 'LineWidth', 2, 'Label', '50 dB threshold');
xlabel('Word Length (bits)');
ylabel('SQNR (dB)');
title('SQNR vs Word Length');
xticks(word_lengths);
grid on;

saveas(gcf, 'reports/E1_2_word_length_sweep_plot.png');
fprintf('Plot saved: reports/E1_2_word_length_sweep_plot.png\n');

% ── Save results ──────────────────────────────────────────────────────
fid = fopen('reports/E1_2_word_length_sweep_results.txt', 'w');
fprintf(fid, 'E1.2 Word Length Sweep Results\n');
fprintf(fid, 'MPIC v1.0 — norm_float range [%.4f, %.4f]\n\n', ...
        min(norm_float(:)), max(norm_float(:)));
fprintf(fid, '%-6s %-6s %-12s %-10s %-10s %-6s\n', ...
        'WL','FL','Resolution','Max_Error','SQNR_dB','PASS');
for i = 1:length(word_lengths)
    WL   = word_lengths(i);
    FL   = WL - IL;
    pass = results(i,3) < TOLERANCE;
    fprintf(fid, '%-6d %-6d %-12.6f %-10.6f %-10.2f %-6d\n', ...
            WL, FL, 1/2^FL, results(i,3), results(i,4), pass);
end
fprintf(fid, '\nMinimum passing WL : %d-bit\n', min_pass_WL);
fprintf(fid, 'Chosen for HLS     : 16-bit Q4.12\n');
fclose(fid);
fprintf('Results saved: reports/E1_2_word_length_sweep_results.txt\n');
fprintf('\nE1.2 COMPLETE\n');


% ════════════════════════════════════════════════════════════════════
function H = build_mel_filterbank_no_norm(sr, n_fft, n_mels)
    hz_to_mel = @(f) 2595 * log10(1 + f/700);
    mel_to_hz = @(m) 700 * (10.^(m/2595) - 1);
    mel_pts   = linspace(hz_to_mel(0), hz_to_mel(sr/2), n_mels+2);
    hz_pts    = mel_to_hz(mel_pts);
    freqs     = linspace(0, sr/2, n_fft/2+1);
    H         = zeros(n_mels, n_fft/2+1);
    for m = 1:n_mels
        lo  = hz_pts(m);
        cen = hz_pts(m+1);
        hi  = hz_pts(m+2);
        rising  = (freqs - lo)  ./ (cen - lo + 1e-10);
        falling = (hi - freqs)  ./ (hi - cen + 1e-10);
        H(m,:)  = max(0, min(rising, falling));
    end
end
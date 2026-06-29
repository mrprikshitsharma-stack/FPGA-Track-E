% E1_3_crosscheck.m
% Epic E1, Task 3 - Cross-check all 10 golden vectors
% Track E, Project STREAMSENSE
%
% HOW TO RUN:
%   >> cd('D:/FPGA-Track-E')
%   >> run('MATLAB/E1_3_crosscheck.m')
%
% PURPOSE:
%   Run full MPIC pipeline on all 10 golden vectors
%   Compare against Track A golden normalized outputs
%   All 10 must pass norm_err < 0.0005 (cross-impl tolerance)

clear; close all;

fprintf('E1.3 - Cross-check All 10 Golden Vectors\n');
fprintf('==========================================\n\n');

DEPLOY = 'D:\FPGA-Track-E\golden_vectors_10_matlab';

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

% ── All 10 golden vectors ─────────────────────────────────────────────
gv_names = {
    'GV_00_yes',  'GV_01_no',   'GV_02_up',   'GV_03_down', 'GV_04_left', ...
    'GV_05_right','GV_06_on',   'GV_07_off',  'GV_08_stop', 'GV_09_go'
};

n_gv = length(gv_names);

% Results table
mel_errors  = zeros(1, n_gv);
norm_errors = zeros(1, n_gv);
fp_errors   = zeros(1, n_gv);
sqnr_vals   = zeros(1, n_gv);
pass_flags  = zeros(1, n_gv);

% Mel filterbank — build once, reuse for all vectors
H = build_mel_filterbank_no_norm(SR, N_FFT, N_MELS);
win = hann(N_FFT, 'periodic');

fprintf('%-14s %-12s %-12s %-10s %-10s %-6s\n', ...
        'Vector', 'Mel_err(dB)', 'Norm_err', 'FP_err', 'SQNR(dB)', 'PASS');
fprintf('%s\n', repmat('-', 1, 68));

for i = 1:n_gv
    gv = gv_names{i};
    
    % ── Load raw audio ────────────────────────────────────────────────
    fid = fopen(fullfile(DEPLOY,'raw',[gv '.bin']),'rb');
    raw = fread(fid, FRAME_LEN, 'float32')';
    fclose(fid);
    
    % ── STFT ─────────────────────────────────────────────────────────
    n_frames = 1 + floor((FRAME_LEN - N_FFT) / HOP);
    S_power  = zeros(N_FFT/2+1, n_frames);
    for t = 1:n_frames
        s            = (t-1)*HOP + 1;
        chunk        = raw(s : s+N_FFT-1);
        X            = fft(chunk(:) .* win(:), N_FFT);
        S_power(:,t) = abs(X(1:N_FFT/2+1)).^2;
    end
    
    % ── Mel + log + norm ─────────────────────────────────────────────
    mel_power  = H * S_power;
    mel_db     = single(max(10 .* log10(mel_power + LOG_EPS), CLIP_FLOOR));
    norm_float = single((mel_db - GLOBAL_MEAN) / GLOBAL_STD);
    
    % ── Fixed-point Q4.12 ────────────────────────────────────────────
    WL = 16; FL = 12; scale = 2^FL;
    norm_rounded = round(norm_float * scale);
    norm_clamped = min(max(norm_rounded, -2^(WL-1)), 2^(WL-1)-1);
    norm_fixed   = single(norm_clamped / scale);
    
    fp_err  = max(abs(norm_float(:) - norm_fixed(:)));
    sig_pwr = mean(norm_float(:).^2);
    nse_pwr = mean((norm_float(:) - norm_fixed(:)).^2);
    sqnr    = 10 * log10(sig_pwr / (nse_pwr + 1e-12));
    
    % ── vs Track A golden ────────────────────────────────────────────
    fid = fopen(fullfile(DEPLOY,'mel',[gv '_mel.bin']),'rb');
    mel_golden = single(reshape(fread(fid, N_MELS*97, 'float32=>single'), [N_MELS, 97]));
    fclose(fid);
    
    fid = fopen(fullfile(DEPLOY,'normalized',[gv '_norm.bin']),'rb');
    norm_golden = single(reshape(fread(fid, N_MELS*97, 'float32=>single'), [N_MELS, 97]));
    fclose(fid);
    
    mel_err  = max(abs(mel_db(:)     - mel_golden(:)));
    norm_err = max(abs(norm_float(:) - norm_golden(:)));
    pass     = norm_err < TOLERANCE;
    
    mel_errors(i)  = mel_err;
    norm_errors(i) = norm_err;
    fp_errors(i)   = fp_err;
    sqnr_vals(i)   = sqnr;
    pass_flags(i)  = pass;
    
    fprintf('%-14s %-12.4e %-12.4e %-10.6f %-10.2f %-6d', ...
            gv, mel_err, norm_err, fp_err, sqnr, pass);
    if ~pass
        fprintf('  *** FAIL ***');
    end
    fprintf('\n');
end

% ── Summary ──────────────────────────────────────────────────────────
fprintf('%s\n', repmat('-', 1, 68));
fprintf('\nSUMMARY:\n');
fprintf('  Vectors tested  : %d\n', n_gv);
fprintf('  PASS            : %d\n', sum(pass_flags));
fprintf('  FAIL            : %d\n', sum(~pass_flags));
fprintf('  Max norm_err    : %.4e  (tolerance %.4f)\n', max(norm_errors), TOLERANCE);
fprintf('  Max fp_err      : %.6f\n', max(fp_errors));
fprintf('  Min SQNR        : %.2f dB\n', min(sqnr_vals));
if all(pass_flags)
    fprintf('  Overall         : ALL PASS\n\n');
else
    fprintf('  Overall         : *** FAIL ***\n\n');
end

% ── Plot ─────────────────────────────────────────────────────────────
labels = cellfun(@(x) x(6:end), gv_names, 'UniformOutput', false);

figure('Name','E1.3 Cross-check','Position',[100 100 900 500]);

subplot(1,2,1);
bar(norm_errors, 'FaceColor', [0.2 0.5 0.8]);
hold on;
yline(TOLERANCE, 'r--', 'LineWidth', 2, 'Label', 'Tolerance 0.0005');
set(gca, 'XTickLabel', labels, 'XTick', 1:n_gv);
ylabel('Norm max error');
title('Norm Error vs Track A — All 10 Vectors');
xtickangle(45); grid on;

subplot(1,2,2);
bar(sqnr_vals, 'FaceColor', [0.2 0.7 0.4]);
hold on;
yline(50, 'r--', 'LineWidth', 2, 'Label', '50 dB threshold');
set(gca, 'XTickLabel', labels, 'XTick', 1:n_gv);
ylabel('SQNR (dB)');
title('SQNR Q4.12 — All 10 Vectors');
xtickangle(45); grid on;

saveas(gcf, 'reports/E1_3_crosscheck_plot.png');
fprintf('Plot saved: reports/E1_3_crosscheck_plot.png\n');

% ── Save report ──────────────────────────────────────────────────────
fid = fopen('reports/E1_3_crosscheck_results.txt', 'w');
fprintf(fid, 'E1.3 Cross-check Results — All 10 Golden Vectors\n');
fprintf(fid, 'Fixed-point: Q4.12 (16-bit)  Tolerance: 0.0005\n\n');
fprintf(fid, '%-14s %-12s %-12s %-10s %-10s %-6s\n', ...
        'Vector','Mel_err_dB','Norm_err','FP_err','SQNR_dB','PASS');
for i = 1:n_gv
    fprintf(fid, '%-14s %-12.4e %-12.4e %-10.6f %-10.2f %-6d\n', ...
            gv_names{i}, mel_errors(i), norm_errors(i), ...
            fp_errors(i), sqnr_vals(i), pass_flags(i));
end
fprintf(fid, '\nOverall: %d/10 PASS\n', sum(pass_flags));
fprintf(fid, 'Max norm_err: %.4e\n', max(norm_errors));
fclose(fid);
fprintf('Results saved: reports/E1_3_crosscheck_results.txt\n');
fprintf('\nE1.3 COMPLETE\n');


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
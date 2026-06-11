% matlab/ex2_fixed_point.m
load('D:\FPGA_Track_E\MATLAB\ex2_float_feat.mat'); % loads feat_float and sig_f
% ---- Manual Q-format fixed-point implementation ----
% We use integer arithmetic; scale by 2^F to simulate Q(I.F)
% For simplicity, implement at the output stage only:
% Convert feat_float to fixed-point and back; measure SQNR.
wl_list = [8, 10, 12, 14, 16];
sqnr = zeros(size(wl_list));
for i = 1:length(wl_list)
    WL = wl_list(i); F = WL - 4; % 4 integer bits (range ~-8..8)
    scale = 2^F;
    % Quantise
    q_int = round(feat_float * scale);
    q_int = max(min(q_int, 2^(WL-1)-1), -2^(WL-1)); % saturate
    feat_fp = q_int / scale; % back to float for comparison
    % SQNR
    noise = feat_float - feat_fp;
    sqnr(i) = 20*log10(norm(feat_float) / (norm(noise) + 1e-12));
    fprintf('WL=%2d Q%d.%d SQNR=%.1f dB\n', WL, WL-F, F, sqnr(i));
end
figure; plot(wl_list, sqnr, 'b-o');
xlabel('Word length (bits)'); ylabel('SQNR (dB)');
title('Fixed-point SQNR vs word length'); grid on;
saveas(gcf,'D:\FPGA_Track_E\reports\ex2_sqnr_plot.png');
% Choose the minimum WL that gives SQNR >= 50 dB (a reasonable floor)
chosen_WL = wl_list(find(sqnr >= 50, 1, 'first'));
fprintf('Chosen WL: %d bits (first WL with SQNR >= 50 dB)\n', chosen_WL);
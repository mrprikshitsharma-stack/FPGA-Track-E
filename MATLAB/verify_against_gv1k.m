% verify_against_gv1k.m
%
% Compares MATLAB MPIC pipeline output against pre-generated GV1K
% golden vectors (.bin files, float32 LE, shape [64,97]).
%
% Run AFTER mpic_preprocess.m is on your MATLAB path.
%
% DIRECTORY STRUCTURE EXPECTED:
%   golden_vectors_1000/
%       normalized/   <- GV1K_NNNN_<label>_norm.bin files (1000 of them)
%       wav/          <- GV1K_NNNN_<label>.wav  (if you have them)
%   OR just point GV1K_NORM_DIR at wherever the .bin files live.
%
% The manifest.json in golden_vectors_1000/ maps each GV1K index to the
% original wav path — use that to locate the source WAV file.

clear; clc;

%% ── Config ────────────────────────────────────────────────────────────────────
GV1K_NORM_DIR = 'C:\STREAMSENSE\golden_vectors_1000\normalized';
GV1K_WAV_DIR  = 'C:\STREAMSENSE\golden_vectors_1000\wav';   % adjust if different
MANIFEST_PATH = 'C:\STREAMSENSE\golden_vectors_1000\manifest.json';

MAX_ABS_TOL   = 5e-4;   % MPIC v1.0 gate: max element-wise |diff| < 5e-4
N_MELS        = 64;
EXPECTED_T    = 97;

%% ── Load manifest ─────────────────────────────────────────────────────────────
fid    = fopen(MANIFEST_PATH, 'r');
raw    = fread(fid, '*char')';
fclose(fid);
mf     = jsondecode(raw);
entries = mf.entries;   % cell array of structs
N_TOTAL = length(entries);
fprintf('Manifest loaded: %d entries\n', N_TOTAL);

%% ── Verify loop ───────────────────────────────────────────────────────────────
n_pass = 0;
n_fail = 0;
max_errors = zeros(N_TOTAL, 1, 'single');

for i = 1:N_TOTAL
    entry = entries{i};
    gv_id = entry.gv_id;   % e.g. "GV1K_0000"

    % Locate the .bin file
    bin_files = dir(fullfile(GV1K_NORM_DIR, [gv_id, '_*_norm.bin']));
    if isempty(bin_files)
        fprintf('[WARN] %s: no .bin file found, skipping\n', gv_id);
        n_fail = n_fail + 1;
        continue;
    end
    bin_path = fullfile(GV1K_NORM_DIR, bin_files(1).name);

    % Load golden vector [64 x 97]
    fid     = fopen(bin_path, 'rb');
    golden  = fread(fid, N_MELS * EXPECTED_T, 'float32');
    fclose(fid);
    golden  = reshape(golden, [N_MELS, EXPECTED_T]);

    % Find WAV — try wav subdir first, fall back to original source path
    wav_name = bin_files(1).name;
    wav_name = strrep(wav_name, '_norm.bin', '.wav');
    wav_path = fullfile(GV1K_WAV_DIR, wav_name);
    if ~isfile(wav_path)
        % Try the original source_file from manifest
        if isfield(entry, 'source_file')
            wav_path = entry.source_file;
        end
    end

    if ~isfile(wav_path)
        fprintf('[WARN] %s: WAV not found at %s\n', gv_id, wav_path);
        n_fail = n_fail + 1;
        continue;
    end

    % Run MATLAB pipeline
    try
        matlab_mel = mpic_preprocess(wav_path);
    catch err
        fprintf('[ERROR] %s: %s\n', gv_id, err.message);
        n_fail = n_fail + 1;
        continue;
    end

    % Compare
    diff = abs(single(matlab_mel) - single(golden));
    max_err = max(diff(:));
    max_errors(i) = max_err;

    if max_err < MAX_ABS_TOL
        n_pass = n_pass + 1;
    else
        n_fail = n_fail + 1;
        if n_fail <= 5
            fprintf('[FAIL] %s  max_abs_err=%.6f  (tol=%.1e)\n', gv_id, max_err, MAX_ABS_TOL);
        end
    end
end

%% ── Summary ───────────────────────────────────────────────────────────────────
pct = 100.0 * n_pass / max(n_pass + n_fail, 1);
fprintf('\n=== GV1K Verification Summary ===\n');
fprintf('  Total checked : %d\n', n_pass + n_fail);
fprintf('  Pass          : %d\n', n_pass);
fprintf('  Fail          : %d\n', n_fail);
fprintf('  Pass rate     : %.2f%%\n', pct);
fprintf('  Mean max_err  : %.6f dB\n', mean(max_errors(max_errors > 0)));
fprintf('  Max  max_err  : %.6f dB\n', max(max_errors));

if pct >= 90.0
    fprintf('\n[OK] MPIC gate PASSED (>=90%% within 5e-4)\n');
else
    fprintf('\n[FAIL] MPIC gate FAILED (<90%% within 5e-4)\n');
    fprintf('       Check hann_periodic() and htk_mel_filterbank() carefully.\n');
end

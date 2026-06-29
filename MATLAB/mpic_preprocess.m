function norm_mel = mpic_preprocess(wav_path)
% MPIC_PREPROCESS  Exact replica of STREAMSENSE mel_pipeline.py (MPIC v1.0)
%
% Replicates torchaudio.transforms.MelSpectrogram with the exact same
% filterbank as PyTorch/torchaudio — HTK mel scale, unnormalized triangular
% filterbanks, periodic Hann window, center=False framing.
%
% INPUT
%   wav_path : path to a WAV file (16 kHz mono, or will be converted)
%
% OUTPUT
%   norm_mel : [64 x 97] float32 normalised log-mel spectrogram
%              Ready to reshape to [1,1,64,97] for ONNX input.
%
% MPIC v1.0 constants (FROZEN — do not change):
%   sample_rate  = 16000
%   n_fft        = 512
%   hop_length   = 160
%   n_mels       = 64
%   center       = false   -> T = floor((16000-512)/160)+1 = 97
%   window       = hann periodic
%   power        = 2.0
%   mel_scale    = HTK  (NOT Slaney)
%   filterbank_norm = none  (NOT area-normalised)
%   log          = 10*log10(mel + 1e-10)
%   clip_floor   = -80 dB
%   global_mean  = -30.785545 dB
%   global_std   =  22.157099 dB
%
% USAGE
%   mel = mpic_preprocess('path/to/yes/0a2b400e_nohash_0.wav');
%   % mel is [64,97] — matches the .bin golden vectors exactly

    %% ── MPIC v1.0 frozen constants ────────────────────────────────────────────
    SR           = 16000;
    FRAME_LEN    = 16000;   % pad/crop target
    N_FFT        = 512;
    HOP_LENGTH   = 160;
    N_MELS       = 64;
    LOG_EPS      = 1e-10;
    CLIP_FLOOR   = -80.0;
    GLOBAL_MEAN  = -30.785545;
    GLOBAL_STD   =  22.157099;
    EXPECTED_T   = floor((FRAME_LEN - N_FFT) / HOP_LENGTH) + 1;  % 97

    %% ── Step 1-3: Load, mono, pad/crop ───────────────────────────────────────
    [wav, fs] = audioread(wav_path);

    % Step 1: resample if needed
    if fs ~= SR
        wav = resample(wav, SR, fs);
    end

    % Step 2: stereo -> mono (mean channels, matches PyTorch mean(dim=0))
    if size(wav, 2) > 1
        wav = mean(wav, 2);
    end
    wav = wav(:);   % column vector

    % Step 3: pad zeros on right or crop to exactly FRAME_LEN samples
    L = length(wav);
    if L < FRAME_LEN
        wav = [wav; zeros(FRAME_LEN - L, 1)];
    elseif L > FRAME_LEN
        wav = wav(1:FRAME_LEN);
    end

    %% ── Step 4: STFT with periodic Hann window, center=False ─────────────────
    % Periodic Hann: w[n] = 0.5*(1 - cos(2*pi*n/N_FFT)), n=0..N_FFT-1
    % This is torch.hann_window(N_FFT, periodic=True) — same as MATLAB hann
    % BUT MATLAB's hann(N) is symmetric (N+1 periodic). We need periodic form.
    win = hann_periodic(N_FFT);

    % center=False: frames start at sample 1,161,321,...
    % PyTorch: n_frames = floor((T - N_FFT) / hop) + 1 = 97
    % No reflection padding (center=False means raw signal framing)
    n_frames = floor((FRAME_LEN - N_FFT) / HOP_LENGTH) + 1;
    assert(n_frames == EXPECTED_T, 'Frame count mismatch: expected %d got %d', EXPECTED_T, n_frames);

    % Build STFT manually to match PyTorch exactly
    n_freq = N_FFT / 2 + 1;   % 257
    stft_power = zeros(n_freq, n_frames, 'single');

    for k = 1:n_frames
        start = (k-1)*HOP_LENGTH + 1;
        frame = wav(start : start + N_FFT - 1) .* win;
        X = fft(frame, N_FFT);
        stft_power(:, k) = single(abs(X(1:n_freq)).^2);
    end

    %% ── Step 5: HTK mel filterbank (unnormalised) ────────────────────────────
    fb = htk_mel_filterbank(SR, N_FFT, N_MELS);   % [N_MELS x n_freq]
    mel = fb * double(stft_power);                  % [64 x 97]

    %% ── Step 6: Log scale ────────────────────────────────────────────────────
    mel_db = 10.0 * log10(mel + LOG_EPS);

    %% ── Step 7: Clip floor ───────────────────────────────────────────────────
    mel_db = max(mel_db, CLIP_FLOOR);

    %% ── Step 8: Z-score normalisation ───────────────────────────────────────
    norm_mel = single((mel_db - GLOBAL_MEAN) / GLOBAL_STD);   % [64 x 97]

    assert(isequal(size(norm_mel), [N_MELS, EXPECTED_T]), ...
        'Output shape mismatch: expected [64,97]');
end


%% ════════════════════════════════════════════════════════════════════════════
function w = hann_periodic(N)
% HANN_PERIODIC  Periodic Hann window — matches torch.hann_window(N, periodic=True)
%
% torch.hann_window(N) = 0.5 * (1 - cos(2*pi*n/N)),  n = 0..N-1
% This differs from MATLAB's hann(N) which is symmetric (divides by N-1).
    n = (0:N-1)';
    w = 0.5 * (1 - cos(2*pi*n/N));
end


%% ════════════════════════════════════════════════════════════════════════════
function fb = htk_mel_filterbank(sr, n_fft, n_mels)
% HTK_MEL_FILTERBANK  Replicates torchaudio's HTK mel filterbank exactly.
%
% torchaudio default: mel_scale='htk', norm=None (no area normalisation)
% This matches librosa's mel_filters(sr, n_fft, n_mels, htk=True, norm=None)
%
% Returns fb: [n_mels x (n_fft/2+1)] single matrix

    n_freqs = n_fft / 2 + 1;   % 257 frequency bins

    % HTK mel conversion: m = 2595 * log10(1 + f/700)
    hz_to_mel = @(f) 2595.0 * log10(1.0 + f / 700.0);
    mel_to_hz = @(m) 700.0 * (10.^(m / 2595.0) - 1.0);

    % Frequency axis of STFT bins
    fft_freqs = linspace(0, sr/2, n_freqs);   % 0 to 8000 Hz, 257 points

    % Mel axis: n_mels+2 equally spaced points from 0 to sr/2 in mel
    mel_min = hz_to_mel(0);
    mel_max = hz_to_mel(sr / 2);
    mel_points = linspace(mel_min, mel_max, n_mels + 2);
    hz_points  = mel_to_hz(mel_points);       % [n_mels+2] in Hz

    % Build triangular filters
    fb = zeros(n_mels, n_freqs);
    for m = 1:n_mels
        f_left   = hz_points(m);
        f_center = hz_points(m + 1);
        f_right  = hz_points(m + 2);

        for k = 1:n_freqs
            f = fft_freqs(k);
            if f >= f_left && f <= f_center
                fb(m, k) = (f - f_left) / (f_center - f_left);
            elseif f > f_center && f <= f_right
                fb(m, k) = (f_right - f) / (f_right - f_center);
            end
        end
    end

    fb = single(fb);
end

N = 512;
w = hann(N);
sig = randn(N,1);
spec = abs(fft(sig .* w/N)).^2;

plot(10*log10(spec(1:N/2+1)));
xlabel('Bin');
ylabel('Power (dB)');
title('Ex1: Toolchain check FFT');

saveas(gcf,'../reports/ex1_matlab_fft.png');

disp('MATLAB Signal Processing Toolbox OK');

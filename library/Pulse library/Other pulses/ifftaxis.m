function [time,y] = ifftaxis(f,fy)
%fy = must be symmetric around 0

% N = length(f);
% nifft = 2^(nextpow2(N));
y = ifftshift(ifft(fftshift(fy(:))));

dt = 1/2/f(end);
time = dt*(0:length(f)-1).';
% y = y(round(length(y)/2) + round(-length(f)/2:length(f)/2-1));

end
function y = shortCORPSE(t,deg_angle)
% y = shortCORPSE(t,deg_angle)
%See arXiv:1209.4247v3
%
%Total duration should be = 2.3*pi

k = asind(sind(deg_angle/2)/2);
durations = [deg_angle/2-k 360-2*k deg_angle/2-k];
phase = [0 pi 0];

timings = round(cumsum(durations)/sum(durations)*length(t));
timings = [0 max(1,min(length(t),timings))];

y = zeros(length(t),2);
for ct = 1:length(timings)-1
    y((timings(ct)+1):timings(ct+1),1) = cos(phase(ct));
    y((timings(ct)+1):timings(ct+1),2) = sin(phase(ct));
end

end


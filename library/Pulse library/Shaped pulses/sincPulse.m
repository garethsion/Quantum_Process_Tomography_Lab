function y = sincPulse(time,deltaF)
%y = sincPulse(time,deltaF)
%Bandwidth = 2*deltaF

time = time - time(1);

if(~isempty(time))
    y = [sinc((time(:)-time(end)/2)*2*deltaF) zeros(length(time),1)]; %real only so that 2sided in frequency
else
    y = zeros(0,2);
end
end
function y = freqComb(time,deltaF,BW,shift)
%deltaF = one sided excitation bw for single sinc 
%BW = full frequency comb
%Period = 4*DeltaF
%shift = shift between sinc functions to reduce power

%BETTER START FROM FREQ DOMAIN

if(~isempty(time))
    per = 4*deltaF;
    N = round(BW/per/2);

    sincFun = sincPulse(time,deltaF*1.1); %slightly larger to compensate nonlinear spin behaviour
    sincFun = sincFun(:,1);

    y = zeros(length(time),2);
    for ct = -N:N
        freq = ct*per;
        I = sincFun.*cos(2*pi*freq*(time(:)+ct*shift));
        Q = sincFun.*sin(2*pi*freq*(time(:)+ct*shift));
        
        newtimeidx = round(ct*shift/(time(2)-time(1)))+(0:length(time)-1);
        newtimeidx = newtimeidx(newtimeidx >= 1 & newtimeidx <= length(time));
        newtimeidx2 = length(time)-newtimeidx(end:-1:1)+1;
        y(newtimeidx,:) = y(newtimeidx,:) + [I(newtimeidx2) Q(newtimeidx2)];
    end
else
    y = zeros(0,2);
end    

end
function y = PB2eqpow(t,deg_angle)
    if(deg_angle ~= 0)
        amp = [360 360 360 360 deg_angle];
    else
        amp = [360 360 360 360];
    end
    phi = acosd(-deg_angle/1440);
    phase = [90 -phi -phi 90 0];
    
    subtime = floor(length(t)/length(amp));
    y = zeros(length(t),2);
    
    for ct = 1:length(amp)
        y(1+(ct-1)*subtime:ct*subtime,1) = amp(ct)*cosd(phase(ct));
        y(1+(ct-1)*subtime:ct*subtime,2) = amp(ct)*sind(phase(ct));
    end
    
    y = y/max(abs(y(:,1)+1i*y(:,2)));
end
function y = NB2(t,deg_angle)
    amp = [180 360 180 deg_angle];
    phi = acosd(-deg_angle/720);
    phase = [90 -phi 90 0];
    
    subtime = floor(length(t)/length(amp));
    y = zeros(length(t),2);
    
    for ct = 1:length(amp)
        y(1+(ct-1)*subtime:ct*subtime,1) = amp(ct)*cosd(phase(ct));
        y(1+(ct-1)*subtime:ct*subtime,2) = amp(ct)*sind(phase(ct));
    end
    
    y = y/max(abs(y(:,1)+1i*y(:,2)));
end
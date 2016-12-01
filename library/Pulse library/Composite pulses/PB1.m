function y = PB1(t,deg_angle)
    amp = [360 720 360 deg_angle];
    phi = acos(-deg_angle/1440);
    phase = [phi -phi phi 0];
    
    subtime = floor(length(t)/length(amp));
    y = zeros(length(t),2);
    
    for ct = 1:length(amp)
        y(1+(ct-1)*subtime:ct*subtime,1) = amp(ct)*cos(phase(ct));
        y(1+(ct-1)*subtime:ct*subtime,2) = amp(ct)*sin(phase(ct));
    end
    
    y = y/max(abs(y(:,1)+1i*y(:,2)));
end
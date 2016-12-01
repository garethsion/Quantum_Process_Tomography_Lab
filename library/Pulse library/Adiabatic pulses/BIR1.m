function y = BIR1(t,angle,DeltaF,varargin)
%B1-insensitive adiabatic rotation
    %Have a even number of point to get nice symmetric functions
    dt = t(2)-t(1);
    Nhalf = floor(length(t)/2);
    time = (0:dt:(2*Nhalf-1)*dt).';
    
    if(isempty(varargin))
        [F1,F2] = AdiaModFun(time);
    else
        [F1,F2] = AdiaModFun(time,varargin{1});
    end
    
    %Shift from middle
    F1 = [F1(Nhalf+(1:Nhalf)); F1(1:Nhalf)];
    F2 = [F2(Nhalf+(1:Nhalf)); F2(1:Nhalf)];
    
    %Create phase jump for arbitrary rotation angle
    phase = zeros(2*Nhalf,1);
    phase(Nhalf+(1:Nhalf)) = pi + angle*pi/180;
    
    I = F1.*cos(2*pi*cumsum(DeltaF.*F2)*dt + phase);
    Q = F1.*sin(2*pi*cumsum(DeltaF.*F2)*dt + phase);
    
    y = zeros(length(t),2);
    y(1:2*Nhalf,:) = [I Q];
end
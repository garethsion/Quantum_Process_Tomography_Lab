function y = BIR4(t,angle,DeltaF,varargin)
%B1-insensitive adiabatic rotation, symmetrized
    %Have a even number of point to get nice symmetric functions
    dt = t(2)-t(1);
    Nquarter = floor(length(t)/4);
    time = (0:dt:(2*Nquarter-1)*dt).';
    
    if(isempty(varargin))
        [F1,F2] = AdiaModFun(time);
    else
        [F1,F2] = AdiaModFun(time,varargin{1});
    end
    
    %Shift from middle
    F1 = [F1(Nquarter+(1:Nquarter)); F1(1:Nquarter)]; F1 = [F1; F1];
    F2 = [F2(Nquarter+(1:Nquarter)); F2(1:Nquarter)]; F2 = [F2; F2];
    
    %Create phase jump for arbitrary rotation angle
    phase = zeros(4*Nquarter,1);
    phase(Nquarter+(1:2*Nquarter)) = pi + angle/2*pi/180;
    phase(3*Nquarter+(1:Nquarter)) = 0;
    
    I = F1.*cos(2*pi*cumsum(DeltaF.*F2)*dt + phase);
    Q = F1.*sin(2*pi*cumsum(DeltaF.*F2)*dt + phase);
    
    y = zeros(length(t),2);
    y(1:4*Nquarter,:) = [I Q];
end
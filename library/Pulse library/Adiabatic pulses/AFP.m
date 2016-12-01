function y = AFP(t,DeltaF,varargin)
%Adibatic full passage
%NOT PHASE CONTINUOUS !!!???
    %From Tannus
    if(~isempty(t))
        dt = t(2)-t(1);
        t = (0:dt:(length(t)-1)*dt).';

        if(isempty(varargin))
            [F1,F2] = AdiaModFun(t);
        else
            [F1,F2] = AdiaModFun(t,varargin{1});
        end
        I = F1.*cos(2*pi*DeltaF*cumsum(F2)*dt);
        Q = F1.*sin(2*pi*DeltaF*cumsum(F2)*dt);
    else
        I = [];
        Q = [];
    end

    y = [I Q];
end
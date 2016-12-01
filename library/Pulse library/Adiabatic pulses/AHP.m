function y = AHP(t,DeltaF,varargin)
%Adibatic half passage    
    t = t(:) - t(1);
    time = linspace(0,2*t(end),2*length(t));
    if(isempty(varargin))
        y = AFP(time,DeltaF);
    else
        y = AFP(time,DeltaF,varargin{1});
    end
    
    y = y(1:length(t),:);
end
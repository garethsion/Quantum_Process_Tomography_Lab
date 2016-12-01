function [F1,F2] = AdiaModFun(t,varargin)
%Modulation functions
%F1 is the amplitude modulation, corresponding to a X field
%F2 is the frequency modulation, corresponding to a Z field

    t = t - t(1);
    tau = 2*t/t(end) - 1;
    F1min = 0.01; %must be < 1
    
    %Defaut: Chirp
    F1 = 1*ones(size(tau)); 
    F2 = tau;
    
    %Other functions
    if(~isempty(varargin))
        switch(lower(varargin{1}))
            case 'lorentz'
                beta = (1-F1min)/(F1min*tau(end)^2);
                F1 = 1./(1+beta*tau.^2);
                F2 = tau./(1+beta*tau.^2)+1/sqrt(beta)*atan(sqrt(beta)*tau);
            
            case 'hs'
                beta = asech(F1min)/tau(end);
                F1 = sech(beta*tau);
                F2 = tanh(beta*tau)/tanh(beta);
                
%             case 'hs8'
%                 n = 8;
%                 beta = asech(F1min)/tau(end)^n;
%                 F1 = sech(beta*tau.^n);
%                 F2 = cumsum(F1.^2)*dt;
            
            case 'gauss'
                beta = sqrt(-2*log(F1min))/tau(end);
                F1 = exp(-beta^2/2*tau.^2);
                F2 = erf(beta*tau)/erf(beta);
                
            case 'hanning'
                F1 = 1/2*(1+cos(pi*tau));
                F2 = tau + 4/(3*pi)*sin(pi*tau).*(1+1/4*cos(pi*tau));
                
%             case 'sin20'
%                 n = 20;
%                 F1 = 1 - abs(sin(pi*tau/2).^n);
%                 F2 = tau - cumsum(sin(pi*tau/2).^n.*(1+cos(pi*tau/2).^2))*dt;
        end
    end

end


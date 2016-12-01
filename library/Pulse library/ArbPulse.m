function y = ArbPulse(t)
    tau = 100;
    f0 = 0.1;
    
    wr = 1-exp(-t/tau);
    df = f0*exp(-t/tau);
    y = wr.*sin(2*pi*df.*t);  
end
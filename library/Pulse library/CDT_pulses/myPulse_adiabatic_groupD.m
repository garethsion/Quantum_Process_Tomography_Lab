function y = myPulse_adiabatic_groupD( t, init_freq, rate, phase)

freq = init_freq + rate*t;
y(1:length(t),1) = sin(freq.*t + phase);
y(1:length(t),2) = cos(freq.*t + phase);

end

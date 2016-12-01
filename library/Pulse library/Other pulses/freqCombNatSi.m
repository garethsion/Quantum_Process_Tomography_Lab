function y = freqCombNatSi(time,A,shift)
%A en MHz
y = freqComb(time,A/2*1e-3,10e-3,shift);
end


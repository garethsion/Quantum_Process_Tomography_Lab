function value = logsweep(point,step,start) 
    % start = start exponent, i.e 5 for 10^5 ns
    % formula for calculating step:
    % step = (endexponent-startexponent)/(number of points-1) 
    value = 10.^(start+step*(point-1))-10.^start;
end

function value = sqrtsweep(point,step) 
    % formula for calculating step:
    % step = sqrt(EndPoint-StartPoint)/(number of points-1) 
    value = (step*(point-1)).^2;
end

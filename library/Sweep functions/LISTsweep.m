function value = LISTsweep(point,~) 
    % IMPORTANT, set start point to 0!
    
    %listed_values = [4,1,0.1,0,-0.1,-1,-4]; %1dimensional
    listed_values = [-14.5,-14,-13.5,-13,-12,-11,];
    Nlist = numel(listed_values);
    idx = mod(point,Nlist);
    if any(idx == 0)
        idx(idx == 0) = Nlist;
    end
    value = listed_values(idx);
    if point == 1
        value = 0;
    end
end

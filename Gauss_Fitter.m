function Gauss_Fitter = Gauss_Fitter(time_data, dat)
    % Gauss_Fitter takes time data and rotation data and performs a 
    % Gaussian fit to said data. It returns the area under the fitted 
    % curve 
    if mean(dat) > 0
        f = fit(time_data, dat, 'gauss1');
        area = f.a1;      
    else 
        f = fit(time_data, - dat, 'gauss1');
        area = -f.a1;
    end
    Gauss_Fitter = area;
end
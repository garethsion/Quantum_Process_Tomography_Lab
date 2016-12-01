function y = AydanQOC(t)

load('C:\Users\Gary Wolfowicz\Desktop\Simulations Bismuth\AWG\Pulse library\AydanQOC_01.mat');

y = interp1(data(:,1),data(:,2),t*1e9);
y(isnan(y)) = 0;
y = y/max(abs(y));

end
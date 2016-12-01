function filt = CPMGIntegFilter(time)
%CPMGINTEGFILTER Summary of this function goes here
%   Detailed explanation goes here

tau = 40e-6;
tau0 = 5e-6;
tauAcq = 9e-6;

dt = time(2)-time(1);
filt = zeros(size(time));
for ct = 1:floor((time(end)-tau0-tau)/tau)
    idx = round((tau0 + tau*(ct-1)+(-tauAcq/2:dt:tauAcq/2))/dt);
    filt(max(1,min(length(time),idx))) = 1;
end

end


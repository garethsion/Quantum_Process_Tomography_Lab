function Pulse = myPulse(time,phi,theta,rabiperiod) 


% phi : angle of the axis of the rotation in the x-y plane [deg]
% theta : angle of the roation [deg]
% Rabi period [nS]
omegaR = 2*pi/rabiperiod*10^9; % 2*pi/T

Pulse = zeros(2,length(time));
sample = mean(diff(time))*10^(-9);

phi1 = acos(-theta/4/pi);
phi2 = 3*phi1;

% duration of each pulse
Tpi = pi/omegaR;
Ttheta = theta/omegaR;
% time between each pulse
Twait = 100e-9; 

% time at which the pulse occurs
Sequence = [Twait,Tpi+Twait,Tpi+2*Twait,3*Tpi+2*Twait,...
    3*Tpi+3*Twait,4*Tpi+3*Twait,4*Tpi+4*Twait,4*Tpi+4*Twait+Ttheta];


% pi-rotation along phi1
for aa = round(Sequence(1)/sample):round(Sequence(2)/sample)
    Pulse(:,aa)=[cos(phi+phi1);sin(phi+phi1)]';
end

% 2pi-rotation along phi2
for bb = round(Sequence(3)/sample):round(Sequence(4)/sample)
    Pulse(:,bb)=[cos(phi+phi2);sin(phi+phi2)]';
end

% pi-rotation along phi1
for cc = round(Sequence(5)/sample):round(Sequence(6)/sample)
    Pulse(:,cc)=[cos(phi+phi1);sin(phi+phi1)]';
end

% pi-rotation along phi1
for cc = round(Sequence(7)/sample):round(Sequence(8)/sample)
    Pulse(:,cc)=[cos(phi);sin(phi)]';
end
Pulse = Pulse';
Pulse = Pulse(1:length(time),:);
end


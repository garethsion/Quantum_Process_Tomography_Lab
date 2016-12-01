% clear all;
addpath(genpath('.\'));
S = SpinClass(1/2);

%%
Tsingle = 20;
time = (linspace(0,Tsingle,500)).';
dt = time(2)-time(1);

piPulseDuration = 0.3;
A = 1/piPulseDuration/2;

% dw = -5*linspace(-1,1,50);
dw = 0;

% pulse = A*[ones(size(time,1),1) zeros(size(time,1),1)];

% pulse = A*sincPulse(time,A);

% pulse = 1.1*0.25*freqComb(time,0.25,2,0);

% pulse = A*BB1eqpow(time,180);

% pulse = A*XY16pulse(time);

% pulse = A*PB2eqpow(time,360);

deltaF = 3;
pulse = A*AFP(time,deltaF,'hs');

% deltaF = 1;
% pulse = A*BIR4(time,180,deltaF,'hs');

% Evolution
rho0 = [1 0].';
obs = rho0;

rho = rho0;
result = zeros(length(time),1);
result(1) = abs(rho'*obs)^2;

for ct = 1:length(time)
    H0 = dw*S.Z + pulse(ct,1)*S.X - pulse(ct,2)*S.Y;
    U = expm(-1i*2*pi*H0*dt);
    rho = U*rho;
    result(ct) = abs(rho'*obs)^2;
end

figure(10)
clf(10)
subplot(2,1,1)
plot(time,pulse)
axis tight
xlabel('Time')
ylabel('Pulse amplitude (a.u.)');


subplot(2,1,2)
plot(time,result)
title(num2str(result(end),3));
axis tight
ylim([0 1])
xlabel('Time')
ylabel('State projection (a.u.)');

%%
rho0 = [1 0].';
obs = rho0;

result = zeros(length(dw),1);
for ct = 1:length(dw)
    rho = rho0;
    for ct1 = 1:length(time)
        H0 = dw(ct)*S.Z + pulse(ct1,1)*S.X - pulse(ct1,2)*S.Y;
        U = expm(-1i*2*pi*H0*dt);
        rho = U*rho;
    end
    result(ct) = abs(rho'*obs)^2;
end
figure(10)
clf(10)
plot(dw,result)
axis tight
ylim([0 1])
xlabel('Detuning (MHz)');
ylabel('State projection (a.u.)');
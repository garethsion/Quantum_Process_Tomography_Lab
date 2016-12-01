% clear all;
addpath(genpath('.\'));
S = SpinClass(1/2);

%%
piPulseDuration = 0.14;

Tsingle = 2.3*piPulseDuration;
time = (linspace(0,Tsingle,70)).';
dt = time(2)-time(1);

A = 1/piPulseDuration/2;

dw = 0;

% pulse = A*[ones(size(time,1),1) zeros(size(time,1),1)];

% pulse = A*sincPulse(time,A);

% pulse = 1.1*0.25*freqComb(time,0.25,2,0);

% pulse = A*BB1eqpow(time,180);

% pulse = A*XY16pulse(time);

% pulse = A*PB2eqpow(time,360);

% deltaF = 2;
% pulse1 = A*AFP(time,deltaF,'hs');

pulse = A*shortCORPSE(time,180);

% deltaF = 1;
% pulse = A*BIR4(time,180,deltaF,'hs');

% Evolution
rho0 = S.Y;
obs1 = S.X; obs2 = S.Y; obs3 = S.Z;
rot0 = expm(-1i*2*pi*dw*S.Z*dt);
rot = rot0;

rho = rho0;
result = zeros(length(time),3);
result(1,:) = [trace(obs1*rho0) trace(obs2*rho0) trace(obs3*rho0)];

for ct = 1:length(time)
    H0 = dw*S.Z + pulse(ct,1)*S.X - pulse(ct,2)*S.Y;
    U = expm(-1i*2*pi*H0*dt);
    rho = U*rho*U';
    rot = rot0*rot;
    rhoRot = rot'*rho*rot;
    result(ct,:) = [trace(obs1*rhoRot) trace(obs2*rhoRot) trace(obs3*rhoRot)];
end
result(:,1) = result(:,1)/trace(obs1*obs1);
result(:,2) = result(:,2)/trace(obs2*obs2);
result(:,3) = result(:,3)/trace(obs3*obs3);

figure(10)
clf(10)
subplot(2,1,1)
plot(time,pulse)
axis tight
xlabel('Time')
ylabel('Pulse amplitude (a.u.)');

subplot(2,1,2)
plot(time,real(result))
axis tight
ylim([-1 1])
xlabel('Time')
ylabel('State projection (a.u.)');
legend('X','Y','Z');

%%
figure(11)
sphere(30);
hold on
plot3(real(result(:,1)),real(result(:,2)),real(result(:,3)),'k','LineWidth',2);
hold off

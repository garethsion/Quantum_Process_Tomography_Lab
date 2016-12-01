% clear all;
addpath(genpath('.\'));
S = SpinClass(1/2);

%%
piPulseDuration = 0.14;

Tsingle = 1*piPulseDuration;
time = (linspace(0,Tsingle,100)).';
dt = time(2)-time(1);

A0 = 1/piPulseDuration/2;
A = A0*(1+linspace(-0.2,0.2,31));

dw0 = 5;
dw = dw0*linspace(-1,1,31);

pulse = [ones(size(time,1),1) zeros(size(time,1),1)];

% pulse = sincPulse(time,1);

% pulse = 1.1*0.25*freqComb(time,0.25,2,0);

% pulse = BB1eqpow(time,180);

% pulse = CORPSE(time,180);

% pulse = rCinBB(time,180);

% pulse = rSKinsC(time,180);
% 
% pulse = shortCORPSE(time,180);

% pulse = PB2eqpow(time,360);

% deltaF = 2;
% pulse = AFP(time,deltaF,'hs');

% deltaF = 1;
% pulse = BIR4(time,180,deltaF,'hs');

%%
phi0 = [1 0].';
obs = phi0;

result = zeros(length(dw),length(A));
for ctA = 1:length(A)
    disp([int2str(ctA) '/' int2str(length(A))]);
    for ctW = 1:length(dw)
        phi = phi0;
        for ct1 = 1:length(time)
            H0 = dw(ctW)*S.Z + A(ctA)*(pulse(ct1,1)*S.X - pulse(ct1,2)*S.Y);
            U = expm(-1i*2*pi*H0*dt);
            phi = U*phi;
        end
        result(ctW,ctA) = abs(phi'*obs)^2;
    end
end
%%
figure()
res = log10(result);
res(res(:) > -1) = nan;
h = imagesc(dw/dw0,A/A0-1,res.');
set(h,'alphadata',~isnan(res.'))
set(gca,'Ydir','normal');
axis tight
xlabel('Detuning (MHz)');
ylabel('Amplitude (MHz)');
title('State projection (a.u.)');
colorbar
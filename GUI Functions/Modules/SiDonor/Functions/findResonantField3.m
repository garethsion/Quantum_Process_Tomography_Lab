function [B0res, MWparam, RFres, RFparam] = findResonantField3(fCavity)
%[B0res, MWdfdB, RFres, RFdfdB] = findResonantField2(fCavity)
%
%This function gives the resonant high field transitions
%
%(INPUT) Magnetic field sweep through SYSPARAM necessary
%Input 1: cavity resonance frequency fcavity (in Hz)
%
%Output 1: ESR magnetic field
%Output 2: ESR df/dB, df/dA, transition probability amplitude
%Output 3: ENDOR frequencies
%Output 4: ENDOR df/dB, df/dA, transition probability amplitude
%

global SYSPARAM 
inTol = 1e-15;
Hdim = SYSPARAM.Hdim;

%% Microwave transitions
%Fast global search of resonance
EigVals = SiDonorEig;
transVals = abs(EigVals(Hdim:-1:Hdim/2+1,:) - EigVals(1:Hdim/2,:));
transVals = abs(transVals - fCavity);

[~,Bidx] = min(transVals,[],2);

B0 = SYSPARAM.B;
B0res = B0(Bidx).';

%Precise local search to get within tolerance
width = 2*(B0(2)-B0(1));
tol = inTol + 1;
while(tol > inTol)
    DB = linspace(-width, width, 1000);
    for ctB = 1:Hdim/2
        B = B0res(ctB) + DB;
        SYSPARAM.set('B',B);
        EigVals = SiDonorEig;
        
        transVals = abs(EigVals(Hdim+1-ctB,:) - EigVals(ctB,:));
        transVals = abs(transVals - fCavity);
        [~, Bidx] = min(transVals);
        
        B0res(ctB) = B(Bidx);
    end
    width = width/100;
    tol = (DB(2)-DB(1))/min(B0res);
end

SYSPARAM.set('B',B0res);

[dfdB,T,S] = SiDonorTrans('B');
dfdB = -dfdB;
dfdA = SiDonorTrans('A');

MWparam{1} = diag(dfdB(diag(S(Hdim:-1:Hdim/2+1,1:Hdim/2)),:));
MWparam{2} = diag(dfdA(diag(S(Hdim:-1:Hdim/2+1,1:Hdim/2)),:));
MWparam{3} = diag(T(diag(S(Hdim:-1:Hdim/2+1,1:Hdim/2)),:));

%% RF transitions
RFres = zeros(Hdim/2,4);
RFparam = cell(3,1);
RFparam{1} = zeros(Hdim/2,4);
RFparam{2} = zeros(Hdim/2,4);
RFparam{3} = zeros(Hdim/2,4);

Evals = SiDonorEig;
for ctB = 1:Hdim/2
    EigVals = Evals(:,ctB);
    
    lvlUp = Hdim+1 - ctB;
    lvlDown = ctB;
    
    if(lvlUp + 1 <= Hdim)
        RFres(ctB,1) = EigVals(lvlUp+1) - EigVals(lvlUp);
        RFparam{1}(ctB,1) = dfdB(S(lvlUp+1,lvlUp),ctB);
        RFparam{2}(ctB,1) = dfdA(S(lvlUp+1,lvlUp),ctB);
        RFparam{3}(ctB,1) = T(S(lvlUp+1,lvlUp),ctB);
    end
    if(lvlUp - 1 >= Hdim/2+1)
        RFres(ctB,2) = EigVals(lvlUp) - EigVals(lvlUp-1);
        RFparam{1}(ctB,2) = dfdB(S(lvlUp,lvlUp-1),ctB);
        RFparam{2}(ctB,2) = dfdA(S(lvlUp,lvlUp-1),ctB);
        RFparam{3}(ctB,2) = T(S(lvlUp,lvlUp-1),ctB);
    end
    if(lvlDown + 1 <= Hdim/2)
        RFres(ctB,3) = EigVals(lvlDown+1) - EigVals(lvlDown);
        RFparam{1}(ctB,3) = dfdB(S(lvlDown+1,lvlDown),ctB);
        RFparam{2}(ctB,3) = dfdA(S(lvlDown+1,lvlDown),ctB);
        RFparam{3}(ctB,3) = T(S(lvlDown+1,lvlDown),ctB);
    end
    if(lvlDown - 1 >= 1)
        RFres(ctB,4) = EigVals(lvlDown) - EigVals(lvlDown-1);
        RFparam{1}(ctB,4) = dfdB(S(lvlDown,lvlDown-1),ctB);
        RFparam{2}(ctB,4) = dfdA(S(lvlDown,lvlDown-1),ctB);
        RFparam{3}(ctB,4) = T(S(lvlDown,lvlDown-1),ctB);
    end
end

%% Reinitialize SYSPARAM
SYSPARAM.set('B',B0);

end


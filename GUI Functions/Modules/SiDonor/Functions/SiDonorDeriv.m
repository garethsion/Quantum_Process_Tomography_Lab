function dEdX = SiDonorDeriv(derivOrder)
%---------------------------------------------------
%------------ Eigenvalue derivative ----------------
%---------------------------------------------------
%
%dfdX = SiDonorDeriv(derivOrder, varargin)
%
%REQUIRES global SYSPARAM as SiDonorClass
%
%Input 1: derivation in order 'BBAEN..'
%
%Output 1: (d^n Eigenvalue)/(dX1*dX2*...) (Hdim, parameter sweep)

global SYSPARAM
if(isempty(SYSPARAM))
    error('A global SYSPARAM as SiDonorClass must be defined');
end

%Input checking
for ct = 1:length(derivOrder)
    if(isempty(strfind('BAEN',derivOrder(ct))))
        error(['Wrong input parameter (not B/A/E/N): ' num2str(derivOrder(ct))]);
    end
end

B = SYSPARAM.B;
A = SYSPARAM.A; %Hz, from CT %OLD = 1.4754e9;
E = SYSPARAM.E;  %Hz/T, from CT + X-band EPR %OLD = -2.8025e10;
N = SYSPARAM.N; %Hz/T
symFlag = SYSPARAM.SymFlag;
Hdim = SYSPARAM.Hdim;
paramDim = SYSPARAM.ParamDim;

%Symbolic n-derivatives
SYSPARAM.set('B','sym', 'A','sym', 'E','sym', 'N','sym');
DiffSym = diff(SiDonorEig, derivOrder(1));
for ct = 2:length(derivOrder)
  DiffSym = diff(DiffSym, derivOrder(ct));
end
DiffSymFun = cell(Hdim,1);
for ct = 1:Hdim
    DiffSymFun{ct} = matlabFunction(DiffSym(ct),'vars',...
    [SYSPARAM.B SYSPARAM.A SYSPARAM.E SYSPARAM.N]);
end
SYSPARAM.set('B',B, 'A',A, 'E',E, 'N',N);

%Evaluate
if(symFlag)
    dEdX = sym('dEdX', [Hdim 1]);
    for ct = 1:Hdim
        dEdX(ct) = DiffSymFun{ct}(B,A,E,N);
    end
else
    dEdX = zeros(Hdim,paramDim);
    for ct = 1:Hdim
        dEdX(ct,:) = DiffSymFun{ct}(B,A,E,N);
    end

    %Sort derivative to respective eigenvalue
    [~, ~, sortIdx] = SiDonorEig();
    dEdX = dEdX(sortIdx,:);
%     for ct = 1:paramDim
%         dfdX(:,ct) = dfdX(sortIdx(:,ct),ct);
%     end
end

end


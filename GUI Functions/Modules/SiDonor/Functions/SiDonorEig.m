function [Evals,Estates,sortIdx,MixRatio] = SiDonorEig()
%--------------------------------------------------------------------------
%--------------------- Analytical diagonalization -------------------------
%----------- Isotropic Hamiltonian for S = 1/2 coupled to any I -----------
%--------------------------------------------------------------------------
%
%[Evals,Estates,sortIdx,MixRatio] = SiDonorEig()
%
%REQUIRES global SYSPARAM as SiDonorClass
%WARNING: FOR SYMBOLIC, NO SORTING -> NEED TO BE RESORTED IF USE 'SUBS'
%WARNING: SORT ENERGIES USING LAST PARAMETER VALUE
%
%Output 1: Eigenvalues, sorted. (Hdim, parameter sweep)
%Output 2: Corresponding eigenstates (Hdim, Hdim, parameter sweep)
%Output 3 (not for 'sym'): sorting index
%Output 4: Mixing angle theta (states = cos(theta)|i> + sin(theta)|j>)

global SYSPARAM
if(isempty(SYSPARAM))
    error('A global SYSPARAM as SiDonorClass must be defined');
end

B = SYSPARAM.B; %T
A = SYSPARAM.A; %Hz, from CT %OLD = 1.4754e9;
E = SYSPARAM.E;  %Hz/T, from CT + X-band EPR %OLD = -2.8025e10;
N = SYSPARAM.N; %Hz/T
I = SYSPARAM.I;
symFlag = SYSPARAM.SymFlag;
Hdim = SYSPARAM.Hdim;
paramDim = SYSPARAM.ParamDim;

if(~symFlag)
    Evals = zeros(Hdim, paramDim);
    Estates = zeros(Hdim, Hdim, paramDim);
    MixRatio = zeros(Hdim, paramDim);
else
    Evals = sym('Evals', [Hdim 1]);
    Estates = sym('Estates', [Hdim Hdim]);
    Estates(:) = 0;
    MixRatio = sym('MixRatio', [Hdim 1]);
end

%REWRITE IN TERM OF MATRIX OR MEX FILE!!!

%% All contributions

Up = @(mI) -B*(E/2 + N*mI) + A/2*mI;
Down = @(mI) -B*(-E/2 + N*(mI+1)) - A/2*(mI+1);
Cross = @(mI) A/2*sqrt(I*(I+1) - mI*(mI+1));

%% Eigenvalues
%Upper/Lower non mixed state
Evals(1,:) = Up(I);
Evals(Hdim,:) = Down(-I-1);

%Mixed states (2-dim subsystems)
for k = 1:Hdim/2-1
    mI = I-k; %mI <-> mI+1
    
    a = Up(mI);
    b = Down(mI);
    
    leftSide = a + b;
    rightSide = sqrt((a-b).^2 + 4*Cross(mI).^2);
    
    Evals(k+1,:) = 1/2*(leftSide + rightSide);  %mS=1/2, mI  
    Evals(Hdim/2+k,:) = 1/2*(leftSide - rightSide); %mS=-1/2, mI+1
end

%% Eigenstates
if(nargout > 1)
    %Upper/Lower non mixed state
    Estates(1,1,:) = 1;
    Estates(Hdim,Hdim,:) = 1;
    MixRatio(1,:) = pi/2;
    MixRatio(Hdim,:) = pi/2;
 
    %Mixed states (2-dim subsystems)
    for k = 1:Hdim/2-1
        mI = I-k; %mI <-> mI+1
        temp = (Evals(k+1,:) - Up(mI))./Cross(mI);
        theta = atan(temp);

        Estates([k+1; Hdim/2+k],k+1,:) = [cos(theta); sin(theta)];
        Estates([k+1; Hdim/2+k],Hdim/2+k,:) = [-sin(theta); cos(theta)];
        MixRatio(k+1,:) = theta;
        MixRatio(Hdim/2+k,:) = theta;
    end
end

%% Sort values
if(~symFlag)
%     %Sort for all field separately
%     [Evals, sortIdx] = sort(Evals,1);
%     if(nargout > 1)
%         for ct = 1:paramDim
%             Estates(:,:,ct) = Estates(:,sortIdx(:,ct),ct);
%         end
%     end

    %Sort using high parameter index (usually high field) ->
    %might not always give sorted energies !!!!!!!WARNING!!!!!
    [~, sortIdx] = sort(Evals(:,end));
    Evals = Evals(sortIdx,:);
    if(nargout > 1)
        Estates = Estates(:,sortIdx,:);
        MixRatio = MixRatio(sortIdx,:);
    end
    
end
   
end


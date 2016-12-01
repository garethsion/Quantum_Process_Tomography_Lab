function [dfdX, Trans, States] = SiDonorTrans(varargin)
%------------------------------------------------------
%----------- Compute transition probabilities -----------
%------------------------------------------------------
%
%[dfdX, Trans, States] = SiDonorTrans(varargin)
%
%REQUIRES global SYSPARAM as SiDonorClass
%
%Input 1 (optional): Nothing for frequency, otherwise 'BAEN' for derivative
%Input 2 (optional): Alternative Hamiltonian for transition probability
%
%Output 1: Transition freq/derivatives (transitions, parameter sweep)
%Output 2: Transition probabilities (transitions, parameter sweep),
%          normalized to 2*gammaE (high field electron = 1)
%Output 3: [state1 state2] -> transition number
%
%WARNING: Freq/derivatives/probabilities are all given in ABSOLUTE.

%Params
global SYSPARAM
if(isempty(SYSPARAM))
    error('A global SYSPARAM as SiDonorClass must be defined');
end

S = SpinClass(1/2);
I = SpinClass(SYSPARAM.I);

Hdim = SYSPARAM.Hdim;
paramDim = SYSPARAM.ParamDim;
symFlag = SYSPARAM.SymFlag;

size = Hdim*(Hdim-1)/2;

%Observable
Hext = SYSPARAM.E*kron(S.X,I.I) + SYSPARAM.N*kron(S.I,I.X);
if(nargin == 2)
    Hext = varargin{2};
end

[dEdX, Estates] = SiDonorEig();
if(~isempty(varargin) && ~strcmp(varargin{1},''))
    dEdX = SiDonorDeriv(varargin{1});
end

if(~symFlag)
    Trans = zeros(size, paramDim);
%     Mixity = zeros(size, paramDim);
    dfdX = zeros(size, paramDim);
else
    Trans = sym('Trans', [size 1]);
    dfdX = sym('dfdX', [size 1]);
end
States = zeros(Hdim);

k = 0;
for ctA = 1:Hdim
    for ctB = 1:Hdim
        k = k + 1;
        
        if(nargout > 1)
            if(~symFlag)
                for ctP = 1:paramDim
                    Trans(k,ctP) = Estates(:,ctB,ctP)'*Hext*Estates(:,ctA,ctP);
%                     Mixity(k,ctP) = (Estates(:,ctB,ctP)'*kron(S.I,I.X)*Estates(:,ctA,ctP))/...
%                                    (Estates(:,ctB,ctP)'*kron(S.X,I.I)*Estates(:,ctA,ctP));
                end
            else
                Trans(k) = Estates(:,ctB)'*Hext*Estates(:,ctA);
            end
        end
        
        dfdX(k,:) = dEdX(ctB,:)-dEdX(ctA,:); 
%         dfdX(k,:) = abs(dEdX(ctB,:)-dEdX(ctA,:))./...
%             sqrt(abs(dEdX(ctB,:).*dEdX(ctA,:)));
        States(ctA,ctB) = k; %States(ctB,ctA) = k;
    end
end

if(nargout > 1)
    %Normalization %CHANGE HERE NOT GOOD if we change Hext 
    if(nargin~=2)
        Trans = abs(2*Trans/SYSPARAM.E); %Gives 1 at high field for electron
    end
%     Mixity = abs(Mixity);
    
    %Value cutoff
    if(~symFlag && nargin~=2)
        cutoff = find(abs(Trans(:)) < 1e-10);
        Trans(cutoff) = 0;
%         dfdX(cutoff) = 0;
    end
end

end
function [M] = CreatePauli(TotalSpin,Direction)
%spin matrices 'pauli' for any total spin

switch Direction,
    case 'I'
        M = eye(2*TotalSpin+1);
    case 'Z';
        M = CreateCartesianZMatrix(TotalSpin);
    case 'X';
        Plus = CreateCartesianPMatrix(TotalSpin); %upper and lower part of matrix
        Minus = CreateCartesianMMatrix(TotalSpin);
        M = (Plus+Minus)/2;
    case 'Y';
        Plus = CreateCartesianPMatrix(TotalSpin);
        Minus = CreateCartesianMMatrix(TotalSpin);
        M = (Plus-Minus)/(2*1i);
    case 'P';
        M = CreateCartesianPMatrix(TotalSpin);
    case 'M';
        M = CreateCartesianMMatrix(TotalSpin);
    otherwise,
        error('Must choose a valid direction (I,X,Y,Z,P,M)!');

end

function M = CreateCartesianZMatrix(TotalSpin)

v = linspace(TotalSpin,-TotalSpin,2*TotalSpin+1); %linspace = a:b, dim=c, a,b,c arguments
M = diag(v); %vector on diagonal

function M = CreateCartesianPMatrix(TotalSpin)

v = linspace(TotalSpin,-TotalSpin,2*TotalSpin+1);
M = zeros(TotalSpin*2 + 1);
I = TotalSpin;
for k=length(v):-1:1
    if k+1 <= 2*I+1
        M(k,k+1) = sqrt( I*(I+1) - v(k)*v(k+1));
    end
end
        

function M = CreateCartesianMMatrix(TotalSpin)

v = linspace(TotalSpin,-TotalSpin,2*TotalSpin+1);
M = zeros(TotalSpin*2 + 1);
I = TotalSpin;
for k=1:length(v)
    if k-1 > 0
        M(k,k-1) = sqrt( I*(I+1) - v(k)*v(k-1));
    end
end
function myChi = Chi (rho_zero, rho_one, rho_plus, rho_minus)
    % Chi calculates the process matrix given four density
    % matrices taken as arguments.

    I = eye(2,2);
    Pauli_X = [0, 1; 1, 0];
    
    p1 = rho_zero;
    p4 = rho_one;
    p3 = rho_plus - 1i*rho_minus - (1-1i)*(p1+p4)/2;
    p2 = rho_plus + 1i*rho_minus - (1+1i)*(p1+p4)/2;
    
    Lambda = 1/2 * [I, Pauli_X; Pauli_X, -1*I];
    myChi = Lambda * [p1, p2; p3, p4] * Lambda;
end 
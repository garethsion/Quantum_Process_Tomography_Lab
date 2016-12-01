function Density = Density(Xpure, Ypure, Zpure, Xproc, Yproc, Zproc)
    % Density takes pure and process x, y, and z rotation data and 
    % produces a corresponding density matrix 
    
    % Pauli Basis
    Pauli_X = [0, 1; 1, 0];
    Pauli_Y = [0, -1i; 1i, 0];
    Pauli_Z = [1, 0; 0, -1];
    I = eye(2,2);
    
    % Fit the pure states
    rx_pure = Gauss_Fitter((1:length(Xpure(:,1)))', Xpure(:,1));
    ry_pure = Gauss_Fitter((1:length(Ypure(:,1)))', Ypure(:,1));
    rz_pure = Gauss_Fitter((1:length(Zpure(:,1)))', Zpure(:,1));
    
    % Fit the process states
    rx_process = Gauss_Fitter((1:length(Xproc(:,1)))', Xproc(:,1));
    ry_process = Gauss_Fitter((1:length(Yproc(:,1)))', Yproc(:,1));
    rz_process = Gauss_Fitter((1:length(Zproc(:,1)))', Zproc(:,1));
    rpure = [rx_pure, ry_pure, rz_pure];
    
    % Normalisation
    rx = rx_process/abs(norm(rpure));
    ry = ry_process/abs(norm(rpure));
    rz = rz_process/abs(norm(rpure));

    rx_sigma = rx*Pauli_X;
    ry_sigma = ry*Pauli_Y;
    rz_sigma = rz*Pauli_Z;
    
    % Calculate Density matrix
    rho = 0.5 * (I + (rx_sigma) + (ry_sigma) + (rz_sigma));
    
    Density = rho;
    %trace(rho);
end
function Fidelity = Fidelity(chi0, chi1)
    % Fidelity calculates the fidelity of a given process%
    Fidelity = trace(sqrt(chi1)*chi0*sqrt(chi1));
end

classdef Constants
    %Constants
    %h in eV.s, Planck constant
    %kb in eV/K, Boltzmann constant
    %c in m/s, light speed
    %mu0 in H/m, vacuum permeability 
    %gamma0 in Hz/T, electron gyromagnetic ratio
    %g0 , electron g factor
    %e in C, electric charge
    %eps0 in F/m, vacuum permittivity
    %me in eV/c^2, electron mass
    
    properties (SetAccess = private)
        h = 4.135667516e-15;%eV.s, Planck constant
        kb = 8.6173324e-5; %eV/K, Boltzmann constant
        c = 299792458; %m/s, light speed
        mu0 = 4*pi*1e-7; %H/m, vacuum permeability 
        gamma0 = 2.802495266e10; %Hz/T, electron gyromagnetic ratio
        g0 = 2.0023193043617; %electron g factor
        e = -1.602176565e-19; %C, electric charge
        eps0 = 1/(4*pi*1e-7*299792458^2); %F/m, vacuum permittivity
        me = 0.510998910e6; %eV/c^2, electron mass
    end
    
    methods
        function obj = Constants()
        end
    end
end

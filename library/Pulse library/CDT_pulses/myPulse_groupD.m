function y = myPulse_groupD( t, theta, phi, freq )
% Customisation variables
gap = 0.5; % Of a pi_pulse
% Get Phi variables
[phi1,phi2] = phis(theta, phi);
% Period of oscillation in ns. 1/MHz = ms
period = (1000)/(freq);
% Time for Pi pulse in ns
pi_pulse = period/2;
% Step size of t
step_size=(max(t)-min(t))/(length(t)-1);
%`Custom pulse
my_pulse = (period*theta)/(2*pi);

% Pi pulse vector 1
pi_vec1 = [ ones(round(pi_pulse/step_size),1)   * cos(phi1), ...
            ones(round(pi_pulse/step_size),1)   * sin(phi1) ];
% 2Pi pulse vector
pi2_vec = [ ones(round(2*pi_pulse/step_size),1) * cos(phi2), ...
            ones(round(2*pi_pulse/step_size),1) * sin(phi2) ];
% Pi pulse vector 2  
pi_vec2 = [ ones(round(pi_pulse/step_size),1)   * cos(phi1), ...
            ones(round(pi_pulse/step_size),1)   * sin(phi1) ];
% Pi pulse vector 2  
my_vec = [  ones(round(my_pulse/step_size),1)   * cos(phi), ...
            ones(round(my_pulse/step_size),1)   * sin(phi) ];
        
% gap 
gap_pulse = zeros(round(gap*pi_pulse/step_size),2);

% Add pi 2pi pi pulses
y = [ pi_vec1; gap_pulse; pi2_vec; gap_pulse; pi_vec2; gap_pulse; my_vec ];
% Fill with zeros to the end
y = [ y; zeros( max(0, length(t)-length(y)), 2 ) ];
% Crop t
y = y(1:length(t),:);
end

% Given theta and phi, generates the phi1 and phi2
function [phi1,phi2] = phis(theta, phi)
% From equations
phi1 = acos(-theta/(4*pi));
phi2 = 3*phi1;
% Make phi1 and phi2 relavtive to phi
phi1 = phi1+phi;
phi2 = phi2+phi;
end

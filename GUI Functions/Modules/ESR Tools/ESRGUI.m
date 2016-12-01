%Pulse Creator GUI module
function ESRGUI(ESR)
%% Module definition (template)

%% CONNECTION
ESR.UI_add_connect();

%% MAIN PARAMETERS
ESR.UI_add_subpanel('Main tools',0.70,0.21);
    
%FIELD: MEASUREMENT TYPES
ESR.UI_add_setting('checkbox','meas_q_rough',2,1);

end
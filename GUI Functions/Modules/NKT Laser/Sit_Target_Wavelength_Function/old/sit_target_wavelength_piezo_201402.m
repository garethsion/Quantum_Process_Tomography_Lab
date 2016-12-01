kwavelength=keithley2400(26); 
kwavelength.source('voltage',100); 
kwavelength.measure('current',0.1e-3,0.15e-3);
kwavelength.output('on');  
kwavelength.set_voltage(0);
max_voltage_ramp = 0.1; % maximum voltage ramp
cycle_pause = 0.1;

% target=1078.24793; % P-b
% target=1078.27000; % P-d
% target=1078.29750; % P-f
% target=1078.28167; % P-e
% target=1078.10000; % off res

%target=1078.94793; % As-b-A

% target=1078.94790; % As-b-A
% target=1078.94620; % As-b-D

% February 14, 2014
% target=1078.23143; % P-a
% target=1078.24850; % P-b
% target=1078.26060; % P-c
% target=1078.26940; % P-d
% target=1078.28145; % P-e
%target=1078.2984; % P-f

% Match 7, 2014
% target=1078.23285; % P-a
% target=1078.24778; % P-b
% target=1078.26060; % P-c
% target=1078.27330; % P-d
% target=1078.28145; % P-e
% target=1078.2970; % P-f
% target=1078.2706; % off res

target = 1078.150;
% target = 1078.270;

current=getWavelength();

target=target*1000; % [pm]
current=current*1000; % [pm]
if (target-current)>12
    error('Current wavelength too far away!');
elseif target<current
    error('Current wavelength > target!');
end

step_slope=200/20; % [V/pm]

voltage_toSet=0;
kwavelength.set_voltage(voltage_toSet);

i=1;
while i~=0
    current=getWavelength()*1000;
    difference=target-current; % [pm]
    
    %constrain the per step voltage ramp to max_voltage_ramp
    if abs(difference*step_slope)<abs(max_voltage_ramp)
        voltage = difference*step_slope;
    else
        if difference*step_slope < 0
            voltage = - abs(max_voltage_ramp);
        elseif difference*step_slope > 0
            voltage = abs(max_voltage_ramp);
        end
    end
            
    voltage_toSet=voltage_toSet+voltage;
    if abs(voltage)>120
        error('Voltage too large!');
    %elseif abs(voltage)
    else
        kwavelength.set_voltage(voltage_toSet);
    end
        pause(cycle_pause);
end
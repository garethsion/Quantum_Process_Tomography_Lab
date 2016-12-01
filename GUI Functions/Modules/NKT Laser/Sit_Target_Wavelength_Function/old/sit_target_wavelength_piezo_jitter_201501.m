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

% target = 1078.270;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN-TIME SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
target_wavelength = 1078.276; %nm
%target_wavelength = 1078.2750; %nm
jitter_wavelength_pp = 1.5; %pm!!
ramp_frequency = 1e3;
cycle_pause = 0.1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ch = 1;
amplification = 80; % PA78 voltage amplifier
amplification_offset = -0.005; %V Set the 0 point when using voltage amplifier PA78

max_voltage_total = 60/amplification;
max_voltage_ramp = 0.1/amplification; % maximum voltage ramp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD SETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initilize
awavelength=awg33(10);
awavelength.set_output_load(ch,'high')
awavelength.set_to_ramp(ch)
awavelength.set_ramp_symmetry(ch,50) % Set triangular ramp
voltage_wave_toSet = 0.002;
awavelength.set_voltage_wave(ch,voltage_wave_toSet)% Set ramp amplitude to minimum value
% Set offset to amplification_offset to get output of 0V
awavelength.set_voltage(ch,amplification_offset)
awavelength.set_frequency(ch,ramp_frequency)
awavelength.output(ch,'on');


%%
pause(1) % Required when rerunning the script
current=getWavelength();

target_wavelength=target_wavelength*1000; % [pm]
current=current*1000; % [pm]
if (target_wavelength-current)>12
    error('Current wavelength too far away!');
elseif target_wavelength<current
    error('Current wavelength > target!');
end

% step_slope=200/20; % [V/pm] without amplifier
step_slope= - 0.1/0.47; % [V/pm] With PA78 voltage amplifier, tested! Minus sign correct!

voltage_wave_target = abs(jitter_wavelength_pp * step_slope);
voltage_toSet=amplification_offset;
awavelength.set_voltage(ch,voltage_toSet);

target_reached = 0;
voltage_wave_is_set=0;
i=1;
while i~=0
    current=getWavelength()*1000;
    difference=target_wavelength-current; % [pm]
    
    %constrain the per step voltage ramp to max_voltage_ramp
    if abs(difference*step_slope)<abs(max_voltage_ramp)
        voltage = difference*step_slope;
        target_reached=1;
    else
        if difference*step_slope < 0
            voltage = - abs(max_voltage_ramp);
        elseif difference*step_slope > 0
            voltage = abs(max_voltage_ramp);
        end
    end
    
    voltage_toSet=voltage_toSet+voltage;
    
    % Check that waveform offset + wave amplitude is within the maximum
    % voltage range
    if abs(voltage_toSet)+1/2*abs(voltage_wave_target)>max_voltage_total
        error('Voltage too large!');
    % Check that when the wave amplitude is set, the voltage ramp isn't
    % below the amplification offset, i.e. the output voltage doesn't go into
    % negative values
    % voltage_toSet and amplification_offset are negative, since the
    % voltage amplifier inverts the signal.
    elseif voltage_wave_is_set && voltage_toSet+voltage_wave_target/2 > amplification_offset 
        error('Voltage too small')
    else
        awavelength.set_voltage(ch,voltage_toSet);
    end
    
    
    % If target is reached, increase ramp voltage stepwise
    if target_reached==1 && voltage_wave_is_set~=1
        %TODO
        
        while voltage_wave_toSet ~= voltage_wave_target
        %constrain the per step voltage ramp to max_voltage_ramp
            if voltage_wave_target-voltage_wave_toSet>abs(max_voltage_ramp)
                voltage_wave_toSet = voltage_wave_toSet + max_voltage_ramp;
            else
                voltage_wave_toSet = voltage_wave_target;
            end
            awavelength.set_voltage_wave(ch,voltage_wave_toSet)
            pause(cycle_pause)
        end
        voltage_wave_is_set = 1;
    end
    pause(cycle_pause);
end
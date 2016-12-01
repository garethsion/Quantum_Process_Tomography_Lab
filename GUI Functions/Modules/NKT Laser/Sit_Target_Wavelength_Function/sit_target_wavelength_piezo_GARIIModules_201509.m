%% Parameters
target = 1078.27385;

%% Setup parameters
max_voltage_ramp = 0.1; % maximum voltage ramp
cycle_pause = 0.1;

%% SETUP
K = KEI2400Class(); 
K.ID='1';
K.connect();
K.set_source_type('voltage')
K.set_source_voltage_range(100)
K.set_measure_voltage(0)
K.set_measure_current(1)
K.set_measure_current_range(0.1e-3)
K.set_compliance_current(0.15e-3)
K.set_output_status(1)
WS7 = WS7Class();
WS7.connect


%% RUN
current = WS7.get_wavelength();

target=target*1000; % [pm]
current=current*1000; % [pm]
if (target-current)>12
    error('Current wavelength too far away!');
elseif target<current
    error('Current wavelength > target!');
end

step_slope=200/20; % [V/pm]

voltage_toSet=0;
K.set_source_voltage(voltage_toSet);

i=1;
while i~=0
    current=WS7.get_wavelength()*1000;
    if current <= 0
        % An error has happened, likely underexposed (err_value = -3)
        % Wait until exposure is ok again to avoid exposing piezo to high
        % voltages
        while current <= 0
            sprintf('Laser shut off, I am waiting.')
            pause(2)
            current=WS7.get_wavelength();
        end
    end
    
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
    if abs(voltage_toSet)>80
        error('Voltage too large!');
    %elseif abs(voltage)
    else
        K.set_source_voltage(voltage_toSet);
    end
        pause(cycle_pause);
end


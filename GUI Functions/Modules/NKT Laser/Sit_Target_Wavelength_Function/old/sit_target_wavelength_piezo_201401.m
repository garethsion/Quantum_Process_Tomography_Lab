kwavelength=keithley2400(25); 
kwavelength.source('voltage',100); 
kwavelength.measure('current',0.1e-3,0.15e-3);
kwavelength.output('on');  
kwavelength.set_voltage(0);

% target=1078.24793; % P-b
% target=1078.27000; % P-d
% target=1078.29750; % P-f
% target=1078.28167; % P-e
% target=1078.10000; % off res

%target=1078.94793; % As-b-A

% target=1078.94790; % As-b-A
target=1078.94620; % As-b-D


current=getWavelength();

target=target*1000; % [pm]
current=current*1000; % [pm]
if (target-current)>10
    error('Current wavelength too far away!');
elseif target<current
    error('Current wavelength > target!');
end

step_slope=200/20; % [V/pm]

current_voltage=0;

i=1;
while i~=0
    current=getWavelength()*1000;
    difference=target-current; % [pm]
    voltage=difference*step_slope;
    if abs(voltage)>100
        error('Voltage too large!');
    end
    current_voltage=current_voltage+voltage;
    kwavelength.set_voltage(current_voltage);
    pause(2);
end
YokoWavelength=yoko200(1); 
Vrange = 32; %V max range
YokoWavelength.source('voltage',Vrange);  
YokoWavelength.set_voltage(0);
YokoWavelength.output('on');

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

target = 1078.27425;
% target = 1078.26902

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
    if abs(voltage)>Vrange
        error('Voltage too large!');
    %elseif abs(voltage)
    else
        current_voltage=current_voltage+voltage;
        YokoWavelength.set_voltage(current_voltage);
    end
        pause(1);
end
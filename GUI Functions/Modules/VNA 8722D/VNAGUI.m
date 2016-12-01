%Pulse Creator GUI module
function VNAGUI(VNA)
%% Module definition (template)

%NOT GOOOD!!!!!
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
VNA.MAIN.set_transient_mode(1);
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

%% CONNECTION
VNA.UI_add_connect();

%% MAIN PARAMETERS
VNA.UI_add_subpanel('Main parameters',0.70,0.21);
    
%FIELD: CHANNEL
chans = VNA.UI_add_setting('popupmenu','channel',2,1);
chans.add_event_fun(@VNA.select_channel);

%FIELD: MEASUREMENT TYPES
VNA.UI_add_setting('popupmenu','measure_mode1',2,2);
VNA.get_setting('measure_mode1').UI_add_update();
VNA.UI_add_setting('popupmenu','display_mode1',2,3);
VNA.get_setting('display_mode1').UI_add_update();
VNA.UI_add_setting('popupmenu','domain_mode1',2,4);
VNA.get_setting('domain_mode1').UI_add_update();

VNA.UI_add_setting('popupmenu','measure_mode2',2,2);
VNA.get_setting('measure_mode1').UI_add_update();
VNA.get_setting('measure_mode2').set_state_and_UIvisibility(0);
VNA.UI_add_setting('popupmenu','display_mode2',2,3);
VNA.get_setting('display_mode2').UI_add_update();
VNA.get_setting('display_mode2').set_state_and_UIvisibility(0);
VNA.UI_add_setting('popupmenu','domain_mode2',2,4);
VNA.get_setting('domain_mode2').UI_add_update();
VNA.get_setting('domain_mode2').set_state_and_UIvisibility(0);

%FIELD: FREQUENCY is swept in a ``transient" way in VNA
%It must be therefore set as a SettingClass and not a ParameterClass
VNA.UI_add_param('freq_center1',3,2);
VNA.get_param('freq_center1').UI_add_update();
VNA.UI_add_setting('edit','freq_span1',3,3);
VNA.get_setting('freq_span1').UI_add_update();
VNA.UI_add_setting('popupmenu','freq_pts1',3,4);
VNA.get_setting('freq_pts1').UI_add_update();

VNA.UI_add_param('freq_center2',3,2);
VNA.get_param('freq_center2').UI_add_update();
VNA.get_param('freq_center2').set_state_and_UIvisibility(0);
VNA.UI_add_setting('edit','freq_span2',3,3);
VNA.get_setting('freq_span2').UI_add_update();
VNA.get_setting('freq_span2').set_state_and_UIvisibility(0);
VNA.UI_add_setting('popupmenu','freq_pts2',3,4);
VNA.get_setting('freq_pts2').UI_add_update();
VNA.get_setting('freq_pts2').set_state_and_UIvisibility(0);



%FIELD: POWER
VNA.UI_add_param('power1',4,2);
VNA.get_param('power1').UI_add_update();
VNA.UI_add_param('power2',4,2);
VNA.get_param('power2').UI_add_update();
VNA.get_param('power2').set_state_and_UIvisibility(0);

% IF bandwidth and average
VNA.UI_add_setting('popupmenu','IF_bandwidth',4,3);
VNA.get_setting('IF_bandwidth').UI_add_update();
VNA.UI_add_setting('edit','averages_num',4,4);
VNA.get_setting('averages_num').UI_add_update();

%% MAIN PARAMETERS
VNA.UI_add_subpanel('Calibration',0.58,0.12);

VNA.UI_add_setting('popupmenu','calibrate_mode',6,1); 
buttonPos = ModuleUICPos(6,2);
VNA.ModuleUIC('push','Calibrate',buttonPos,'Callback',@VNA.calibrate);
    
%% Trigger
VNA.UI_add_subpanel('Trigger parameters',0.46,0.12);

%FIELD: TRIGGER MODE
VNA.UI_add_setting('popupmenu','trigger_mode',8.2,1);

end
%MSO GUI module
function MSOGUI(MSO)
%% Module definition
help_text = {['\bfAcq. channels:\rm sets which channel(s) will be measured. More than one ' ... 
              'channel can be selected using shift or ctrl.'] ...
              ' ' ...
             ['\bfIntegrate?:\rm when unchecked, the oscilloscope trace fills the X (time) sweep axis ' ...
              '(which is therefore blocked, X axis points is defined by the oscilloscope. ' ...
              'WARNING: this can cause conflict with other instruments.). When unchecked, the trace is averaged.'] ...
              ' ' ...
              '\bfInternal averaging?:\rm the oscilloscope average the data during Shots/Point instead of the computer.' ...
              ' ' ...
              ['\bfDynamic voltage scaling:\rm automatic feedback  computer<-->oscilloscope to modify the ' ... 
              'voltage scaling for an optimized fit to the signal.'] ...
              ' ' ...
              ['\bfNumber of points:\rm sets the number of point in the time axis. WARNING: the actual number ' ...
              'of points might be set differently by the oscilloscope, with a lower limit around 1ns between points.']};
MSO.UI_add_help(help_text);

%% CONNECTION
MSO.UI_add_connect();     

%% ACQUISITION PARAMETERS
MSO.UI_add_subpanel('Acquisition parameters',0.75,0.17);
Ypos = 2;

%FIELD: Measurement channels
chans = MSO.UI_add_setting('listbox','channels',Ypos,1);
set(chans.hText,'Min',1,'Max',3,'Value',[]);
chans.add_event_fun(@MSO.select_acq_channel);
boxsize = get(chans.hText,'Position'); boxsize([2 4]) = [boxsize(2)-0.06 0.1];
set(chans.hText,'Position',boxsize,'FontSize',0.2);

%FIELD: Integration
integ = MSO.UI_add_setting('checkbox','integ',Ypos,2);
integ.add_event_fun(@MSO.select_integrate);

%FIELD: Averaging
avg = MSO.UI_add_setting('checkbox','osc_avg',Ypos,3);
avg.add_event_fun(@MSO.toggle_intAvg_UI)

%FIELD: Dynamical voltage scaling
MSO.UI_add_setting('edit','osc_avg_number',Ypos,4);
MSO.get_setting('osc_avg_number').set_state_and_UIvisibility(0) 

%FIELD: Number of point
MSO.UI_add_setting('popupmenu','AcqPts',Ypos+1,2);

%FIELD: Time range
MSO.UI_add_setting('edit','timeRange',Ypos+1,3);

%FIELD: Trigger time offset
MSO.UI_add_setting('edit','timeOffset',Ypos+1,4);
MSO.get_setting('timeOffset').UI_add_update();


%% CHANNEL SETTINGS
MSO.UI_add_subpanel('Channel settings',0.57,0.18);
Ypos = 5.2;

%FIELD: Channel select
MSO.UI_add_setting('popupmenu','chan_sel',Ypos,1);
MSO.get_setting('chan_sel').add_event_fun(@MSO.channel_select_settings);

%FIELD: Dynamical voltage scaling
MSO.UI_add_setting('checkbox','dynVoltScale',Ypos+1,1);

%FIELD: Impedance
MSO.UI_add_setting('popupmenu','impedance1',Ypos,2);
MSO.get_setting('impedance1').UI_add_update();
MSO.UI_add_setting('popupmenu','impedance2',Ypos,2);
MSO.get_setting('impedance2').UI_add_update();
MSO.get_setting('impedance2').set_UIvisibility(0);
MSO.UI_add_setting('popupmenu','impedance3',Ypos,2);
MSO.get_setting('impedance3').UI_add_update();
MSO.get_setting('impedance3').set_UIvisibility(0);
MSO.UI_add_setting('popupmenu','impedance4',Ypos,2);
MSO.get_setting('impedance4').UI_add_update();
MSO.get_setting('impedance4').set_UIvisibility(0);

%FIELD: Voltage range
MSO.UI_add_setting('edit','voltRange1',Ypos,3);
MSO.get_setting('voltRange1').UI_add_update();
MSO.UI_add_setting('edit','voltRange2',Ypos,3);
MSO.get_setting('voltRange2').UI_add_update();
MSO.get_setting('voltRange2').set_UIvisibility(0);
MSO.UI_add_setting('edit','voltRange3',Ypos,3);
MSO.get_setting('voltRange3').UI_add_update();
MSO.get_setting('voltRange3').set_UIvisibility(0);
MSO.UI_add_setting('edit','voltRange4',Ypos,3);
MSO.get_setting('voltRange4').UI_add_update();
MSO.get_setting('voltRange4').set_UIvisibility(0);

%FIELD: Voltage offset
MSO.UI_add_setting('edit','voltOffset1',Ypos,4);
MSO.get_setting('voltOffset1').UI_add_update();
MSO.UI_add_setting('edit','voltOffset2',Ypos,4);
MSO.get_setting('voltOffset2').UI_add_update();
MSO.get_setting('voltOffset2').set_UIvisibility(0);
MSO.UI_add_setting('edit','voltOffset3',Ypos,4);
MSO.get_setting('voltOffset3').UI_add_update();
MSO.get_setting('voltOffset3').set_UIvisibility(0);
MSO.UI_add_setting('edit','voltOffset4',Ypos,4);
MSO.get_setting('voltOffset4').UI_add_update();
MSO.get_setting('voltOffset4').set_UIvisibility(0);

%FIELD: Voltage calibration offset
MSO.UI_add_setting('edit','voltCalib1',Ypos+1,4);
MSO.UI_add_setting('edit','voltCalib2',Ypos+1,4);
MSO.get_setting('voltCalib2').set_UIvisibility(0);
MSO.UI_add_setting('edit','voltCalib3',Ypos+1,4);
MSO.get_setting('voltCalib3').set_UIvisibility(0);
MSO.UI_add_setting('edit','voltCalib4',Ypos+1,4);
MSO.get_setting('voltCalib4').set_UIvisibility(0);

%% Other instrument options
MSO.UI_add_subpanel('Other instrument options',0.44,0.13);
Ypos = 8.5;

MSO.UI_add_setting('popupmenu','trig_opts',Ypos,1);

MSO.UI_add_setting('popupmenu','acquire_res',Ypos,2);
%MSO.get_setting('acquire_res').set_state_and_UIvisibility(0);

%% Post-processing
MSO.UI_add_subpanel('Post-processing',0.31,0.13);
Ypos = 11;

%Transient filter: flag
MSO.UI_add_setting('checkbox','trans_filter_flag',Ypos,1);

%Transient filter: load function
%MAKE A SETTING FOR THIS
[textPos,~] = ModuleUICPos(Ypos,2);
[~, inputPos] = ModuleUICPos(Ypos,1.1);
MSO.hTransFiltText = MSO.ModuleUIC('text','',textPos);
MSO.ModuleUIC('push','Load',inputPos,'CallBack',@MSO.transfilt_load,'FontSize',0.7);

% Baseline correction   
 
end
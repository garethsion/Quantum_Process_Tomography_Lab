%VSG GUI module
function VSGGUI(VSG)
%% Module definition
help_text = {'\bfFrequency (GHz):\rm Source frequency.' ...
             '\bfPower (dBm):\rm Source power. Maximum is 25 dBm (real 23 dBm with IQ mixing).' ...
             '' ...
             '\bfIQ mixing?:\rm Turns on/off IQ mixing from front panel I/Q inputs.' ...
             '' ...
            ['\bfTransient sweep (Ext Trig)?:\rm Turns on/off transient sweep, i.e. an external trigger starts ' ...
             'a full sweep in a single shot (takes about 1 s, depends on sweep width). Sweep parameters are ' ...
             'defined using "Center frequency" and "Sweep width". This disables the "Frequency" main parameter. ' ...
             'The Update button immediately send new sweep parameters to VSG, even when running.']};
VSG.UI_add_help(help_text);  

%% CONNECTION
VSG.UI_add_connect();

%% MAIN PARAMETERS
VSG.UI_add_subpanel('Main parameters',0.79,0.13);

%FIELD: CARRIER FREQUENCY
VSG.UI_add_param('freq',2,1);
VSG.get_param('freq').UI_add_update();
                 
%FIELD: POWER
VSG.UI_add_param('power',2,2);

%% Trigger
VSG.UI_add_subpanel('Trigger parameters',0.66,0.13);
    
%% IQ mixing
VSG.UI_add_subpanel('IQ mixing',0.53,0.13);
    
VSG.UI_add_setting('checkbox','iqmixing',6.9,1);

%% Fast (transient) sweep
VSG.UI_add_subpanel('Sweep options',0.40,0.13);

VSG.UI_add_setting('checkbox','fastsweep',9.2,1);
VSG.get_setting('fastsweep').add_event_fun(@VSG.fastsweep_select);

VSG.UI_add_setting('edit','fastsweep_center',9.2,2);
VSG.get_setting('fastsweep_center').set_state_and_UIvisibility(0);

VSG.UI_add_setting('edit','fastsweep_width',9.2,3);
VSG.get_setting('fastsweep_width').set_state_and_UIvisibility(0);

VSG.UI_add_setting('push','fastsweep_update',9.2,4);
VSG.get_setting('fastsweep_update').set_state_and_UIvisibility(0);
VSG.get_setting('fastsweep_update').add_event_fun(@VSG.fastsweep_update);
    
end
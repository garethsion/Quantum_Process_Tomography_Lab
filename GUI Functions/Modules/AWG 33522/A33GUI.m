%AWG 33522 GUI module
function A33GUI(A33)
%% Module definition
%Optional function handles
% VSG.window_resize = @window_resize;
% VSG.metadataEdit = @metadataEdit;
% VSG.sweepControlsEdit = @sweepControlsEdit;

%% CONNECTION
A33.UI_add_connect();

%% MAIN PARAMETERS
A33.UI_add_subpanel('Main parameters',0.68,0.24);

%Channel
A33.UI_add_setting('popupmenu','channel',2,1);
A33.get_setting('channel').add_event_fun(@A33.channel_select)

%Status (on/off)
A33.UI_add_setting('popupmenu','status1',2,2); 
A33.UI_add_setting('popupmenu','status2',2,2);
A33.get_setting('status2').set_UIvisibility(0);
    
%Waveform type
A33.UI_add_setting('popupmenu','wavetype1',2,3); 
A33.UI_add_setting('popupmenu','wavetype2',2,3);
A33.get_setting('wavetype2').set_UIvisibility(0);

%Output load
A33.UI_add_setting('popupmenu','load1',3,1); 
A33.UI_add_setting('popupmenu','load2',3,1);
A33.get_setting('load2').set_UIvisibility(0);

%Amplitude
A33.UI_add_param('ampl1',3,2);
A33.UI_add_param('ampl2',3,2);
A33.get_param('ampl2').set_UIvisibility(0);

%Frequency
A33.UI_add_param('freq1',3,3);
A33.UI_add_param('freq2',3,3);
A33.get_param('freq2').set_UIvisibility(0);

%Amplitude offset
A33.UI_add_param('amploff1',4,2);
A33.UI_add_param('amploff2',4,2);
A33.get_param('amploff2').set_UIvisibility(0);

%Phase
A33.UI_add_param('phas1',4,3);
A33.UI_add_param('phas2',4,3);
A33.get_param('phas2').set_UIvisibility(0);
end
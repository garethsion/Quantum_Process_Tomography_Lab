%AWG 33522 GUI module
function SR830GUI(SR830)
%% Module definition
%Optional function handles
% VSG.window_resize = @window_resize;
% VSG.metadataEdit = @metadataEdit;
% VSG.sweepControlsEdit = @sweepControlsEdit;

%% CONNECTION
SR830.UI_add_connect();
SR830.UI_add_updateall();

%% MAIN PARAMETERS
SR830.UI_add_subpanel('Modulation',0.68,0.24);
SR830.UI_add_param('PHAS',2,1);
SR830.UI_add_param('FMOD',2,2);
SR830.UI_add_param('FREQ',2,3);
SR830.UI_add_param('RSLP',3,1);
SR830.UI_add_param('HARM',3,2);
SR830.UI_add_param('SLVL',3,3);

%% AUXILIARY OUTPUTS
SR830.UI_add_subpanel('Auxiliary Outputs',0.5,0.10);
SR830.UI_add_param('AUXV1',5,1);
%% MEASUREMENT PANEL
SR830.UI_add_subpanel('Measurements (Parameters will not be sent to lock-in in "Read-only" mode)',0.5,0.13);
chans = SR830.UI_add_setting('listbox','channels',6.9,1);
set(chans.hText,'Min',1,'Max',3,'Value',[]); chans.add_event_fun(@SR830.select_meas_channel);
boxsize = get(chans.hText,'Position'); boxsize([2 4]) = [boxsize(2)-0.03 0.06];
set(chans.hText,'Position',boxsize,'FontSize',0.35);

readonly = SR830.UI_add_setting('checkbox','manual_mode',6.9,2);
readonly.add_event_fun(@SR830.set_manual_mode);

%{
%FIELD: Integration
integ = MSO.UI_add_setting('checkbox','integ',2,2);
integ.add_event_fun(@MSO.select_integrate);
%}

%{ 
%Channel
SR830.UI_add_setting('popupmenu','channel',2,1);
SR830.get_setting('channel').add_event_fun(@SR830.channel_select)
%}

%% SUB-PANEL 
% VNA.UI_add_subpanel('Modulation',0.58,0.12);

%}

% SR830.UI_add_setting('popupmenu','measure_mode1',2,2);

end
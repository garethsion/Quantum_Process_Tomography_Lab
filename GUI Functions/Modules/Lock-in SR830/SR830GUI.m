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

SR830.UI_add_subpanel('Configuration: Read-only mode: Parameters will not be sent, but will be read/updated from SR830)'...
    ,0.81,0.1);
readonly = SR830.UI_add_setting('checkbox','manual_mode',2,1);
readonly.add_event_fun(@SR830.set_manual_mode);

[~, inputPos] = ModuleUICPos(2,2); inputPos(3) = inputPos(3)+0.08;
SR830.ModuleUIC('push','Load settings from SR830', inputPos,'CallBack',@SR830.load_sr830_manual_settings_ui,'FontSize',0.4);



SR830.UI_add_subpanel('Detection',0.70,0.10);
SR830.UI_add_setting('popupmenu','ISRC',4,1);
SR830.get_setting('ISRC').UI_add_update();
SR830.UI_add_setting('popupmenu','SENS',4,2);
SR830.get_setting('SENS').UI_add_update();
SR830.UI_add_setting('popupmenu','OFLT',4,3);
SR830.get_setting('OFLT').UI_add_update();


SR830.UI_add_subpanel('Modulation',0.54,0.15);
SR830.UI_add_setting('popupmenu','FMOD',6,1);
SR830.get_setting('FMOD').UI_add_update();
SR830.UI_add_param('FREQ',6,2);
SR830.get_param('FREQ').UI_add_update();
SR830.UI_add_param('PHAS',6,4);
SR830.get_param('PHAS').UI_add_update();
SR830.UI_add_param('SLVL',6,3);
SR830.get_param('SLVL').UI_add_update();
SR830.UI_add_setting('popupmenu','RSLP',7,1);
SR830.get_setting('RSLP').UI_add_update();
SR830.UI_add_setting('edit','HARM',7,2);
SR830.get_setting('HARM').UI_add_update();


%% AUXILIARY OUTPUTS
SR830.UI_add_subpanel('Auxiliary Outputs',0.43,0.10);
SR830.UI_add_param('AUXV 1',9,1);
SR830.get_param('AUXV 1').UI_add_update();
SR830.UI_add_param('AUXV 2',9,2);
SR830.get_param('AUXV 2').UI_add_update();
SR830.UI_add_param('AUXV 3',9,3);
SR830.get_param('AUXV 3').UI_add_update();
SR830.UI_add_param('AUXV 4',9,4);
SR830.get_param('AUXV 4').UI_add_update();
%% MEASUREMENT PANEL
SR830.UI_add_subpanel('Measurement'...
    ,0.15,0.27);

chans = SR830.UI_add_setting('listbox','channels',11,1);
set(chans.hText,'Min',1,'Max',5,'Value',[]); chans.add_event_fun(@SR830.select_meas_channel);
boxsize = get(chans.hText,'Position'); boxsize([2 4]) = [boxsize(2)-0.03 0.06];
set(chans.hText,'Position',boxsize,'FontSize',0.35);

SR830.UI_add_setting('edit','OEXP 1',11,2);
SR830.get_setting('OEXP 1').UI_add_update();
SR830.UI_add_setting('edit','OEXP 2',12,2);
SR830.get_setting('OEXP 2').UI_add_update();
SR830.UI_add_setting('edit','OEXP 3',13,2);
SR830.get_setting('OEXP 3').UI_add_update();


SR830.UI_add_setting('popupmenu','EXPAND 1',11,3);
SR830.get_setting('EXPAND 1').UI_add_update();
SR830.UI_add_setting('popupmenu','EXPAND 2',12,3);
SR830.get_setting('EXPAND 2').UI_add_update();
SR830.UI_add_setting('popupmenu','EXPAND 3',13,3);
SR830.get_setting('EXPAND 3').UI_add_update();

%{ 
%Channel
SR830.UI_add_setting('popupmenu','channel',2,1);
SR830.get_setting('channel').add_event_fun(@SR830.channel_select)
%}

end
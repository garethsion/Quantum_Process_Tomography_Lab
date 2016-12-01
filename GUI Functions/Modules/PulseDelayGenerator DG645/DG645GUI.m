%AWG 33522 GUI module
function DG645GUI(DG645)
%% Module definition
%Optional function handles
% VSG.window_resize = @window_resize;
% VSG.metadataEdit = @metadataEdit;
% VSG.sweepControlsEdit = @sweepControlsEdit;

%% CONNECTION
DG645.UI_add_connect();
DG645.UI_add_updateall();

%% MAIN PARAMETERS

%DG645.UI_add_subpanel('Configuration: Read-only mode: Parameters will not be sent, but will be read/updated from DG645)'...
%    ,0.81,0.1);
%readonly = DG645.UI_add_setting('checkbox','manual_mode',2,1);
%readonly.add_event_fun(@DG645.set_manual_mode);

%[~, inputPos] = ModuleUICPos(2,2); inputPos(3) = inputPos(3)+0.08;
%DG645.ModuleUIC('push','Load settings from DG645', inputPos,'CallBack',@DG645.load_DG645_manual_settings_ui,'FontSize',0.4);



%% Channels
DG645.UI_add_subpanel('Channel settings',0.41,0.50);

%% AB
yIdx = 3;
DG645.UI_add_param('startA',yIdx,1);
DG645.get_param('startA').UI_add_update();
DG645.UI_add_param('delayB',yIdx,2);
DG645.get_param('delayB').UI_add_update();
DG645.UI_add_setting('edit','ampAB',yIdx,3);
DG645.get_setting('ampAB').UI_add_update();
DG645.UI_add_setting('edit','offsetAB',yIdx,4);
DG645.get_setting('offsetAB').UI_add_update();
DG645.UI_add_setting('popupmenu','polarityAB',yIdx-1,3);
DG645.get_setting('polarityAB').UI_add_update();
%% CD
yIdx = 5;
DG645.UI_add_param('startC',yIdx,1);
DG645.get_param('startC').UI_add_update();
DG645.UI_add_param('delayD',yIdx,2);
DG645.get_param('delayD').UI_add_update();
DG645.UI_add_setting('edit','ampCD',yIdx,3);
DG645.get_setting('ampCD').UI_add_update();
DG645.UI_add_setting('edit','offsetCD',yIdx,4);
DG645.get_setting('offsetCD').UI_add_update();
DG645.UI_add_setting('popupmenu','polarityCD',yIdx-1,3);
DG645.get_setting('polarityCD').UI_add_update();
%% EF
yIdx = 7;
DG645.UI_add_param('startE',yIdx,1);
DG645.get_param('startE').UI_add_update();
DG645.UI_add_param('delayF',yIdx,2);
DG645.get_param('delayF').UI_add_update();
DG645.UI_add_setting('edit','ampEF',yIdx,3);
DG645.get_setting('ampEF').UI_add_update();
DG645.UI_add_setting('edit','offsetEF',yIdx,4);
DG645.get_setting('offsetEF').UI_add_update();
DG645.UI_add_setting('popupmenu','polarityEF',yIdx-1,3);
DG645.get_setting('polarityEF').UI_add_update();
%% GH
yIdx = 9;
DG645.UI_add_param('startG',yIdx,1);
DG645.get_param('startG').UI_add_update();
DG645.UI_add_param('delayH',yIdx,2);
DG645.get_param('delayH').UI_add_update();
DG645.UI_add_setting('edit','ampGH',yIdx,3);
DG645.get_setting('ampGH').UI_add_update();
DG645.UI_add_setting('edit','offsetGH',yIdx,4);
DG645.get_setting('offsetGH').UI_add_update();
DG645.UI_add_setting('popupmenu','polarityGH',yIdx-1,3);
DG645.get_setting('polarityGH').UI_add_update();



%% Channels
yIdx = 11;
DG645.UI_add_subpanel('Trigger',0.31,0.10);

DG645.UI_add_setting('popupmenu','trigger',yIdx,1);
DG645.get_setting('trigger').UI_add_update();
end
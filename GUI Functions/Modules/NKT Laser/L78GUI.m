%WS7 GUI module
function L78GUI(L78)
%% Module definition
%Optional function handles
% WS7.window_resize = @window_resize;
% WS7.metadataEdit = @metadataEdit;
% WS7.sweepControlsEdit = @sweepControlsEdit;

%% CONNECTION
L78.UI_add_connect();       

%% MAIN 
L78.UI_add_subpanel('Wavelength Settings',0.65,0.13);

L78.UI_add_param('wavelength',2,1);
L78.get_param('wavelength').UI_add_update();

L78.UI_add_setting('edit','tolerance',2,2);


%Add pulse to table
L78.ModuleUIC('push','Calibrate first!',[0.79 0.13 0.1 ...
             0.07],'Enable','on','Callback',@L78.calibrate_Offset);
end

%%

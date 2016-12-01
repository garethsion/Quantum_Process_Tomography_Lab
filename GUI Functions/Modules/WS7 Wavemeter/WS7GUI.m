%WS7 GUI module
function WS7GUI(WS7)
%% Module definition (template)
    
%Optional function handles
% WS7.window_resize = @window_resize;
% WS7.metadataEdit = @metadataEdit;
% WS7.sweepControlsEdit = @sweepControlsEdit;

%% CONNECTION
WS7.UI_add_connect();       

%% MAIN Nothing to set up
WS7.UI_add_subpanel('Select measurements',0.75,0.17);

WS7.UI_add_setting('checkbox','measure_wavelength',2,1);
WS7.UI_add_setting('checkbox','measure_power',3,1);
end

%%

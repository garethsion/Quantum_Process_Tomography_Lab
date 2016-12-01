%ITC GUI module
function ITCGUI(ITC)
%% Module definition
%Optional function handles
% ITC.window_resize = @window_resize;
% ITC.metadataEdit = @metadataEdit;
% ITC.sweepControlsEdit = @sweepControlsEdit;

%% CONNECTION
ITC.UI_add_connect();       

%% MAIN PARAMETERS
ITC.UI_add_subpanel('Main parameters',0.79,0.13);

%FIELD: TEMPERATURE
ITC.UI_add_param('temp',2,1);

%% Trigger
uipanel('Parent',ITC.hPanel,'Title','Trigger parameters','Units','Normalized',...
        'FontUnits','Normalized','Position',[0.005 0.66 0.99 0.13],...
        'ForegroundColor','Blue','HighlightColor','Blue');      
    
end
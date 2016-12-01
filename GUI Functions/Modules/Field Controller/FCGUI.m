%Field Controller GUI module
function FCGUI(FC)
%% Module definition

%% CONNECTION
FC.UI_add_connect();
 
%% MAIN PARAMETERS
FC.UI_add_subpanel('Main parameters',0.79,0.13);

%FIELD: MAGNETIC FIELD
FC.UI_add_param('field',2,1);
FC.get_param('field').UI_add_update();

%FIELD: measured magnetic field
[textPos, inputPos] = ModuleUICPos(2,2);
FC.ModuleUIC('text','Measured field (G):',textPos,'FontSize',0.7);    
FC.hMeasField = FC.ModuleUIC('edit','',inputPos,'Enable','off');    

end
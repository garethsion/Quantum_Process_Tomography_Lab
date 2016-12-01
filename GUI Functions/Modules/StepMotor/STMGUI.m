function STMGUI( STM )
%% Module definition

%% CONNECTION
STM.UI_add_connect();
 
%% MAIN PARAMETERS
STM.UI_add_subpanel('Main parameters',0.79,0.13);

%FIELD: MAGNETIC FIELD
STM.UI_add_param('ang',2,1);
STM.get_param('ang').UI_add_update();

%FIELD: measured magnetic field
[textPos, inputPos] = ModuleUICPos(2,2);
STM.ModuleUIC('text','Angle (dgr):',textPos,'FontSize',0.7);    
STM.hMeasAng = STM.ModuleUIC('edit','',inputPos,'Enable','off');    

end
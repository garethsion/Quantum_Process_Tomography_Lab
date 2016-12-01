%WS7 GUI module
function OS2000GUI(OS2000)
%% Module definition (template)
help_text = {};
OS2000.UI_add_help(help_text);

%% CONNECTION
OS2000.UI_add_connect();       

%% TRANSIENT MODE

%NOT GOOOD!!!!!
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
OS2000.MAIN.set_transient_mode(1);
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

%% ACQUISITION PARAMETERS
OS2000.UI_add_subpanel('Acquisition parameters',0.75,0.17);
Ypos = 2;

%Spectrometer index
OS2000.UI_add_setting('popupmenu','spectroIndex',Ypos,1);

%Spectrometer channels
OS2000.UI_add_setting('popupmenu','spectroChannel',Ypos,2);

%Sensor integration time
OS2000.UI_add_setting('edit','integtime',Ypos,3);
OS2000.get_setting('integtime').UI_add_update();

%Correct for detector non-linearity
OS2000.UI_add_setting('checkbox','nonlincor',Ypos+1,1);

%Correct for electrical dark
OS2000.UI_add_setting('checkbox','elecdarkcor',Ypos+1,2);



end

%%

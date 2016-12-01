%Pulse Creator GUI module
function AWGGUI(AWG)
%% Module definition
help_text = {['\bfTrigger mode 1:\rm Internal/Computer mode for control via ' ...
              'computer or internal auto trigger. External for trigger via external input.'] ...
             ['\bfTrigger mode 2:Internal/Computer:\rm Continuous mode where the current sequence ' ...
              'is repeated continuously every SRT. Single mode where a sequence runs once when ' ...
              'receiving a trigger from the computer. AdvSeq: DO NOT USE CURRENTLY.'] ...
             ['\bfTrigger mode 2:External:\rm ']};
AWG.UI_add_help(help_text);  

%% CONNECTION
AWG.UI_add_connect();
      
%% MAIN PARAMETERS
AWG.UI_add_subpanel('Main parameters',0.79,0.13);
      
%% Trigger
AWG.UI_add_subpanel('Trigger parameters',0.66,0.13);

trigmode1 = AWG.UI_add_setting('popupmenu','trigmode1',4.5,1);
trigmode1.add_event_fun(@AWG.trigger_mode_selected);
AWG.UI_add_setting('popupmenu','trigmode2.1',4.5,2);
trigmode22 = AWG.UI_add_setting('popupmenu','trigmode2.2',4.5,2);
trigmode22.set_state_and_UIvisibility(0);
      
end

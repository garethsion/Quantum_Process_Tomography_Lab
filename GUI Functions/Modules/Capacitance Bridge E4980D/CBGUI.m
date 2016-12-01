%CB GUI module
function CBGUI(CB)
%% Module definition
help_text = {['This is a capacitance bridge']};
CB.UI_add_help(help_text);

%% CONNECTION
CB.UI_add_connect();     

%% ACQUISITION PARAMETERS
CB.UI_add_subpanel('Acquisition parameters',0.70,0.22);
Ypos = 2;

CB.UI_add_param('VOLT',Ypos,1);
CB.get_param('VOLT').UI_add_update();
CB.UI_add_param('FREQ',Ypos,2);
CB.get_param('FREQ').UI_add_update();

Ypos = 3;
bias = CB.UI_add_setting('checkbox','BIAS:STATE',Ypos,1);
CB.get_setting('BIAS:STATE').UI_add_update();
bias.add_event_fun(@(hobj, ~) toggle_BiasState_UI(CB,hobj))

CB.UI_add_param('BIAS:VOLT',Ypos,2);
CB.get_param('BIAS:VOLT').UI_add_update();
CB.get_param('BIAS:VOLT').set_state_and_UIvisibility(0)

Ypos = 4;
CB.UI_add_setting('popupmenu','MeasTime',Ypos,1);
CB.get_setting('MeasTime').UI_add_update();
CB.UI_add_setting('edit','Averaging',Ypos,2);
CB.get_setting('Averaging').UI_add_update();
 

CB.UI_add_subpanel('Measurement & Trigger',0.60,0.09);
Ypos = 6;
CB.UI_add_setting('popupmenu','TriggerType',Ypos,1);
CB.get_setting('TriggerType').UI_add_update();
CB.UI_add_setting('popupmenu','MeasType',Ypos,2);
CB.get_setting('MeasType').UI_add_update();
end


function toggle_BiasState_UI(CB,hobj,~)
        stat = get(hobj,'Value');
        CB.get_param('BIAS:VOLT').set_state_and_UIvisibility(stat);
end
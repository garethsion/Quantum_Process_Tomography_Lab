%KEI GUI module
function KEIGUI(KEI)
%% Module definition

%Optional function handles
% KEI.window_resize = @window_resize;
% KEI.metadataEdit = @metadataEdit;
% KEI.sweepControlsEdit = @sweepControlsEdit;

%% CONNECTION
KEI.UI_add_connect();       

%% SOURCE PARAMETERS
KEI.UI_add_subpanel('Source Settings',0.69,0.23);

%FIELD SETTINGS
KEI.UI_add_setting('popupmenu','source_type',2,1);
set(KEI.get_setting('source_type').hText, 'Callback', @KEI.select_source);
KEI.UI_add_setting('popupmenu','front_rear_connect',3,1);
KEI.get_setting('front_rear_connect').UI_add_update();

KEI.UI_add_setting('edit','source_voltage_range',3,2);
KEI.UI_add_setting('edit','compliance_current',4,2);
KEI.UI_add_setting('edit','source_current_range',3,2);
KEI.get_setting('source_current_range').set_state_and_UIvisibility(0)
KEI.UI_add_setting('edit','compliance_voltage',4,2);
KEI.get_setting('compliance_voltage').set_state_and_UIvisibility(0)

%FIELD: SOURCE VALUE
KEI.UI_add_param('source_voltage',2,2);
KEI.UI_add_param('source_current',2,2);
KEI.get_param('source_current').set_state_and_UIvisibility(0)               

%% Measurement Settings
KEI.UI_add_subpanel('Measure Settings',0.42,0.23);
KEI.UI_add_setting('checkbox','4wire_sense',7,1);
KEI.get_setting('4wire_sense').UI_add_update();
    
KEI.UI_add_setting('checkbox','measure_voltage',7,2);
KEI.get_setting('measure_voltage').add_event_fun(@KEI.toggle_measurement_voltage);

KEI.UI_add_setting('edit','measure_voltage_range',7,3);
KEI.get_setting('measure_voltage_range').set_state_and_UIvisibility(0)

KEI.UI_add_setting('checkbox','measure_current',8,2);
KEI.get_setting('measure_current').add_event_fun(@KEI.toggle_measurement_current);

KEI.UI_add_setting('edit','measure_current_range',8,3);



%% Filter
KEI.UI_add_subpanel('Filter Settings',0.20,0.18);

KEI.UI_add_setting('edit','integration_time_PLC',12,1);
    
end

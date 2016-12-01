function  KEI6430GUI( KEI6430 )

%% Load generic Keithley GUI for Keithley 2400 class
KEIGUI(KEI6430)
KEI6430.get_setting('front_rear_connect').set_state_and_UIvisibility(0) 

KEI6430.UI_add_setting('checkbox','filter_auto',12,2);

KEI6430.UI_add_setting('edit','measure_resistance_range',9,3);
KEI6430.get_setting('measure_resistance_range').set_state_and_UIvisibility(0)



KEI6430.UI_add_setting('checkbox','measure_resistance',9,2);
KEI6430.get_setting('measure_resistance').add_event_fun(@KEI.toggle_measurement_resistance);
end


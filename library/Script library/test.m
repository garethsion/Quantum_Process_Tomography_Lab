global MAIN;
%%



MAIN.get_mod('PG').add_pulse_to_data(1);

% MAIN.get_mod('PG').delete_pulse_from_data([1 2]);

MAIN.get_mod('PG').send_data_to_table(1);
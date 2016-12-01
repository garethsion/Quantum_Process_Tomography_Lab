classdef SR830Class < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% SR830Class is a GARII Module %%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = SR830Class()
            %Module name
            obj.name = 'Stanford SR830 Lock-in Amplifier';
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST = {{'Stanford_Research_Systems,SR830,s/n44386,ver1.07', 'visa', 'GPIB0::8::INSTR'}
                {'Stanford_Research_Systems,SR830,s/n45521,ver1.07', 'visa', 'GPIB0::9::INSTR'}};
            
            % Acquistion settings
            % obj.settings{1} = SettingClass(obj,'channels','Output channels',[],[],[],{'1' '2'});
            
            %Define parameters
            %ParameterClass(obj = current module handle, parameter_id,
            %parameter label, {1=no sweep, start value, step value, 1=sweep
            %type=linear},handle to parameter value check function, handle
            %to function for sending parameter to instrument)
            %Channel 1
            %obj.params{1} = ParameterClass(obj,'ampl1','Amplitude Vpp (V)',{1 0.1 0 1},...
%                                                                      @obj.ampl_check,@(x) obj.ampl_set(x,'1'));
            % {1, default_value, 0, 1}
            % obj.params{1} = ParameterClass(obj,'SLVL','VMOD (VRMS)',{1 0.004 0 1}, @obj.slvl_check, @obj.slvl_set); 
            % obj.params{2} = ParameterClass(obj,'FMOD','FMOD (Hz)',{1 0.001 0 1}, @obj.fmod_check, @obj.fmod_set);   
            obj.params{1} = ParameterClass(obj,'PHAS','Phase (-180<deg<180)',{1 0 0 1}, @(val)obj.check_parameter('PHAS',[-180 180],val), @(val)obj.set_parameter('PHAS',val)); 
            %obj.params{end+1} = ParameterClass(obj,'FMOD','Ref. Source (1=Ext, 2=Int)',{1 2 0 1}, @(val)obj.check_parameter('FMOD',[-1 2],val), @(val)obj.set_parameter('FMOD',val));
            obj.params{end+1} = ParameterClass(obj,'FREQ','Frequency (0.001Hz-102kHz)',{1 1.234e3 0 1}, @(val)obj.check_parameter('FREQ',[1e-2 1.02e5],val), @(val)obj.set_parameter('FREQ',val));
            %obj.params{end+1} = ParameterClass(obj,'HARM','Harmonic (1<=i<=19999)',{1 1 0 1}, @(val)obj.check_parameter('HARM',[0 19999],val), @(val)obj.set_parameter('HARM',val));
            obj.params{end+1} = ParameterClass(obj,'SLVL','Mod. Amplitude (0.004<V<5)',{1 0.004 0 1}, @(val)obj.check_parameter('SLVL',[4e-3 5],val), @(val)obj.set_parameter('SLVL',val)); 
            
            obj.params{end+1} = ParameterClass(obj,'AUXV 1','DC 1',{1 0 0 1}, @(val)obj.check_parameter('AUXV',[-10.5 10.5],val), @(val)obj.set_parameter('AUXV 1,',val)); 
            obj.params{end+1} = ParameterClass(obj,'AUXV 2','DC 2',{1 0 0 1}, @(val)obj.check_parameter('AUXV',[-10.5 10.5],val), @(val)obj.set_parameter('AUXV 2,',val)); 
            obj.params{end+1} = ParameterClass(obj,'AUXV 3','DC 3',{1 0 0 1}, @(val)obj.check_parameter('AUXV',[-10.5 10.5],val), @(val)obj.set_parameter('AUXV 3,',val)); 
            obj.params{end+1} = ParameterClass(obj,'AUXV 4','DC 4',{1 0 0 1}, @(val)obj.check_parameter('AUXV',[-10.5 10.5],val), @(val)obj.set_parameter('AUXV 4,',val)); 
            %Define settings
            %SettingClass(obj = current module handle, setting ID, setting
            %label, Initial value, handle to setting value check function, handle
            %to function for sending setting to instrument, (optional for
            %list type setting) list of choices)
            obj.settings{1} = SettingClass(obj,'manual_mode','Read-only',0,[], @obj.load_sr830_manual_settings);
            obj.settings{end+1} = SettingClass(obj,'channels','Select Channels',1,[],[],{'X' 'Y' 'R' 'Theta'});
            obj.settings{end+1} = SettingClass(obj,'ISRC','Input configuration','A',[],@obj.set_input_configuration,{'A' 'A-B' 'I (1MOhm)' 'I (100MOhm)'});
            obj.settings{end+1} = SettingClass(obj,'FMOD','Ref. Source','Internal',[],@obj.set_ref_source,{'External' 'Internal'});
            obj.settings{end+1} = SettingClass(obj,'RSLP','Ext. reference','Sine', [], @obj.set_ext_reference, {'Sine', 'TTLrising', 'TTLfalling'});
            obj.settings{end+1} = SettingClass(obj,'HARM','Harmonic (1<=i<=19999)',1, @(val)obj.check_parameter('HARM',[0 19999],val), @(val)obj.set_parameter('HARM',val));
            obj.settings{end+1} = SettingClass(obj,'OEXP 1','Offset X (%)',0, @(val)obj.check_parameter('OEXP 1',[-105 105],val), @(val)obj.set_offset(1,val));
            obj.settings{end+1} = SettingClass(obj,'OEXP 2','Offset Y (%)',0, @(val)obj.check_parameter('OEXP 2',[-105 105],val), @(val)obj.set_offset(2,val));
            obj.settings{end+1} = SettingClass(obj,'OEXP 3','Offset R (%)',0, @(val)obj.check_parameter('OEXP 3',[-105 105],val), @(val)obj.set_offset(3,val));
            obj.settings{end+1} = SettingClass(obj,'EXPAND 1','Expand X','1',[], [],{'1', '10', '100'});
            obj.settings{end+1} = SettingClass(obj,'EXPAND 2','Expand Y','1', [], [],{'1', '10', '100'});
            obj.settings{end+1} = SettingClass(obj,'EXPAND 3','Expand R','1', [], [],{'1', '10', '100'});
            SensitivityStr = {  '2 nV/fA' ...
                                '5 nV/fA ' ...
                                '10 nV/fA ' ...
                                '20 nV/fA ' ...
                                '50 nV/fA ' ...
                                '100 nV/fA'  ...
                                '200 nV/fA'  ...
                                '500 nV/fA ' ...
                                '1 uV/pA ' ...
                                '2 uV/pA ' ...
                                '5 uV/pA ' ...
                                '10 uV/pA ' ...
                                '20 uV/pA ' ...
                                '50 uV/pA' ...
                                '100 uV/pA' ...
                                '200 uV/pA' ...
                                '500 uV/pA' ...
                                '1 mV/nA' ...
                                '2 mV/nA' ...
                                '5 mV/nA' ...
                                '10 mV/nA' ...
                                '20 mV/nA' ...
                                '50 mV/nA' ...
                                '100 mV/nA' ...
                                '200 mV/nA' ...
                                '500 mV/nA' ...
                                '1 V/uA' ...
                                };
            obj.settings{end+1} = SettingClass(obj,'SENS','Sensitivity','1 V/uA', [], @(val)obj.set_sensitivity(val),SensitivityStr);
            TimeConstantStr = { '10 us ' ...
                                '30 us' ... 
                                '100 us' ...
                                '300 us' ...
                                '1 ms'  ...
                                '3 ms' ...
                                '10 ms' ...
                                '30 ms' ...
                                '100 ms' ...
                                '300 ms' ...
                                '1 s' ...
                                '3 s'  ...
                                '10 s'  ...
                                '30 s' ...
                                '100 s' ...
                                '300 s' ...
                                '1 ks' ...
                                '3 ks' ...
                                '10 ks' ...
                                '30 ks'};
            obj.settings{end+1} = SettingClass(obj,'OFLT','Time constant:', '10 ms', [], @obj.set_time_constant, TimeConstantStr);
            
            %Define measurements
            obj.measures{end+1} = MeasureClass(obj,'measureX','Channel X',@() obj.measure_channel('1'));
            obj.measures{end+1} = MeasureClass(obj,'measureY','Channel Y',@() obj.measure_channel('2'));
            obj.measures{end+1} = MeasureClass(obj,'measureR','Channel R',@() obj.measure_channel('3'));
            obj.measures{end+1} = MeasureClass(obj,'measureTheta','Channel Theta',@() obj.measure_channel('4'));
            %obj.measures{1} = MeasureClass(obj,'measure','Log Magnitude (dB)',@()obj.acquire_data,'Frequency (GHz)');    
            
            
%            obj.set_manual_mode([],[]);% this added here to ensure manual mode is check at the beginning each time
        end
        
        %Connect
        function connect(obj)
            obj.create_device();
            %{
            % reset device
            if(~isempty(obj.dev))
                obj.reset();
            end
            %}
            % obj.dev.ask('*IDN?') % this works here
            % val=obj.dev.ask('OUTP? 1')*1e12 % this works here
            % obj.dev.write(['SLVL ' num2str(1.234)]) % this works here
        end
        
        %Disconnect
        function disconnect(obj)
            % obj.reset();
            obj.dev.close;
            obj.dev = [];
        end
        
        function check_idn(obj)
            obj.dev.ask('*IDN?');
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            obj.dev.write('*RST');
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            % ok_flag = obj.tool_exp_setup();
            if obj.get_setting('manual_mode').val
                obj.load_sr830_manual_settings(1)
            end
            ok_flag = obj.tool_exp_setup('no_check');
        end
        
        %During experiment, sweep to next point
        %pos = [X Y PC] index value, type = which pos is changed
        function ok_flag = experiment_next(obj,type,pos)
            %Sweep to next point
            ok_flag = obj.tool_exp_next(type,pos,'no_check');
        end
        
        %Trigger
        function experiment_trigger(obj)
        end 
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            if(~isempty(obj.dev))                
                ok_flag = 1;
            else
                ok_flag = 0;
            end
        end
        
        %Trigger for measurement
        function experiment_setread(obj)
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
    end
    
    %GUI methods
    methods (Access = public)
        function select_meas_channel(obj,~,~)
            value = obj.get_setting('channels').val;
            
            obj.get_measure('measureX').state = 0;
            obj.get_measure('measureY').state = 0;
            obj.get_measure('measureR').state = 0;
            obj.get_measure('measureTheta').state = 0;
            if(any(value == 1)) 
                obj.get_measure('measureX').state = 1;
            end
            if(any(value == 2))
                obj.get_measure('measureY').state = 1;
            end
            if(any(value == 3)) 
                obj.get_measure('measureR').state = 1;
            end
            if(any(value == 4))
                obj.get_measure('measureTheta').state = 1;
            end
        end 
        
        % special for lock-in: read-only mode
        function set_manual_mode(obj,checkbox,~)
            value = ~checkbox.Value;
            for ctPar = 1:numel(obj.params)
                obj.params{ctPar}.set_state_and_UIvisibility(value)
            end
            for ctPar = 3:numel(obj.settings)
                obj.settings{ctPar}.set_state_and_UIvisibility(value)
            end
            
            %for ctSet = 1:numel(obj.settings)
            %    obj.settings{ctSet}.set_state(value);
            %end
        end
        
        function load_sr830_manual_settings_ui(obj,pushbutton,~)
            obj.load_sr830_manual_settings(1)
        end
        function load_sr830_manual_settings(obj,val)
            if val
                %obj.dev.ask('*CLS')
                for ct = 1:numel(obj.params)
                    par = obj.params{ct};
                    split_name = strsplit(par.name);
                    if numel(split_name) == 1
                        val = obj.dev.ask([par.name '?']);
                    elseif numel(split_name) == 2 % specific for AUXV 1, AUXV 2 etc
                        val = obj.dev.ask([split_name{1} '?' split_name{2}]);
                    else
                        display(sprintf('(load_sr830_manual_settings) Load setting %s from SR830: Wrong parameter name', par.name))
                    end
                    par.param{2}=str2num(val);
                    par.update_label
                end
                
                for ct = 3:numel(obj.settings) %SETTINGS 1 & 2 are not lock-in settings
                    setting = obj.settings{ct};
                    split_name = strsplit(setting.name);
                    if numel(split_name) == 1
                    ask_str = [setting.name ' ?'];
                    val = obj.dev.ask(ask_str);
                        if strcmpi(setting.hText.Style,'edit')
                            setting.hText.String = val;
                        else
                            setting.hText.Value = str2num(val)+1;
                        end
                        setting.update_val;
                        
                    elseif numel(split_name) == 2 
                            if strcmpi(split_name{1}, 'OEXP')
                                val = obj.dev.ask([split_name{1} ' ?' split_name{2}]);
                                split_val = strsplit(val, ',');
                                setting.hText.String = split_val{1};
                                setting.update_val;
                                expand_setting = obj.get_setting(['EXPAND ' split_name{2}]);
                                expand_setting.hText.Value = str2num(split_val{2})+1;
                                expand_setting.update_val;
                            elseif strcmpi(split_name{1}, 'EXPAND')
                                continue
                            end
                    end
                end
            end
        end
        
        function set_ref_source(obj, val)
            if strcmpi(val,'External')
                obj.set_parameter('FMOD',0)
            elseif strcmpi(val,'Internal')
                obj.set_parameter('FMOD',1)
            else
                display('SR830: set_ref_source: Got wrong variable')
            end
        end
        
        function set_sensitivity(obj, val)
            sens_set = obj.get_setting('SENS');
            sens_idx = strmatch(val,sens_set.list)-1;
            obj.set_parameter('SENS', sens_idx);
        end
        function set_time_constant(obj, val)
            sens_set = obj.get_setting('OFLT');
            sens_idx = strmatch(val,sens_set.list)-1;
            obj.set_parameter('OFLT', sens_idx);
        end
        
        function set_input_configuration(obj, val)
            sens_set = obj.get_setting('ISRC');
            sens_idx = strmatch(val,sens_set.list,'exact')-1;
            obj.set_parameter('ISRC', sens_idx);
        end
        
        
        function set_ext_reference(obj, val)
            sens_set = obj.get_setting('RSLP');
            sens_idx = strmatch(val,sens_set.list,'exact')-1;
            obj.set_parameter('RSLP', sens_idx);
        end
        
        function set_offset(obj, channel, val)
            expand_set = obj.get_setting(sprintf('EXPAND %i', channel));
            exp_idx = expand_set.hText.Value-1;
            obj.dev.write(sprintf('OEXP %i, %g, %i', channel, val, exp_idx));
        end
    end
    
    %Internal functions
    methods (Access = private)
        
        function val = measure_channel(obj,chan) 
            % Read value from Lock-in
            val = obj.dev.ask(['OUTP? ' chan]);
            val = str2double(val);
        end

        function set_parameter(obj,param,value)
            obj.dev.write([param ' ' num2str(value)]);
        end 
        
        function val = read_parameter(obj,param)
            val = obj.dev.ask([param '?']);
            val = str2double(val);
        end 
        
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        % ========== FOR SR830 ========== %
        function flag = check_parameter(obj,param,MinMax,value) % modulation amplitude
            flag = 1;
            
            if(any(value < MinMax(1) | value > MinMax(2))) 
                flag = 0;
                obj.msgbox(['(' param ') out of range.']);
            end
        end        
        
    end
end


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
            obj.INST = {{'Stanford_Research_Systems,SR830,s/n44386,ver1.07 ', 'visa', 'GPIB0::8::INSTR'} ...
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
            obj.params{2} = ParameterClass(obj,'FMOD','Ref. Source (1=Ext, 2=Int)',{1 2 0 1}, @(val)obj.check_parameter('FMOD',[-1 2],val), @(val)obj.set_parameter('FMOD',val));
            obj.params{3} = ParameterClass(obj,'FREQ','Frequency (0.001Hz-102kHz)',{1 1.234e3 0 1}, @(val)obj.check_parameter('FREQ',[1e-2 1.02e5],val), @(val)obj.set_parameter('FREQ',val));
            obj.params{4} = ParameterClass(obj,'RSLP','Ext. ref. (1=Sine, 2=TTLr, 3=TTLf)',{1 1 0 1}, @(val)obj.check_parameter('RSLP',[-1 3],val), @(val)obj.set_parameter('RSLP',val));
            obj.params{5} = ParameterClass(obj,'HARM','Harmonic (1<=i<=19999)',{1 1 0 1}, @(val)obj.check_parameter('HARM',[0 19999],val), @(val)obj.set_parameter('HARM',val));
            obj.params{6} = ParameterClass(obj,'SLVL','Mod. Amplitude (0.004<V<5)',{1 0.004 0 1}, @(val)obj.check_parameter('SLVL',[4e-3 5],val), @(val)obj.set_parameter('SLVL',val)); 
            
            obj.params{7} = ParameterClass(obj,'AUXV1','DC 1',{1 0 0 1}, @(val)obj.check_parameter('AUXV',[-10.5 10.5],val), @(val)obj.set_parameter('AUXV 1',val)); 
            %Define settings
            %SettingClass(obj = current module handle, setting ID, setting
            %label, Initial value, handle to setting value check function, handle
            %to function for sending setting to instrument, (optional for
            %list type setting) list of choices)
            obj.settings{1} = SettingClass(obj,'channels','Select Channels',1,[],[],{'1' '2'});
            obj.settings{2} = SettingClass(obj,'manual_mode','Read-only',1,[],[]);
            
            % Define Measurements
            %Define measurements
            obj.measures{1} = MeasureClass(obj,'measure1','Channel 1',@() obj.measure_channel('1'));
            obj.measures{2} = MeasureClass(obj,'measure2','Channel 2',@() obj.measure_channel('2'));
            %obj.measures{1} = MeasureClass(obj,'measure','Log Magnitude (dB)',@()obj.acquire_data,'Frequency (GHz)');    
            
            
            obj.set_manual_mode([],[]);% this added here to ensure manual mode is check at the beginning each time
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
            
            obj.get_measure('measure1').state = 0;
            obj.get_measure('measure2').state = 0;
            if(any(value == 1)) 
                obj.get_measure('measure1').state = 1;
            end
            if(any(value == 2))
                obj.get_measure('measure2').state = 1;
            end
        end 
        
        % special for lock-in: read-only mode
        function set_manual_mode(obj,~,~)
            value = ~obj.get_setting('manual_mode').val;
            for ctPar = 1:numel(obj.params)
                obj.params{ctPar}.set_state(value);
            end
            
            for ctSet = 1:numel(obj.settings)
                obj.settings{ctSet}.set_state(value);
            end
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


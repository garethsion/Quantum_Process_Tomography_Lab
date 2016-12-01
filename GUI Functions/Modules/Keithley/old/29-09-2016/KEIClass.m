classdef KEIClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% KEIClass is a GARII Module %%%%%%%%%%%%%%
    %%%%%%%%% Keithley SourceMeters %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%!! WAS ORIGINALLY WRITTEN FOR 6430, became superclass later
    
    
    %Internal parameters
    properties (Access = private)
        measurement_storage = zeros(3,1);
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = KEIClass()
            %Module name
            obj.name = 'Keithley Sourcemeter';
            
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST = {{'TO BE FILLED BY INHERITED CLASS', 'visa', 'GPIB0::XX::INSTR'}};


            %Define parameters
            obj.params{1} = ParameterClass(obj,'source_voltage','Source voltage (V)',{1 0 0 1},...
                                           @obj.source_voltage_check,@obj.set_source_voltage);
            obj.params{2} = ParameterClass(obj,'source_current','Source current (A)',{1 0 0 1},...
                                           @obj.source_current_check,@obj.set_source_current);
                                       
            %Define settings
            obj.settings{1} = SettingClass(obj,'source_type','Source Type','Voltage',[],...
                @obj.set_source_type,{'Voltage','Current'});
            obj.settings{end+1} = SettingClass(obj,'source_voltage_range','Source voltage range (V)',20,...
                @obj.source_voltage_check, @obj.set_source_voltage_range);
            obj.settings{end+1} = SettingClass(obj,'source_current_range','Source current range (A)',1e-4,...
                @obj.source_current_check, @obj.set_source_current_range);
            obj.settings{end+1} = SettingClass(obj,'compliance_voltage','Voltage compliance (V)',...
                21, @obj.compliance_volt_check, @obj.set_compliance_voltage);
            obj.settings{end+1} = SettingClass(obj,'compliance_current','Current compliance (A)',...
                105e-6, @obj.compliance_curr_check, @obj.set_compliance_current);
            obj.settings{end+1} = SettingClass(obj,'measure_voltage','Measure voltage',0,...
                [], @obj.set_measure_voltage);
            obj.settings{end+1} = SettingClass(obj,'measure_current','Measure current',1,...
                [], @obj.set_measure_current);
            obj.settings{end+1} = SettingClass(obj,'measure_voltage_range','Measurement range (V)',21,...
                @obj.measure_voltage_range_check, @obj.set_measure_voltage_range);
            obj.settings{end+1} = SettingClass(obj,'measure_current_range','Measurement range (A)',1.05e-4,...
                @obj.measure_current_range_check, @obj.set_measure_current_range);
            obj.settings{end+1} = SettingClass(obj,'integration_time_PLC','Integration time (NPLC)',1,...
                @obj.integration_time_PLC_check, @obj.set_integration_time_PLC);
            
            %Define measurements
            obj.measures{1} = MeasureClass(obj,'voltage','Voltage (V)',@()obj.measure_voltage_triggered());
            obj.measures{2} = MeasureClass(obj,'current','Current (A)',@()obj.measure_current_triggered());
        end
        
        %Connect
        function connect(obj)
            obj.create_device();
            if(~isempty(obj.dev))
                obj.reset();
            end
            
            % Following is not proper. Needs checkbox
           % obj.measures{1}.state = 1;
        end
        
        %Disconnect
        function disconnect(obj)
            obj.reset();
            obj.dev.close;
            obj.dev = [];
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            obj.dev.write('*RST')
            obj.dev.check('KEI reset function');
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            ok_flag = obj.tool_exp_setup();
            if(ok_flag)
                %Turn on device
                obj.set_output_status(1);
            end
        end
        
        function experiment_setread(obj)
        end
        
        %During experiment, sweep to next point
        %pos = [X Y PC] index value, type = which pos is changed
        function ok_flag = experiment_next(obj,type,pos)
            %Sweep to next point
            ok_flag = obj.tool_exp_next(type,pos);
        end
        
        %Trigger
        function experiment_trigger(obj)
            obj.measurement_storage = obj.measure_all;
        end 
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            if(~isempty(obj.dev))
                obj.set_output_status(0);
                ok_flag = 1;
            else
                ok_flag = 0;
            end
        end
    end
    
    %GUI methods
    methods (Access = public)
        function select_source(obj,hobj,~)
            sel_source = get(hobj,'Value');
            if sel_source ==1
                obj.get_setting('source_type').val = 'Voltage';
                obj.get_param('source_voltage').set_state_and_UIvisibility(1) 
                obj.get_param('source_current').set_state_and_UIvisibility(0)

                obj.get_setting('source_voltage_range').set_state_and_UIvisibility(1)
                obj.get_setting('compliance_current').set_state_and_UIvisibility(1)
                obj.get_setting('source_current_range').set_state_and_UIvisibility(0)
                obj.get_setting('compliance_voltage').set_state_and_UIvisibility(0)
            elseif sel_source == 2
                obj.get_setting('source_type').val = 'Current';
                obj.get_param('source_voltage').set_state_and_UIvisibility(0) 
                obj.get_param('source_current').set_state_and_UIvisibility(1)

                obj.get_setting('source_voltage_range').set_state_and_UIvisibility(0)
                obj.get_setting('compliance_current').set_state_and_UIvisibility(0)
                obj.get_setting('source_current_range').set_state_and_UIvisibility(1)
                obj.get_setting('compliance_voltage').set_state_and_UIvisibility(1)
                else
                display('Wrong input parameter for KEIGUI.select_source')
            end
        end

        function toggle_measurement_voltage(obj,hobj,~)
            stat = get(hobj,'Value');
            if stat == 0
                obj.get_setting('measure_voltage').val = 0;
                obj.get_setting('measure_voltage_range').set_state_and_UIvisibility(0);
            elseif stat == 1
                obj.get_setting('measure_voltage').val = 1;
                obj.get_setting('measure_voltage_range').set_state_and_UIvisibility(1);
            else
                display('Wrong input parameter for KEIGUI.toggle_measurement_voltage')
            end
        end
        
        function toggle_measurement_current(obj,hobj,~)
            stat = get(hobj,'Value');
            if stat == 0
                obj.get_setting('measure_current').val = 0;
                obj.get_setting('measure_current_range').set_state_and_UIvisibility(0);
            elseif stat == 1
                obj.get_setting('measure_current').val = 1;
                obj.get_setting('measure_current_range').set_state_and_UIvisibility(1);
            else
                display('Wrong input parameter for KEIGUI.toggle_measurement_current')
            end
        end

    end
    
    %Wrapper for internal functions
    methods (Access = public)
    
    % Output function
        function set_output_status(obj,status) %status = 0/1 > turn output off/on
            if any(status == 1) || strcmpi(status,'on') 
                obj.dev.write(':OUTP ON');
            elseif any(status == 0) || strcmpi(status,'off')
                obj.dev.write(':OUTP OFF');
            else
                display('Unknown input for Keithley set_output_status');
            end
        end
        
        function status = get_output_status(obj) %status = 0/1 > turn output off/on
            status = str2num(obj.dev.ask(':OUTP?'));
        end
        
     % Source functions   
        function set_source_type(obj, type) %'volt'/'curr'
            % Check source type parameter and set source
            source_type = obj.get_setting('source_type');
            if any(strcmpi(type, {'volt', 'voltage','v'}))
                    obj.dev.write(':SOUR:FUNC VOLT');
                    source_type.val= 'Voltage';
            elseif any(strcmpi(type, {'curr', 'current','a','i'}))
                    obj.dev.write(':SOUR:FUNC CURR');
                    source_type.val= 'Current';
            end 
        end    
        
        function type = get_source_type(obj) %'volt'/'curr'
            % Check source type 
            type = lower(obj.dev.ask(':SOUR:FUNC?'));
        end    
        
        function set_source_voltage(obj,value) %Volt/Ampere
            % Check source type and send value
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                obj.dev.write(sprintf(':SOUR:VOLT:LEV %g',value));
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                display('Cant set source voltage: Source type is current')
            end 
        end   
        
        function set_source_current(obj,value) %Volt/Ampere
            % Check source type and send value
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                display('Cant set source current: Source type is voltage')
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                obj.dev.write(sprintf(':SOUR:CURR:LEV %g',value));
            end 
        end    
        
        function source_val = get_source_voltage(obj)
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                source_val = str2num(obj.dev.ask(':SOUR:VOLT:LEV?'));
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                display('Cant get source voltage: Source type is current')
            end 
        end
        
        function source_current = get_source_current(obj)
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                display('Cant get source current: Source type is voltage')
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                source_current = str2num(obj.dev.ask(':SOUR:CURR:LEV?'));
            end 
        end
        
        function set_compliance_current(obj,value) %Volt/Ampere
            % If source is volt, set current compliance and vice versa
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                    obj.dev.write(sprintf(':SENS:CURR:PROT %g',value));
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                    display('Cant set current compliance: Source type is current.')
            end 
        end    
        
        function set_compliance_voltage(obj,value) %Volt/Ampere
            % If source is volt, set current compliance and vice versa
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                    display('Cant set voltage compliance: Source type is voltage.')
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                    obj.dev.write(sprintf(':SENS:VOLT:PROT %g',value));
            end 
        end    
        
        function set_source_voltage_range(obj,value) %Volt/Ampere
            % Check source type and send value
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                obj.dev.write(sprintf(':SOUR:VOLT:RANG %g',value));
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                display('Cant set source voltage range: Source type is current.')
            end 
        end
        
        function set_source_current_range(obj,value) %Volt/Ampere
            % Check source type and send value
            if strcmpi(obj.get_setting('source_type').val, 'voltage')
                display('Cant set source current range: Source type is voltage.')
            elseif strcmpi(obj.get_setting('source_type').val, 'current')
                obj.dev.write(sprintf(':SOUR:CURR:RANG %g',value));
            end 
        end
        
        function set_measure_voltage(obj,val)
            meas=obj.get_measure('voltage');
            if any(val == 1) || strcmpi(val,'on') 
                    obj.dev.write(':SENS:FUNC:ON "VOLT"')
                    meas.state=1;
                    obj.get_setting('measure_voltage').val=1;
            elseif any(val == 0) || strcmpi(val,'off') 
                    obj.dev.write(':SENS:FUNC:OFF "VOLT"')
                    meas.state=0;
                    obj.get_setting('measure_voltage').val=0;
            end
        end
        
        function set_measure_current(obj,val)
            meas=obj.get_measure('current');
            if any(val == 1) || strcmpi(val,'on') 
                    obj.dev.write(':SENS:FUNC:ON "CURR"')
                    obj.get_setting('measure_current').val=1;
                    meas.state=1;
            elseif any(val == 0) || strcmpi(val,'off') 
                    obj.dev.write(':SENS:FUNC:OFF "CURR"')
                    obj.get_setting('measure_current').val=0;
                    meas.state=0;
            end
        end
        
          
        function set_measure_voltage_range(obj, value)
            if obj.get_setting('measure_voltage').val==1
                if strcmpi(obj.get_setting('source_type').val, 'voltage')
                    display('Voltage measurement range can not be set when sourcing volts!')
                else
                    obj.dev.write(sprintf(':SENS:VOLT:RANG %g',value));
                end
            else
                display('Cant set voltage measurement range. Voltage measurement not active!')
            end
        end
        
        function set_measure_current_range(obj, value)
            if obj.get_setting('measure_current').val==1
                if strcmpi(obj.get_setting('source_type').val, 'current')
                    display('Current measurement range can not be setwhen sourcing current!')
                else
                    obj.dev.write(sprintf(':SENS:CURR:RANG %g',value));
                end
            else
                display('Cant set current measurement range. Current measurement not active!')
            end
        end
        
        function val=measure_all(obj)
            %% Measure [volt, curr, res]. 
            % only active measurement variables return sensible results 
            
            % Check if output is on
            if obj.get_output_status == 0
                error('Turn output on before measuring');
            end
            % Read value from Keithley
            reply = obj.dev.ask('READ?;');
            %obj.dev.gpibioObj.write('READ?;'); <-- Maybe tweak for better performance?
            %pause(1.2);
            %reply = obj.dev.gpibioObj.read();
            values = regexp(reply,',','split');
            val = [str2num(cell2mat(values(1))),... 
                str2num(cell2mat(values(2))),...
                str2num(cell2mat(values(3)))];
        end
        
        function val=measure_voltage_singleShot(obj)
            
            % Check if output is on
            if obj.get_output_status == 0
                error('Turn output on before measuring');
            end
            % Read value from Keithley
            reply = obj.dev.ask('READ?;');
            %obj.dev.gpibioObj.write('READ?;'); <-- Maybe tweak for better performance?
            %pause(1.2);
            %reply = obj.dev.gpibioObj.read();
            values = regexp(reply,',','split');
            val = str2num(cell2mat(values(1)));
            
            if obj.get_setting('measure_voltage').val == 0
                display('Cant measure voltage: Voltage measurement not active')
            end
        end
        
        function val=measure_current_singleShot(obj)
            % Check if output is on
            if obj.get_output_status == 0
                error('Turn output on before measuring');
            end
            % Read value from Keithley
            reply = obj.dev.ask('READ?;');
            %obj.dev.gpibioObj.write('READ?;'); <-- Maybe tweak for better performance?
            %pause(1.2);
            %reply = obj.dev.gpibioObj.read();
            values = regexp(reply,',','split');
            val = str2num(cell2mat(values(2)));
            
            
            if obj.get_setting('measure_current').val == 0
                display('Cant measure current: Current measurement not active')
            end
        end
        
        function val=measure_voltage_triggered(obj)
            val = obj.measurement_storage(1);
        end
        
        function val=measure_current_triggered(obj)
            val = obj.measurement_storage(2);
        end
        
        function val=measure_resistance_triggered(obj)
            val = obj.measurement_storage(3);
        end
        
        function set_integration_time_PLC(obj, value)
            % Simply write all channels
            if 0.01<value<10
                obj.dev.write(sprintf('SENS:CURR:NPLC %.2g', value))
            else
                error('NPLC should be between 0.01 and 10!')
            end
        end
        
    end
    
    %Internal functions
    methods (Access = private)
        
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = source_current_check(obj,value) %Volt/Ampere
            flag = 1;
            if any([abs(value)>0.105])
                flag=0; 
            obj.msgbox('Select source current from [0.5fA 105mA]');
            end
        end
            
        function flag = source_voltage_check(obj,value) %Volt/Ampere
            flag = 1;
            if any([abs(value)>210])
                flag=0;
                obj.msgbox('Select source voltage from [5uV 210V]')
            end 
        end   
        
        function flag = compliance_volt_check(obj,value) %Volt/Ampere
            flag =1; 
            if any([value<0.21,value>210])
                flag=0;
                obj.msgbox('Select compliance voltage from [210mV 210V]')
            end 
        end      
        
        function flag = compliance_curr_check(obj,value) %Volt/Ampere
            flag = 1;
            if any([value<1.05e-12,value>0.105])
                flag=0;
                obj.msgbox('Select compliance current from [1.05pA 105mA]')
            end 
        end
        
        function flag = measure_voltage_range_check(obj, value) %Volt
            flag = 1;
            if any([value<-210,value>210])
                flag=0;
                obj.msgbox('Select voltage measurement range from [-210V 210V]')
            end 
        end     
        
        function flag = measure_current_range_check(obj, value) %Ampere
            flag = 1;
            
            if any([value<-105e-3,value>105e-3])
                flag=0;
                obj.msgbox('Select current measurement range from [-105mA 105mA]')
            end 
        end     
        
        function flag = integration_time_PLC_check(obj, value)
            flag = 1;
            if any([value<0.01,value>10])
                flag = 0;
                obj.msgbox('Choose Intergration time from range [0.01 10]')
            end
        end
        
    end
end

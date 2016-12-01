classdef KEI6430Class < KEIClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% KEI2400 is a GARII Module %%%%%%%%%%%%%%
    %%%%%%%%% Implementation of Keithley 2400  %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = public)
        
        function obj = KEI6430Class()
            obj = obj@KEIClass(); %Build superclass values
            % Change the name and ID to KEI2400
            obj.name = 'Keithley 6430';
            obj.INST = {{'KEITHLEY INSTRUMENTS INC.,MODEL 6430,1141613,C27   Jul 12 2004 15:47:33/A02  /D/B', 'visa', 'GPIB0::26::INSTR'}};
            
            obj.settings{end+1} = SettingClass(obj,'measure_resistance','Measure resistance',0,...
                [], @obj.set_measure_resistance);
            obj.settings{end+1} = SettingClass(obj,'measure_resistance_range','Measurement range (Ohm)',2.1e5,...
                @obj.measure_resistance_range_check, @obj.set_measure_resistance_range);
            obj.settings{end+1} = SettingClass(obj,'filter_auto','Auto Filter',1,...
                [], @obj.set_filter_auto);
            
            
            obj.measures{3} = MeasureClass(obj,'resist','Resistance (Ohm)',@()obj.measure_resistance_triggered());
            
        end
        
        
        function toggle_measurement_resistance(obj,hobj,~)
            stat = get(hobj,'Value');
            if stat == 0
                obj.get_setting('measure_resistance').val = 0;
                obj.get_setting('measure_resistance_range').set_state_and_UIvisibility(0);
            elseif stat == 1
                obj.get_setting('measure_resistance').val = 1;
                obj.get_setting('measure_resistance_range').set_state_and_UIvisibility(1);
            else
                display('Wrong input parameter for KEIGUI.toggle_measurement_resistance')
            end
        end
        
        function set_measure_resistance(obj,val)
            meas=obj.get_measure('resist');
            if any(val == 1) || strcmpi(val,'on') 
                    obj.dev.write(':SENS:FUNC:ON "RES"')
                    obj.get_setting('measure_resistance').val=1;
                    meas.state=1;
            elseif any(val == 0) || strcmpi(val,'off') 
                    obj.dev.write(':SENS:FUNC:OFF "RES"')
                    obj.get_setting('measure_resistance').val=0;
                    meas.state=0;
            end
        end
        
        function set_measure_resistance_range(obj,value)
            if obj.get_setting('measure_resistance').val==1
                obj.dev.write(sprintf(':SENS:RES:RANG %g',value));
            end
        end
        
        function val=measure_resistance_singleShot(obj)
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
            val = str2num(cell2mat(values(3)));
            
            if obj.get_setting('measure_resistance').val == 0
                display('Cant measure resistance: Resistance measurement not active')
            end
        end
        
        function set_filter_auto(obj,status) %status = 0/1 > turn output off/on
            if any(status == 1) || strcmpi(status,'on') 
                obj.dev.write(':AVER 1');
                obj.dev.write(':AVER:AUTO 1');
            elseif any(status == 0) || strcmpi(status,'off')
                obj.dev.write(':AVER:AUTO 0');
                obj.dev.write(':AVER 0');
                obj.dev.write(':AVER:REP 0');
                obj.dev.write(':MED 0');
                obj.dev.write(':AVER:ADV 0');
            else
                display('Unknown input for Keithley set_output_status');
            end
        end
        
        function flag = measure_resistance_range_check(obj, value) %Ohm
            flag = 1;
            
            if any([value<0,value>2.1e13])
                flag=0;
                obj.msgbox('Select resistance measurement range from [0 1e13 Ohm]')
            end 
        end     
        
    end
    
end


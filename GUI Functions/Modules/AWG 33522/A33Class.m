classdef A33Class < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% A33Class is a GARII Module %%%%%%%%%%%%%%%
    %%%%%%%%%  Vector Signal generator Agilent PSG E8267D %%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = A33Class()
            %Module name
            obj.name = 'AWG 33522A';
            
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST = {%{'Agilent Technologies,33522A,MY50005952,2.03-1.19-2.00-52-00', 'visa', 'USB0::0x0957::0x2307::MY50005952::INSTR'} ...
                        {'Agilent Technologies,33522A,MY50005952,2.03-1.19-2.00-52-00', 'visa', 'GPIB0::10::INSTR'} ...
                               {'Agilent Technologies,33522A,MY50005953,2.03-1.19-2.00-52-00', 'visa', 'USB0::0x0957::0x2307::MY50005953::INSTR'} ...
                               {'Agilent Technologies,33522A,MY50006029,2.09-1.19-2.00-52-00', 'visa', 'USB0::2391::8967::MY50006029::INSTR'}...
                               {'Agilent Technologies,33522A,MY50006018,2.09-1.19-2.00-52-00', 'visa', 'GPIB0::15::INSTR'}};
                               %{'Agilent Technologies,33522A,MY50006018,2.09-1.19-2.00-52-00', 'visa', 'USB0::2391::8967::MY50006018::INSTR'}...
            
            %Define parameters
            %ParameterClass(obj = current module handle, parameter_id,
            %parameter label, {1=no sweep, start value, step value, 1=sweep
            %type=linear},handle to parameter value check function, handle
            %to function for sending parameter to instrument)
            %Channel 1
            obj.params{1} = ParameterClass(obj,'freq1','Frequency (Hz)',{1 1e6 0 1},...
                                                                     @obj.freq_check,@(x) obj.freq_set(x,'1'));
            obj.params{2} = ParameterClass(obj,'ampl1','Amplitude Vpp (V)',{1 0.1 0 1},...
                                                                     @obj.ampl_check,@(x) obj.ampl_set(x,'1'));
            obj.params{3} = ParameterClass(obj,'amploff1','Amplitude offset (V)',{1 0 0 1},...
                                                                     @obj.amploff_check,@(x) obj.amploff_set(x,'1'));
            obj.params{4} = ParameterClass(obj,'phas1','Phase  (degree)',{1 0 0 1},...
                                                                     @obj.phas_check,@(x) obj.phas_set(x,'1'));
                                                                 
            %Channel 2
            obj.params{5} = ParameterClass(obj,'freq2','Frequency (Hz)',{1 1e6 0 1},...
                                                                     @obj.freq_check,@(x) obj.freq_set(x,'2'));
            obj.params{6} = ParameterClass(obj,'ampl2','Amplitude Vpp (V)',{1 0.1 0 1},...
                                                                     @obj.ampl_check,@(x) obj.ampl_set(x,'2'));
            obj.params{7} = ParameterClass(obj,'amploff2','Amplitude offset (V)',{1 0 0 1},...
                                                                     @obj.amploff_check,@(x) obj.amploff_set(x,'2'));
            obj.params{8} = ParameterClass(obj,'phas2','Phase  (degree)',{1 0 0 1},...
                                                                     @obj.phas_check,@(x) obj.phas_set(x,'2'));
                                       
            %Define settings
            %SettingClass(obj = current module handle, setting ID, setting
            %label, Initial value, handle to setting value check function, handle
            %to function for sending setting to instrument, (optional for
            %list type setting) list of choices)
            obj.settings{1} = SettingClass(obj,'channel','Channel','1',[],[],{'1' '2'});
                                                           
            %Channel 1
            obj.settings{2} = SettingClass(obj,'status1','Status','Off',[],@(x) obj.status_set(x,'1'), ...
                                                               {'On' 'Off'});
            obj.settings{3} = SettingClass(obj,'wavetype1','Waveform','Sine',[],@(x) obj.waveform_set(x,'1'), ...
                                                               {'Sine' 'Square' 'Triangle' 'Ramp' 'DC'});
            obj.settings{4} = SettingClass(obj,'load1','Output load','50 Ohm',[],@(x) obj.load_set(x,'1'), ...
                                                               {'50 Ohm' 'High impedance'});
                                                           
           %Channel 2
            obj.settings{5} = SettingClass(obj,'status2','Status','Off',[],@(x) obj.status_set(x,'2'), ...
                                                               {'On' 'Off'});
            obj.settings{6} = SettingClass(obj,'wavetype2','Waveform','Sine',[],@(x) obj.waveform_set(x,'2'), ...
                                                               {'Sine' 'Square' 'Triangle' 'Ramp' 'DC'});
            obj.settings{7} = SettingClass(obj,'load2','Output load','50 Ohm',[],@(x) obj.load_set(x,'2'), ...
                                                               {'50 Ohm' 'High impedance'});
        end
        
        %Connect
        function connect(obj)
            obj.create_device();
            if(~isempty(obj.dev))
                obj.reset();
            end
        end
        
        %Disconnect
        function disconnect(obj)
            obj.reset();
            obj.dev.close;
            obj.dev = [];
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            obj.dev.write('UNIT:ANGL DEG');
            
            obj.dev.check([obj.name ' reset function']);
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            ok_flag = obj.tool_exp_setup();
        end
        
        %During experiment, sweep to next point
        %pos = [X Y PC] index value, type = which pos is changed
        function ok_flag = experiment_next(obj,type,pos)
            %Sweep to next point
            ok_flag = obj.tool_exp_next(type,pos);
        end
        
        %Trigger
        function experiment_trigger(obj)
        end 
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            if(~isempty(obj.dev))                
                obj.status_set('Off','1');
                obj.status_set('Off','2');
                ok_flag = 1;
            else
                ok_flag = 0;
            end
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
    end
    
    %GUI methods
    methods (Access = public)
        function channel_select(obj,~,~)
            if(obj.get_setting('channel').val == 1)
                flag1 = 1;
                flag2 = 0;
            else
                flag1 = 0;
                flag2 = 1;
            end

            obj.get_setting('status1').set_UIvisibility(flag1);
            obj.get_setting('status2').set_UIvisibility(flag2);

            obj.get_setting('wavetype1').set_UIvisibility(flag1);
            obj.get_setting('wavetype2').set_UIvisibility(flag2);

            obj.get_setting('load1').set_UIvisibility(flag1);
            obj.get_setting('load2').set_UIvisibility(flag2);

            obj.get_param('ampl1').set_UIvisibility(flag1);
            obj.get_param('ampl2').set_UIvisibility(flag2);

            obj.get_param('freq1').set_UIvisibility(flag1);
            obj.get_param('freq2').set_UIvisibility(flag2);

            obj.get_param('amploff1').set_UIvisibility(flag1);
            obj.get_param('amploff2').set_UIvisibility(flag2);

            obj.get_param('phas1').set_UIvisibility(flag1);
            obj.get_param('phas2').set_UIvisibility(flag2);
        end
    end
    
    %Internal functions
    methods (Access = public)
        %Frequency parameter
        function freq_set(obj,value,chan) %Hz
            obj.dev.write([':SOUR' chan ':FREQ ' num2str(value)]);
        end        
        
        %Amplitude parameter
        function ampl_set(obj,value,chan) %V
            obj.dev.write([':SOUR' chan ':VOLT ' num2str(value) ' Vpp']);
        end
        
        %Amplitude offset parameter
        function amploff_set(obj,value,chan) %V
            obj.dev.write([':SOUR' chan ':VOLT:OFFS ' num2str(value) ' V']);
        end
        
        %Phase parameter
        function phas_set(obj,value,chan) %Degree
            wavetype = obj.get_setting(['wavetype' chan]).val;
            if(~strcmp(wavetype,'DC'))
                obj.dev.write([':SOUR' chan ':PHAS ' num2str(value) ]);
            end
        end
        
        %Set status setting
        function status_set(obj,value,chan)
            switch(value)
                case 'On' 
                    obj.dev.write(['OUTP' chan ' 1']);   
                    
                case 'Off'
                    obj.dev.write(['OUTP' chan ' 0']);   
            end
        end
        
        %Set waveform setting
        function waveform_set(obj,value,chan)
            switch(value)
                case 'Sine' 
                    obj.dev.write(['SOUR' chan ':FUNC SIN']);   
                
                case 'Square' 
                    obj.dev.write(['SOUR' chan ':FUNC SQU']);  
                    
                case 'Triangle'
                    obj.dev.write(['SOUR' chan ':FUNC TRI']);  
                    
                case 'Ramp' 
                    obj.dev.write(['SOUR' chan ':FUNC RAMP']);                      
                    
                case 'DC'
                    obj.dev.write(['SOUR' chan ':FUNC DC']);  
            end
        end
        
        %Set load setting
        function load_set(obj,value,chan)
            switch(value) %Actually any value could be inputed!
                case '50 Ohm' 
                    obj.dev.write(['OUTP' chan ':LOAD 50']);   
                    
                case 'High impedance'
                    obj.dev.write(['OUTP' chan ':LOAD INF']);   
            end
        end
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = freq_check(obj,value) %Hz
            flag = 1;
            
            chan = num2str(obj.get_setting('channel').val); %use num to accept either val or string
            type = obj.get_setting(['wavetype' chan]).val;
            
            switch(type)
                case 'Sine'
                    maxFreq = 30e6;
                case 'Square' 
                    maxFreq = 30e6;
                case 'Triangle' 
                    maxFreq = 200e3;
                case 'Ramp' 
                    maxFreq = 200e3;
                case 'DC'
                    maxFreq = +inf;
                    
                otherwise
                    flag = 0;
                    return;
            end
            
            if(any(value < 1e-6 | value > maxFreq)) 
                flag = 0;
                obj.msgbox(['Frequency must be set between 1e-6 Hz and ' num2str(maxFreq,3) ' Hz (' type ').']);
            end
        end
        
        function flag = ampl_check(obj,value) %V
            chan = num2str(obj.get_setting('channel').val); %use num to accept either val or string
            [min_offset,max_offset] = obj.get_param(['amploff' chan]).get_sweep_min_max();
            
            flag = obj.amplitude_check([min_offset max_offset],max(value)/2); %ampl = Vpp/2
            
            if(any(value < 1e-3)) 
                flag = 0;
                obj.msgbox('Voltage amplitude must be set above 1 mV.');
            end
        end
        
        function flag = amploff_check(obj,value) %V
            chan = num2str(obj.get_setting('channel').val); %use num to accept either val or string
            [~,max_ampl] = obj.get_param(['ampl' chan]).get_sweep_min_max();
            
            flag = obj.amplitude_check([min(value) max(value)],max_ampl/2);
        end
        
        function flag = amplitude_check(obj,offset,ampl) %V
            flag = 1;
            
            chan = num2str(obj.get_setting('channel').val); %use num to accept either val or string
            type = obj.get_setting(['load' chan]).val;
            wavetype = obj.get_setting(['wavetype' chan]).val;
            
            if(strcmp(wavetype,'DC'))
                value = offset;
            else
                value = [offset(1)-ampl offset(2)+ampl];
            end
            
            switch(type)
                case '50 Ohm'
                    maxVolt = 5;
                case 'High impedance'
                    maxVolt = 10;
                otherwise
                    flag = 0;
                    return;
            end
            
            if(any(abs(value) > maxVolt)) 
                flag = 0;
                obj.msgbox(['|Voltage (amplitude+offset)| must be set below ' int2str(maxVolt) ' V (' type ').']);
            end
        end
        
        function flag = phas_check(obj,value) %Degree
            flag = 1;
            
            if(any(value < -360 | value > +360)) 
                flag = 0;
                obj.msgbox('Phase must be set between -360 and +360 degrees.');
            end
        end
    end
end


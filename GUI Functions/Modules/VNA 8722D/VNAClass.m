classdef VNAClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% VNAClass is a GARII Module %%%%%%%%
    %%%%% HP Vector Network Analyzer 8722D %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %CHECK IS NOT ALLOWED HERE (SEE VNA COMMAND MANUAL)
    
    %Internal parameters
    properties (Access = private)
        store_imag_data = []
    end  
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = VNAClass()
            %Module name
            obj.name = 'VNA 8722D';
            
            %Instrument properties
            obj.INST_brand = 'agilent';
            obj.INST ={{'HEWLETT PACKARD,8722D,0,7.74', 'visa', 'GPIB0::18::INSTR'}};
            
            %Define parameters
            obj.params{1} = ParameterClass(obj,'power1','Power (dBm)',{1 -20 0 1},...
                                           @obj.power_check,@obj.power_set); 
                                       
            obj.params{2} = ParameterClass(obj,'power2','Power (dBm)',{1 -20 0 1},...
                                           @obj.power_check,@obj.power_set); 
            
            obj.params{3} = ParameterClass(obj,'freq_center1','Center frequency (GHz)',{1,9.5,0.001,1},...
                                           @obj.freq_center_check,@obj.freq_center_set);
            
            obj.params{4} = ParameterClass(obj,'freq_center2','Center frequency (GHz)',{1,9.5,0.001,1},...
                                           @obj.freq_center_check,@obj.freq_center_set);
            
            %Define settings
            %Channel select
            obj.settings{1} = SettingClass(obj,'channel','Channel',1,[],@obj.channel_set,{'1' '2'});
            
            %Frequency settings
            obj.settings{2} = SettingClass(obj,'freq_span1','Span frequency (GHz)',1,...
                                                                      @obj.freq_span_check,@obj.freq_span_set);
            obj.settings{3} = SettingClass(obj,'freq_pts1','Number of points',1601,[],...
                                                                @obj.freq_pts_set,{'51' '201' '401' '801' '1601'});
                                                            
            obj.settings{4} = SettingClass(obj,'freq_span2','Span frequency (GHz)',1,...
                                                                      @obj.freq_span_check,@obj.freq_span_set);
            obj.settings{5} = SettingClass(obj,'freq_pts2','Number of points',1601,[],...
                                                                @obj.freq_pts_set,{'51' '201' '401' '801' '1601'});
                                                            
            %Measure mode settings
            obj.settings{6} = SettingClass(obj,'measure_mode1','Measure mode','S21',[],...
                                                                @obj.measure_mode_set,{'S11' 'S12' 'S21' 'S22'});
            obj.settings{7} = SettingClass(obj,'display_mode1','Display mode','Log Magnitude',[],...
                                                                @obj.display_mode_set,{'Log Magnitude' 'Lin Magnitude' ...
                                                                 'Phase' 'Real' 'Imaginary' 'SWR', 'Real&Imag - Smith'});
            obj.settings{8} = SettingClass(obj,'domain_mode1','Domain mode','Frequency',[],...
                                                                @obj.domain_mode_set,{'Frequency' 'Time'});
                                                            
            obj.settings{9} = SettingClass(obj,'measure_mode2','Measure mode','S11',[],...
                                                                @obj.measure_mode_set,{'S11' 'S12' 'S21' 'S22'});
            obj.settings{10} = SettingClass(obj,'display_mode2','Display mode','Log Magnitude',[],...
                                                                @obj.display_mode_set,{'Log Magnitude' 'Lin Magnitude' ...
                                                                 'Phase' 'Real' 'Imaginary' 'SWR'});
            obj.settings{11} = SettingClass(obj,'domain_mode2','Domain mode','Frequency',[],...
                                                                @obj.domain_mode_set,{'Frequency' 'Time'});
                                      
            %Trigger mode
            obj.settings{12} = SettingClass(obj,'trigger_mode','Trigger mode','WholeAverageGroup',[],...
                                                                [],{'Single' 'Continuous' 'Hold' 'WholeAverageGroup'});
            obj.settings{end+1} = SettingClass(obj,'averages_num','Int. Averages (1-999)',1,...
                                                                      @obj.averages_check,@obj.averages_set);
            obj.settings{end+1} = SettingClass(obj,'IF_bandwidth','IF bandwidth (Hz)',1000,[],...
                                                                @obj.IF_bandwidth_set,{'10' '30' '100' '300' '1000' '3000' '3700'});
                                                            
            %Calibration
            obj.settings{end+1} = SettingClass(obj,'calibrate_mode','Calibrate mode','Thru',[],[],{'Thru' 'Open' 'Short'});
                                                            
            %Define measurements
            obj.measures{1} = MeasureClass(obj,'measure1','Log Magnitude (dB)',@()obj.acquire_data('real_valued'),'Frequency (GHz)');    
            obj.measures{1}.state = 1;
            obj.measures{2} = MeasureClass(obj,'measure2','Imaginary (dB)',@()obj.acquire_data('imaginary_component'),'Frequency (GHz)');    
            obj.measures{2}.state = 0;
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
            obj.dev.close;
            obj.dev = [];
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            obj.measure_mode_set('S21');
            obj.domain_mode_set('Frequency');
            obj.display_mode_set('Log Magnitude');
%             obj.dev.write('PWRRPAUTO'); %Auto power range mode doesn't
%             work with calibration
            obj.power_set(-40);
            obj.auto_scale();
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            ok_flag = obj.tool_exp_setup('no_check');
            
            %Create transient axis
            meas1 = obj.get_measure('measure1');
            meas2 = obj.get_measure('measure2');
            for meas = [meas1, meas2]
            if(meas.state)
                if(obj.get_setting('channel').val == 1)
                    [centermin, centermax] = obj.get_param('freq_center1').get_sweep_min_max();
                    span = obj.get_setting('freq_span1').val;
                    pts = obj.get_setting('freq_pts1').val;
                else
                    [centermin, centermax] = obj.get_param('freq_center2').get_sweep_min_max();
                    span = obj.get_setting('freq_span2').val;
                    pts = obj.get_setting('freq_pts2').val;
                end
                
                axis = centermin + span/2*linspace(-1,1,pts).';
                meas.transient_axis.vals = axis;
            else
                meas.transient_axis.vals = [];
            end
            end
        end        
        
        %During experiment, sweep to next point
        %type = [0=XY,1=X,2=Y,3=PC], pos = [X Y PC] value
        function ok_flag = experiment_next(obj,type,pos)
            %Sweep to next point
            ok_flag = obj.tool_exp_next(type,pos,'no_check');
        end
        
        %Trigger
        function experiment_trigger(obj)
            trig_mode = obj.get_setting('trigger_mode').val;
            obj.trigger_mode_set(trig_mode);
        end 
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            if(~isempty(obj.dev))
                
                ok_flag = 1;
            else                
                ok_flag = 0;
            end
        end
        
        function experiment_setread(obj)
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
        %Calibration        
        function calibrate(obj,~,~)
            if(~isempty(obj.dev))
                %Send params/settings first
                obj.send_all_settings('no_check');
                obj.send_all_params('no_check');
                
                %Start calibration
                obj.dev.write('CALIRESP'); 
                
                %Calibration mode (UNSURE!!!)
                switch(obj.get_setting('calibrate_mode').val)
                    case 'Thru'
                        obj.dev.write('STANC'); 
                        
                    case 'Open'
                        obj.dev.write('STANB'); 
                        
                    case 'Short'
                        obj.dev.write('STANA');
                end
                
                %End calibration
                obj.dev.write('RESPDONE'); 
            end
        end
    end
    
    %GUI functions
    methods (Access = public)
        function select_channel(obj,~,~)
            chan_sel = obj.get_setting('channel').val;
            
            if(chan_sel == 1)
                ch1_flag = 1;
                ch2_flag = 0;
            elseif(chan_sel == 2)
                ch1_flag = 0;
                ch2_flag = 1;
            end
            
            %CH1
            obj.get_setting('measure_mode1').set_state_and_UIvisibility(ch1_flag);
            obj.get_setting('display_mode1').set_state_and_UIvisibility(ch1_flag);
            obj.get_setting('domain_mode1').set_state_and_UIvisibility(ch1_flag);

            obj.get_param('freq_center1').set_state_and_UIvisibility(ch1_flag);
            obj.get_setting('freq_span1').set_state_and_UIvisibility(ch1_flag);
            obj.get_setting('freq_pts1').set_state_and_UIvisibility(ch1_flag);

            obj.get_param('power1').set_state_and_UIvisibility(ch1_flag);

            %CH2
             obj.get_setting('measure_mode2').set_state_and_UIvisibility(ch2_flag);
            obj.get_setting('display_mode2').set_state_and_UIvisibility(ch2_flag);
            obj.get_setting('domain_mode2').set_state_and_UIvisibility(ch2_flag);

            obj.get_param('freq_center2').set_state_and_UIvisibility(ch2_flag);
            obj.get_setting('freq_span2').set_state_and_UIvisibility(ch2_flag);
            obj.get_setting('freq_pts2').set_state_and_UIvisibility(ch2_flag);

            obj.get_param('power2').set_state_and_UIvisibility(ch2_flag);
        end
    end
    
    %Acquire/Query functions
    methods (Access = public)
        function [freq] = acquire_start_freq(obj)
            datachar = obj.dev.ask('STAR?');
            freq = str2double(datachar)/(10^9);% GHz
        end
        
        function [freq] = acquire_stop_freq(obj)
            datachar = obj.dev.ask('STOP?');
            freq = str2double(datachar)/(10^9);% GHz
        end

        function [freq] = acquire_centre(obj)
            freq = str2double(obj.dev.ask('CENT?'))/1e9;
        end
        
        function [freq] = acquire_span(obj)
            freq = str2double(obj.dev.ask('SPAN?'))/1e6;
        end
        
        function [data_x] = acquire_freq_axis(obj)
            freq_start = obj.acquire_start_freq();
            freq_stop = obj.acquire_stop_freq();
            num_point = obj.acquire_num_point();    
            data_x = linspace(freq_start,freq_stop,num_point)';
        end
       
        function [height,freq] = acquire_marker_position(obj)
            obj.dev.write('FORM4');
            datachar = obj.dev.ask('OUTPMARK');
            height = str2double(datachar(1:16));% dB
            freq = str2double(datachar(32:48))/(10^9);% GHz
        end
        
        function [point] = acquire_num_point(obj)
            datachar = obj.dev.ask('POIN?');
            point = str2double(datachar);
        end
        
        function [power] = acquire_power(obj) %in dBm
            datachar = obj.dev.ask('POWE?');
            power = str2double(datachar);
        end
        
        function search_max(obj)
            obj.dev.write('MARKMAXI');
        end

        function search_min(obj)
            obj.dev.write('MARKMINI');
        end
    end
    
    %Internal functions
    methods (Access = private)
        function channel_set(obj,channel)
            switch channel
                case 1
                    obj.dev.write('CHAN1');
                case 2
                    obj.dev.write('CHAN2');
                otherwise
                    disp('No command sent to VNA')
            end
        end
        
        function power_set(obj,power) %dBm
            obj.dev.write(sprintf('POWE %u',power));
        end
        
        function freq_center_set(obj,freq)
            obj.dev.write(sprintf('CENT %eGHz',freq));
        end %GHz
        
        function freq_span_set(obj,span)
            obj.dev.write(sprintf('SPAN %eGHz',span));
        end %GHz
        
        %Unused
        function freq_start_set(obj,freq)
            obj.dev.write(sprintf('STAR %eGHz',freq));
        end
        
        %Unused
        function freq_stop_set(obj,freq)
            obj.dev.write(sprintf('STOP %eGHz',freq));
        end
        
        %Number of points
        function freq_pts_set(obj,point)
            obj.dev.write(sprintf('POIN %u',point));
        end
        
        %Number of averages
        function averages_set(obj,num_averages)
            obj.dev.write('AVEROON')
            obj.dev.write(sprintf('AVERFACT %u',num_averages));
        end
        
        
        % IF bandwidth
        function IF_bandwidth_set(obj,bandwidth)
            obj.dev.write(sprintf('IFBW %u',bandwidth));
        end
        
        %Measure/Acquire data
        function data = acquire_data(obj,type)
            if ~strcmpi(type, 'imaginary_component');
                %obj.dev.ask('OPC?');
                obj.dev.write('FORM4');
                data = obj.dev.ask('OUTPFORM');
                data = str2num(data); %#ok<ST2NM>
                obj.store_imag_data = data(:,2);
                data = data(:,1);
            else
                data = obj.store_imag_data;
            end
        end
        
        function measure_mode_set(obj,s_parameter)
            switch s_parameter
                case 'S11'
                    obj.dev.write('S11');
                case 'S21'
                    obj.dev.write('S21');
                case 'S12'
                    obj.dev.write('S12');
                case 'S22'
                    obj.dev.write('S22');
                otherwise
                    disp('No command sent to VNA');
            end
        end
        
        function domain_mode_set(obj,type)
            switch(type)
                case 'Frequency'
                    obj.dev.write('LINFREQ');
                    obj.dev.write('TIMDTRANOFF'); 
                    
                case ' Time'
                    obj.dev.write('MARKCW');
                    obj.dev.write('CWTIME');
                    obj.dev.write('TIMDTRANON');
                    
                otherwise
                    disp('No command sent to VNA');
            end
        end
        
        function display_mode_set(obj,format)
            switch format
                case 'Log Magnitude'
                    obj.dev.write('LOGM');
                    obj.get_measure('measure1').label = 'Log Magnitude (dB)';
                    obj.get_measure('measure2').state = 0;
                    
                case 'Phase'
                    obj.dev.write('PHAS');
                    obj.get_measure('measure1').label = 'Phase (degree)';
                    obj.get_measure('measure2').state = 0;
                    
                case 3
                    obj.dev.write('DELA');
                    
                case 4
                    obj.dev.write('SMIC');
                    
                case 5
                    obj.dev.write('POLA');
                    
                case 'Lin Magnitude'
                    obj.dev.write('LINM');
                    obj.get_measure('measure1').label = 'Lin Magnitude (a.u.)';
                    obj.get_measure('measure2').state = 0;
                    
                case 'SWR'
                    obj.dev.write('SWR');
                    obj.get_measure('measure1').label = 'SWR (a.u.)';
                    obj.get_measure('measure2').state = 0;
                    
                case 'Real'
                    obj.dev.write('REAL');
                    obj.get_measure('measure1').label = 'Real (a.u.)';
                    obj.get_measure('measure2').state = 0;
                    
                case 'Imaginary'
                    obj.dev.write('IMAG');
                    obj.get_measure('measure1').label = 'Imaginary (a.u.)';
                    obj.get_measure('measure2').state = 0;
                    
                case 'Real&Imag - Smith'
                    obj.dev.write('SMIC');
                    obj.get_measure('measure1').label = 'Real (lin)';
                    obj.get_measure('measure2').state = 1;
                    obj.get_measure('measure2').label = 'Imag (lin)';
                    
                otherwise
                    disp('Display_mode_set: No command sent to VNA');
            end
        end
        
        function trigger_mode_set(obj,type)
            switch(type)
                case 'Single'
                    obj.dev.write('SING');
                    
                case 'Continuous'
                    obj.dev.write('CONT');
                    
                case 'Hold'
                    obj.dev.write('HOLD');
                    
                case 'WholeAverageGroup'
                    num_averages = obj.get_setting('averages_num').val();
                    obj.dev.write(sprintf('NUMG %u', num_averages));
            end
        end
        
        %Plot
        function auto_scale(obj)
            obj.dev.write('AUTO');
        end 
    end
    
    %Parameter check
    methods (Access = private)
        function flag = power_check(obj,value) %dBm
            flag = 1;
            
            if(any(value < -75 | value > -5)) 
                flag = 0;
                obj.msgbox('Power must be set between -75 and -5 dBm');
            end
        end
        
        function flag = freq_center_check(obj,value) %GHz
            if(obj.get_setting('channel').val == 1)
                span = obj.get_setting('freq_span1').val;
            else
                span = obj.get_setting('freq_span2').val;
            end
            freq = [value - span/2, value + span/2];
            flag = obj.freq_check(freq);
        end
        
        function flag = freq_span_check(obj,value) %GHz
            if(obj.get_setting('channel').val == 1)
                center = obj.get_param('freq_center1').vals;
            else
                center = obj.get_param('freq_center2').vals;
            end
            freq = [center - value/2, center + value/2];
            flag = obj.freq_check(freq);
        end
        
        function flag = freq_check(obj,value)
            flag = 1;
            
            if(any(value < 50e-3 | value > 40)) 
                flag = 0;
                obj.msgbox('Frequency must be set between 50 MHz and 40 GHz');
            end
        end
        function flag = averages_check(obj,value)
            flag = 1;
            
            if(any(value < 1 | value > 999)) 
                flag = 0;
                obj.msgbox('Averaging between 1 and 999');
            end
        end
    end
end


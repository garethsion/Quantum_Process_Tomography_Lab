classdef VSGClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% VSGClass is a GARII Module %%%%%%%%%%%%
    %%%%% Vector Signal generator Agilent PSG E8267D %%%%%% 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = VSGClass()
            %Module name
            obj.name = 'VSG E8267D';
            
            %Instrument properties
            obj.INST_brand = 'ni'; %used to be 'agilent'!
            obj.INST = {{'Agilent Technologies, E8267D, MY50420183, C.06.21', 'visa', 'GPIB0::19::INSTR'} ...
                        {'Agilent Technologies, E8267D, US50350080, C.06.10', 'visa', 'GPIB0::15::INSTR'}};
            
            %Define parameters
            obj.params{1} = ParameterClass(obj,'freq','Frequency (GHz)',{1 9.7 0 1},...
                                           @obj.freq_check,@obj.freq_set);
            obj.params{2} = ParameterClass(obj,'power','Power (dBm)',{1 -20 0 1},...
                                           @obj.power_check,@obj.power_set);
                                       
            %Define settings
            obj.settings{1} = SettingClass(obj,'iqmixing','IQ mixing?',1,@obj.iqmixing_check,@obj.iqmixing_set);
            
            %Fast sweeping
            obj.settings{2} = SettingClass(obj,'fastsweep','Transient sweep (Ext. trig.)?',0,...
                                            @obj.fastsweep_check,@obj.fastsweep_set);
            obj.settings{3} = SettingClass(obj,'fastsweep_center','Center frequency (GHz)',9.7,...
                                            @obj.fastsweep_center_check,[]);
            obj.settings{4} = SettingClass(obj,'fastsweep_width','Sweep width (GHz)',0.1,...
                                            @obj.fastsweep_width_check,[]);
            obj.settings{5} = SettingClass(obj,'fastsweep_update','Update',[],[],[]);
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
            obj.set_status(0);
            obj.get_param('freq').send(9.7);
            obj.get_param('power').send(-20);
            obj.get_setting('iqmixing').send();
            obj.dev.write(':POWER:ALC 0');
            
            obj.dev.write(':INIT:CONT 1'); %Continuous sweep (for averaging)
            
            obj.dev.write(':LIST:DWEL:TYPE STEP');
            obj.dev.write(':LIST:RETRACE 1');
            
            obj.dev.check('VSG reset function');
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            ok_flag = obj.tool_exp_setup();
            if(obj.get_setting('fastsweep').val)
                obj.dev.write(':FREQ:MODE LIST'); %Sweep mode
            else
                obj.dev.write(':FREQ:MODE CW'); %CW mode
            end
            
            if(ok_flag)
                %Turn on device
                obj.set_status(1);
            end
        end
        
        %During experiment, sweep to next point
        %pos = [X Y PC] index value, type = which pos is changed
        function ok_flag = experiment_next(obj,type,pos)
            ok_flag = 1;
            
            %Sweep to next point
            if(~obj.get_setting('fastsweep').val)
                ok_flag = obj.tool_exp_next(type,pos);
            end
        end
        
        %Trigger
        function experiment_trigger(obj)
            if(obj.get_setting('fastsweep').val)
                obj.dev.write('*TRG');
            end
        end 
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            if(~isempty(obj.dev))
                obj.set_status(0);
                if(obj.get_setting('fastsweep').val)
                    obj.dev.write(':FREQ:MODE CW'); %Somehow if in LIST mode it crashes when a check appears later
                end
                
                ok_flag = 1;
            else
                ok_flag = 0;
            end
        end
    end
    
    %GUI methods
    methods (Access = public)
        function fastsweep_select(obj,~,~)
            sweep_status = obj.get_setting('fastsweep').val;
            obj.get_setting('fastsweep_center').set_state_and_UIvisibility(sweep_status);
            obj.get_setting('fastsweep_width').set_state_and_UIvisibility(sweep_status);
            obj.get_setting('fastsweep_update').set_state_and_UIvisibility(sweep_status);
            
            obj.get_param('freq').set_state_and_UIvisibility(~sweep_status);
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
        function freq = acquire_frequency(obj) %GHz
            datachar = obj.dev.ask(':FREQ?');
            freq = str2double(datachar)*1e-9; 
        end
         
        function power = acquire_power(obj) %dBm
            datachar = obj.dev.ask(':POW:AMPL?'); 
            power = str2double(datachar);
        end
        
        function status = acquire_RFstatus(obj) %status = 0/1 > RF off/on
            datachar = obj.dev.ask(':OUTP:STAT?'); 
            status = str2double(datachar);
        end
        
        function set_status(obj,status) %status = 0/1 > turn RF off/on
            if(status == 0)
                obj.dev.write(':OUTP:STAT OFF');
            elseif(status == 1)
                obj.dev.write(':OUTP:STAT ON');
            else
                error('Input required: 0 for RF off, 1 for RF on');
            end
        end
        
        function mode = acquire_freq_mode(obj)
            mode = obj.dev.ask(':FREQ:MODE?');
        end
        
        %Update internal sweep
        function fastsweep_update(obj,~,~)
            %Calculate new sweep settings
            center_val = obj.get_setting('fastsweep_center').val;
            width_val = obj.get_setting('fastsweep_width').val;
            start_val = center_val - width_val/2;
            end_val = center_val + width_val/2;
            
            %Frequency sweep definition
            if(~isempty(obj.dev))
                obj.dev.write(sprintf(':FREQ:STAR %u Hz',start_val*1e9));
                obj.dev.write(sprintf(':FREQ:STOP %u Hz',end_val*1e9));
            end
%             obj.dev.write(':FREQ:MODE LIST');
        end
    end
    
    %Internal functions
    methods (Access = private)
        function freq_set(obj,value) %GHz
            obj.dev.write(sprintf(':FREQ %u Hz',value*1e9));
        end        
        function power_set(obj,value) %dBm
            obj.dev.write(sprintf(':POW %u dBm',value));
        end   
        
        %Set On or Off IQ mixing
        function iqmixing_set(obj,value)
            if(value)
                obj.dev.write(':OUTPUT:MODULATION 1');
                obj.dev.write(':DM:STATE 1');
            else
                obj.dev.write(':OUTPUT:MODULATION 0');
                obj.dev.write(':DM:STATE 0');
            end
            obj.dev.write(':DM:IQAD 0');
            
            obj.dev.check('VSG IQ mixing setting');
        end
        
        %Set an internal sweep
        function fastsweep_set(obj,value)
            if(value == 1) %Transient sweep
                %Sweep trigger source: external
                obj.dev.write('TRIG:SOUR EXT');
                
                %Point sweep trigger: immediate
                obj.dev.write('LIST:TRIG:SOUR IMM');
                
                %Calculate dwell time and point number
                minDwellTime = 0.001;
                sweepPts = 100;
                dwelltime = minDwellTime;

                obj.dev.write([':SWE:DWEL ' num2str(dwelltime)]); %Dwell time
                obj.dev.write(sprintf(':SWE:POIN %u',sweepPts));

                %Frequency sweep definition
                obj.fastsweep_update([],[]);

                %Sweep parameters
                obj.dev.write(':LIST:TYPE STEP'); %Linear sweep
                obj.dev.write(':LIST:DIR UP'); %Sweep up
            else %No transient sweep
                %Sweep trigger source: computer
                obj.dev.write('TRIG:SOUR BUS');
                
                %Point trigger source: computer
                obj.dev.write('LIST:TRIG:SOUR BUS');
            end
        end        
    end
    
    %Parameter check
    methods (Access = private)
        function flag = freq_check(obj,value) %GHz
            flag = 1;
            
            if(any(value < 250e-6 | value > 20)) 
                flag = 0;
                obj.msgbox('Frequency must be set between 250 kHz and 20 GHz');
            end
        end      
        function flag = power_check(obj,value) %dBm
            flag = 1;
            
            if(any(value < -130 | value > 25)) 
                flag = 0;
                obj.msgbox('Power must be set between -130 and 25 dBm');
            end
        end
        
        function flag = iqmixing_check(~,value)
            flag = 1;
            if(~value)
                result = questdlg('IQ mixing is off. Are you in tuning mode?', ...
                                  'Spectrometer warning','Yes', 'No','No');
                if(strcmp(result,'No'))
                    flag = 0;
                end
            end
        end
        
        %Fast sweep check
        function flag = fastsweep_check(obj,value)
            flag = 1;
            if(value && obj.MAIN.SRT < 0.01)
                flag = 0;
                obj.msgbox('Transient sweep requires SRT to be > 0.01 s.');
            end
        end
        
        function flag = fastsweep_width_check(obj,value)
            flag = 1;
            
            if(value < 0 || value > 1) %Above some value ? sweep not fast enough if width too large
                flag = 0;
                obj.msgbox('Sweep width must be set between 0 and 1 GHz.');
            end
            
            center = obj.get_setting('fastsweep_center').val;
            
            flag = flag && obj.freq_check([center-value/2 center+value/2]);
        end
        
        function flag = fastsweep_center_check(obj,value)
            flag = 1;
            
            width = obj.get_setting('fastsweep_width').val;
            
            flag = flag && obj.freq_check([value-width/2 value+width/2]);
        end
    end
end



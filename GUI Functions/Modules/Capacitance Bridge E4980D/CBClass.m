classdef CBClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% MSOClass is a GARII Module %%%%%%%%%%%%%%%%%
    %%%%%%%% Mixed Signal Oscilloscope Agilent MSO-X 3104A %%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)   
        lastData = [0, 0]
        MeasTypes = {'CPD', 'CPQ', 'CPG', 'CPRP', 'CSD', 'CSQ', 'CSRS', ...
            'LPD', 'LPQ', 'LPG', 'LPRP', 'LSD', 'LSQ', 'LSRS', 'RX', 'ZTD', ...
            'ZTR', 'GB', 'YTD', 'YTR', 'VDID '}
        MeasDescriptors = {'Cp (F)-D','Cp (F)-Q','Cp-G','Cp (F)-Rp (Ohm)','Cs (F)-D',...
            'Cs (F)-Q','Cs (F)-Rs (Ohm)','Lp (H)-D','Lp (H)-Q','Lp-G','Lp-Rp (Ohm)','Ls (H)-D','Ls (H)-Q',...
            'Ls (H)-Rs (Ohm)','R (Ohm)-X (Ohm)','Z (Ohm)-Theta (deg)','Z (Ohm)-Theta (rad)','G-B','Y-Theta (deg)','Y-Theta (rad)','Vdc (V)-Idc (A)'}
    end
    
    %GUI parameters
    properties (Access = public)
    end
    
    %Main methods
    methods (Access = public)
        %Define all the main properties of instrument
        function obj = CBClass()
            %Module name
            obj.name = 'Agilent E4980A';
            
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST = {{'Agilent Technologies,E4980A,MY46310120,A.03.00', 'visa', 'GPIB0::17::INSTR'}};
                           
            % Parameters 
            obj.params{1} = ParameterClass(obj,'VOLT','Voltage level (V)',{1 1 0 1},...
                @(val)obj.check_parameter('VOLT',[0 20],val), @(val)obj.set_parameter('VOLT',val)); 
            obj.params{end+1} = ParameterClass(obj,'FREQ','Frequency (kHz)',{1 1 0 1},...
                @(val)obj.check_parameter('FREQ',[0.02 2000],val), @(val)obj.set_parameter('FREQ',val*1e3)); 
            obj.params{end+1} = ParameterClass(obj,'BIAS:VOLT','DC bias (V)',{1 0 0 1},...
                @(val)obj.check_parameter('BIAS:VOLT',[-40 40],val), @(val)obj.set_parameter('BIAS:VOLT',val)); 
            
            % Settings
            obj.settings{1} = SettingClass(obj,'BIAS:STATE','DC bias?',0,[], @(val)obj.set_parameter('BIAS:STATE',val));
            obj.settings{end+1} = SettingClass(obj,'MeasTime','Measurement time','Medium',[], @obj.set_averaging,{'Short', 'Medium', 'Long'});
            obj.settings{end+1} = SettingClass(obj,'Averaging','No. of averages',1,@(val)obj.check_parameter('Averaging',[1 256],val), @obj.set_averaging);
            obj.settings{end+1} = SettingClass(obj,'TriggerType','Trigger source','Bus',[], @(val)obj.set_parameter(':ABORT;TRIG:SOUR',val),{'Int', 'Ext', 'Hold', 'Bus'});
            obj.settings{end+1} = SettingClass(obj,'MeasType','Measure type','CPD',[],...
                @(val)obj.set_MeasType(val),obj.MeasTypes);
                                       
            % Measurements                             
            
            obj.measures{1} = MeasureClass(obj,'ch1','Channel 1 (V)',@() obj.read_channel(1));
            obj.measures{1}.state = 1;
            obj.measures{2} = MeasureClass(obj,'ch2','Channel 2 (V)',@() obj.read_channel(2));
            obj.measures{2}.state = 1;
            end
        
        %Connect
        function connect(obj)
            obj.create_device();
            if(~isempty(obj.dev))
                %obj.reset();
            end
        end
        
        %Disconnect
        function disconnect(obj)
            obj.dev.close();
            obj.dev = [];
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            obj.dev.ask('*RST');
        end
        
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            % ok_flag = obj.tool_exp_setup();
            ok_flag = obj.tool_exp_setup('no_check');
        end
        %During experiment, sweep to next point
        %type = [0=XY,1=X,2=Y,3=PC], pos = [X Y PC] value
        function ok_flag = experiment_next(obj,type,pos)
            ok_flag = obj.tool_exp_next(type,pos,'no_check');
        end
        
        %Trigger
        function data = experiment_trigger(obj)
            if strcmpi(obj.get_setting('TriggerType').val, 'Bus')
                obj.dev.write(':TRIG;');
            end
            returnStr= obj.dev.ask(':FETCh?');
            splitStr = strsplit(returnStr,','); 
            data = cellfun(@str2double, splitStr(1:2));
            obj.lastData = data;
        end 
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            if(~isempty(obj.dev))                
                ok_flag = 1;
            else
                ok_flag = 0;
            end
        end
        
        %Measurement instrument to be ready, every shot
        function experiment_setread(obj)
        end
    end
    
    %Internal functions
    methods (Access = private)
        function set_parameter(obj,param,value)
            obj.dev.write([param ' ' num2str(value)]);
        end 
        
        function val = read_parameter(obj,param)
            val = obj.dev.ask([param '?']);
            val = str2double(val);
        end 
        
        function set_averaging(obj, val)
            measTime = obj.get_setting('MeasTime').val;
            avg = obj.get_setting('Averaging').val;
            obj.dev.write(['APER ' measTime ', ' num2str(avg)])
        end
        
        function set_MeasType(obj, val)
            obj.set_parameter(':FUNC:IMP',val)
            
            indC = strfind(obj.MeasTypes, val);
            ind = find(not(cellfun('isempty',indC)));
            MeasDesc = strsplit(obj.MeasDescriptors{ind},'-');
            obj.measures{1}.label = MeasDesc{1};
            obj.measures{2}.label = MeasDesc{2};
        end
        
        function data = read_channel(obj,channel)
            data = obj.lastData(channel);
        end
    end
    
    
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = check_parameter(obj,param,MinMax,value) % modulation amplitude
            flag = 1;
            
            if(any(value < MinMax(1) | value > MinMax(2))) 
                flag = 0;
                obj.msgbox(sprintf(' Parameter %s out of range [%.2f %.2f].', ...
                    param, min(MinMax), max(MinMax)));
            end
        end        
        
    end
end
        


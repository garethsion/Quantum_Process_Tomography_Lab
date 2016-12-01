classdef DG645Class < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% DG645Class is a GARII Module %%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = public)
        TriggerSelection ={'Internal', 'Ext. rising','Ext. falling','Single rising','Single falling','Single','Line'  };
            
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = DG645Class()
            %Module name
            obj.name = 'Pulse Delay Generator DG645, Stanford Research ';
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST = {{'Stanford Research Systems,DG645,s/n003458,ver1.16.116', 'visa', 'GPIB0::15::INSTR'}};
            
            % Acquistion settings
            obj.params{1} = ParameterClass(obj,'startA','Start A (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 2,0,',val*1e-3)); 
            obj.params{end+1} = ParameterClass(obj,'delayB','Duration B (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 3,2,',val*1e-3)); 
            obj.params{end+1} = ParameterClass(obj,'startC','Start C (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 4,0,',val*1e-3)); 
            obj.params{end+1} = ParameterClass(obj,'delayD','Duration D (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 5,4,',val*1e-3)); 
            obj.params{end+1} = ParameterClass(obj,'startE','Start E (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 6,0,',val*1e-3)); 
            obj.params{end+1} = ParameterClass(obj,'delayF','Duration F (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 7,6,',val*1e-3)); 
            obj.params{end+1} = ParameterClass(obj,'startG','Start G (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 8,0,',val*1e-3)); 
            obj.params{end+1} = ParameterClass(obj,'delayH','Duration H (ms)',{1 0 0 1}, @(val)obj.check_parameter('Delay',[0 1e6],val), @(val)obj.set_parameter('DLAY 9,8,',val*1e-3)); 
            %Define settings
            %SettingClass(obj = current module handle, setting ID, setting
            %label, Initial value, handle to setting value check function, handle
            %to function for sending setting to instrument, (optional for
            %list type setting) list of choices)
            obj.settings{end+1} = SettingClass(obj,'ampAB','Voltage B (V)',0, @(val)obj.check_parameter('LAMP 1',[0 5], val), @(val)obj.set_parameter('LAMP 1,',val));
            obj.settings{end+1} = SettingClass(obj,'offsetAB','Offset A (V)',0, @(val)obj.check_parameter('LAMP 1',[0 5], val), @(val)obj.set_parameter('LOFF 1,',val));
            obj.settings{end+1} = SettingClass(obj,'polarityAB','Polarity AB','Pos', [], @(val)obj.set_polarity(1,val),{'Pos','Neg'});
            %CD
            obj.settings{end+1} = SettingClass(obj,'ampCD','Voltage D (V)',0, @(val)obj.check_parameter('LAMP 2',[0 5], val), @(val)obj.set_parameter('LAMP 2,',val));
            obj.settings{end+1} = SettingClass(obj,'offsetCD','Offset C (V)',0, @(val)obj.check_parameter('LAMP 2',[0 5], val), @(val)obj.set_parameter('LOFF 2,',val));
            obj.settings{end+1} = SettingClass(obj,'polarityCD','Polarity CD','Pos', [], @(val)obj.set_polarity(2,val),{'Pos','Neg'});
            %EF
            obj.settings{end+1} = SettingClass(obj,'ampEF','Voltage F (V)',0, @(val)obj.check_parameter('LAMP 3',[0 5], val), @(val)obj.set_parameter('LAMP 3,',val));
            obj.settings{end+1} = SettingClass(obj,'offsetEF','Offset E (V)',0, @(val)obj.check_parameter('LAMP 3',[0 5], val), @(val)obj.set_parameter('LOFF 3,',val));
            obj.settings{end+1} = SettingClass(obj,'polarityEF','Polarity EF','Pos', [], @(val)obj.set_polarity(3,val),{'Pos','Neg'});
            %GH
            obj.settings{end+1} = SettingClass(obj,'ampGH','Voltage G (V)',0, @(val)obj.check_parameter('LAMP 4',[0 5], val), @(val)obj.set_parameter('LAMP 4,',val));
            obj.settings{end+1} = SettingClass(obj,'offsetGH','Offset H (V)',0, @(val)obj.check_parameter('LAMP 4',[0 5], val), @(val)obj.set_parameter('LOFF 4,',val));
            obj.settings{end+1} = SettingClass(obj,'polarityGH','Polarity GH','Pos', [], @(val)obj.set_polarity(4,val),{'Pos','Neg'});
            
            obj.settings{end+1} = SettingClass(obj,'trigger','Trigger','Internal', [], @(val)obj.set_trigger(val),obj.TriggerSelection);
            
         end
        
        %Connect
        function connect(obj)
            obj.create_device();
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
            ok_flag = obj.tool_exp_setup();
        end
        
        %During experiment, sweep to next point
        function ok_flag = experiment_next(obj,type,pos)
            %Sweep to next point
            ok_flag = obj.tool_exp_next(type,pos);
        end
        
        %Trigger
        function experiment_trigger(obj)
            %ToDo
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
        
        
        function load_DG645_manual_settings_ui(obj,pushbutton,~)
            obj.load_DG645_manual_settings(1)
        end
        
        function load_DG645_manual_settings(obj,val)
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
                        display(sprintf('(load_DG645_manual_settings) Load setting %s from DG645: Wrong parameter name', par.name))
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
        
        function set_polarity(obj, channel, val)
            if val == 'Pos'
                obj.dev.write(sprintf('LPOL %i,1', channel));
            elseif val == 'Neg'
                obj.dev.write(sprintf('LPOL %i,0', channel));
            end
        end
        function set_trigger(obj, val)
            trig_idx = strmatch(val,obj.TriggerSelection)-1;
            obj.dev.write(sprintf('TSRC %i', trig_idx));
            
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
        
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        % ========== FOR DG645 ========== %
        function flag = check_parameter(obj,param,MinMax,value) % modulation amplitude
            flag = 1;
            
            if(any(value < MinMax(1) | value > MinMax(2))) 
                flag = 0;
                obj.msgbox(['(' param ') out of range.']);
            end
        end        
        
    end
end


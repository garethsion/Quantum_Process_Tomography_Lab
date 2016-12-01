classdef WS7Class < ModuleClass
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
        function obj = WS7Class()
            %Module name
            obj.name = 'Wavelength Meter WS7';
            
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST = {{' ' '' ''}};
            
            %Define measures
            obj.measures{1} = MeasureClass(obj,'wavelength','Wavelength (nm)',@()obj.get_wavelength());
            obj.measures{2} = MeasureClass(obj,'power','Power (a.u.)',@()obj.get_power());
            
            %Define settings
            obj.settings{1} = SettingClass(obj,'measure_wavelength','Measure wavelength',1,...
                [], @obj.set_measure_wavelength);
            obj.settings{2} = SettingClass(obj,'measure_power','Measure power',0,...
                [], @obj.set_measure_power);
        end
        
        %Connect
        function connect(obj)
            loadlibrary('wlmData.dll', 'C:\Program Files\HighFinesse\Wavelength Meter WS7 1256\Projects\DataDemo\C\wlmData.h', 'alias', 'wlmLib'); % Wavemeter
            if calllib('wlmLib', 'Instantiate', 0, 0, 0, 0) == 0;
                obj.dev = [];
            else
                obj.dev = 1;
            end
        end
        
        %Disconnect
        function disconnect(obj)
            unloadlibrary('wlmLib');
        end
        
        %Reset to some defaut parameter
        function reset(obj)
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            ok_flag = obj.tool_exp_setup('no_check');
        end
        
        function experiment_setread(obj)
        end
        
        function ok_flag = experiment_next(obj,type,pos)
            %Sweep to next point
            ok_flag = obj.tool_exp_next(type,pos,'no_check');
        end
        
        %Trigger
        function experiment_trigger(obj)
        end 
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            ok_flag = 1;
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
        function wavelength = get_wavelength(obj)
            wavelength = calllib('wlmLib','GetWavelength',1);
        end
        
        function power = get_power(obj)
            power = calllib('wlmLib','GetPowerNum',1,0);
        end
        
        function set_measure_wavelength(obj,val)
            meas=obj.get_measure('wavelength');
            if any(val == 1) || strcmpi(val,'on')
                    meas.state=1;
                    obj.get_setting('measure_wavelength').val=1;
            elseif any(val == 0) || strcmpi(val,'off') 
                    meas.state=0;
                    obj.get_setting('measure_wavelength').val=0;
            end
        end
        
        function set_measure_power(obj,val)
            meas=obj.get_measure('power');
            if any(val == 1) || strcmpi(val,'on')
                    meas.state=1;
                    obj.get_setting('measure_power').val=1;
            elseif any(val == 0) || strcmpi(val,'off') 
                    meas.state=0;
                    obj.get_setting('measure_power').val=0;
            end
        end
    end
    
    %Internal functions
    methods (Access = private)
    end
end


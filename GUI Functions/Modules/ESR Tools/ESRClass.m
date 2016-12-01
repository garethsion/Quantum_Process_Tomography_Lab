classdef ESRClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% VNAClass is a GARII Module %%%%%%%%
    %%%%% HP Vector Network Analyzer 8722D %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %CHECK IS NOT ALLOWED HERE (SEE VNA COMMAND MANUAL)
    
    %Internal parameters
    properties (Access = private)
        
    end  
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = ESRClass()
            %Module name
            obj.name = 'ESR Tools';
            
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST ={};
            
            
            %Define settings
            %Channel select
            obj.settings{1} = SettingClass(obj,'meas_q_rough','Meas Q (rough)',0,[],@obj.set_meas_q_rough);
            
            %Define measurements
            obj.measures{1} = MeasureClass(obj,'q_rough','Calc (rough mode)',@()obj.calc_q_rough,'Q (roughly)');    
            obj.measures{1}.state = 1;
        end
        
        % Connect
        function connect(obj)
            obj.dev=1;
        end
        
        %Disconnect
        function disconnect(obj)
            obj.dev = [];
        end
        
        % Reset to some defaut parameter
        function reset(obj)
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            ok_flag = 1;
        end        
        
        %During experiment, sweep to next point
        %type = [0=XY,1=X,2=Y,3=PC], pos = [X Y PC] value
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
        
        function experiment_setread(obj)
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
        % Calc Q rough        
        function q_rough = calc_q_rough(obj)
            hP = MAIN.hPLOT(1);
            ydata = get(hP,'YData');
            q_rough = 500;
        end
        
        function set_meas_q_rough(obj, val)
            meas_q_rough = obj.get_measure('q_rough');
            meas_q_rough.state = val;
        end
    end
    
    %GUI functions
    methods (Access = public)
    end
    
    %Internal functions
    methods (Access = private)
    end
    
    %Parameter check
    methods (Access = private)
    end
end


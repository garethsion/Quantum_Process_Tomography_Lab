classdef ITCClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%% ITCClass is a GIC Module %%%%%%%%%%%%%
    %%%% Integrated Temperature Controller %%%%% 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = ITCClass()
            %Module name
            obj.name = 'ITC ??';
            
            %Instrument properties
            obj.INST_brand = 'agilent';
            obj.INST = {{'Agilent Technologies, E8267D, US50350080, C.06.10', 'visa', 'GPIB0::15::INSTR'}};
            
            %Define parameters
            obj.params{1} = ParameterClass(obj,'temp','Temperature (K)',{1 0 0 1},...
                                           @obj.temp_check,@obj.temp_set);
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
            obj.temp_set(0);
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
                
                ok_flag = 1;
            else
                ok_flag = 0;
            end
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
    end
    
    %Internal functions
    methods (Access = private)
        function temp_set(obj,value) %K
            if(obj.temp_check(value)) 
%                 obj.dev.write(sprintf(':FREQ %u Hz',value*1e9));
            end
        end      
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = temp_check(obj,value) %GHz
            flag = 1;
            
            if(any(value < 250e-6 | value > 20)) 
                flag = 0;
                obj.msgbox('Frequency must be set between 250 kHz and 20 GHz');
            end
        end
    end
end


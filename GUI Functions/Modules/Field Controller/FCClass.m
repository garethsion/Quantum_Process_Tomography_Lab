classdef FCClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%% FCClass is a GARII Module %%%%%%%%%%%%%
    %%%%%%%%% Field Controller for "Zoidberg magnet" %%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %DO NOT USE DEV.CHECK FOR THIS MODULE
    
    %Internal parameters
    properties (SetAccess = private, GetAccess = public)
        %A field is defined by its 
        % - centre field
        % - sweep width
        % - the position or address within that sweep. The sweep width is
        %   discretized in 4096 steps.
        % All fields in G
        
        %Field characteristics
        MIN_FIELD = -50; %min field
        MAX_FIELD = 23000; %max field
        SW_RANGE = 16000; %Sweep range 0 to max
        
        %Resolutions
        CF_RES = 5.0e-2; %Maximum centre field resolution
        SW_RES = 0.1; %Maximum sweep resolution
        FIELD_RES = 5.0e-3; %Maximum field resolution (repeatability of CF)
        MIN_SW_STEP = 1e-3; %Minimum step size for sweeps
        
        %Sweep register
        MIN_SW = 0;
        CF_SW = 2048;
        MAX_SW = 4095;
        
        %Current values
        cur_cf = [];
        cur_sw = [];
    end
    
    %Main parameters
    properties (Access = public)
        hMeasField; %Handle to UI showing current field
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = FCClass()
            %Module name
            obj.name = 'Field Controller';
            
            %Instrument properties
            obj.INST_brand = 'ni'; %(This is actually just which VISA driver it uses)
%             obj.INST = {{'', 'gpibio', 2}};
            obj.INST = {{'', 'visa', 'GPIB0::2::INSTR'}};
            
            %Define parameters
            obj.params{1} = ParameterClass(obj,'field','Magnetic field (G)',{1 3000 0 1},...
                                           @obj.field_check,@obj.field_set);
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
            obj.dev = [];
            %dev.close doesn't work for FC apparently
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            obj.dev.clear_device(); %set field to 3480 and sweep to 100
            obj.get_centre_field();
            obj.set_sweep_width(0.1);
        end
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Set sweep width
            fieldobj = obj.get_param('field');
            if(fieldobj.param{1} == 1) %no sweep
                obj.set_sweep_width(0.1);
            else %sweep
                [minval,maxval] = fieldobj.get_sweep_min_max();
                sweepcenter = (maxval + minval)/2;
                sweepwidth = maxval - minval;
                obj.set_centre_field(sweepcenter);
                obj.set_sweep_width(sweepwidth);
            end
            
            %Setup sweep axis & send initial values to device
            ok_flag = obj.tool_exp_setup('no_check');
        end
       
        %During experiment, sweep to next point
        %pos = [X Y PC] index value, type = which pos is changed
        function ok_flag = experiment_next(obj,type,pos)
            %IN CASE OF LINEAR SWEEP, DO FASTER THEN FIELD_SET
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
    end
    
    %Wrapper for internal functions
    methods (Access = public)
        function [cf] = get_centre_field(obj)
            reply = obj.dev.ask('CF');
            cf = str2num(reply(4:end));  %#ok<*ST2NM>
            obj.cur_cf = cf;
        end
        
        function [sw] = get_sweep_width(obj)
            reply = obj.dev.ask('SW');
            sw = str2num(reply(4:end)); 
            obj.cur_sw = sw;
        end
        
        function [field] = get_field(obj)
            cf = obj.get_centre_field();
            sw = obj.get_sweep_width();
            sa = obj.get_sweep_address(); 
            
            field = cf - sw/2 + sw*sa/obj.MAX_SW;
        end
        
        function [range] = get_range(obj)
            cf = obj.get_centre_field();
            sw = obj.get_sweep_width();
            range = [ (cf - sw/2) (cf + sw/2)];            
        end
        
        function [sa] = get_sweep_address(obj)
            reply = obj.dev.ask('SA');
            sa = str2num(reply(4:end)); 
        end
          
        %Set magnetic field properly (set, check and wait until steady)
        function [ok] = field_set(obj,field)
            if(isempty(obj.cur_cf))
                obj.get_centre_field(); %update obj.cur_cf
            end
            cf = obj.cur_cf;
            if(isempty(obj.cur_sw))
                obj.get_sweep_width(); %update obj.cur_sw
            end
            sw = obj.cur_sw;
            
            %Convert new field to address within sweep
            field = round(field/obj.MIN_SW_STEP)*obj.MIN_SW_STEP;
            new_sa = floor(((field - (cf - sw/2)) * (obj.MAX_SW / sw)));
            
            %If new field is outside sweep range, set to centre field
            %Better to be at center because sweep might be up or down
            if(new_sa < obj.MIN_SW || new_sa > obj.MAX_SW)
                field = round(field/obj.CF_RES)*obj.CF_RES;
                if(field-sw/2 < obj.MIN_FIELD || field+sw/2 > obj.MAX_FIELD)
                    ok = 0;
                    return;
                end
                obj.set_centre_field(field);
                obj.set_sweep_address(obj.CF_SW);
            else %Field within sweep
                obj.set_sweep_address(new_sa);
            end

            %Wait for steady field: much slower sweep, but not very
            %reliable otherwise
            obj.wait_for_steady_field();
            meas_field = obj.get_field();
            if(abs(field - meas_field) < obj.CF_RES)
                ok = 1;
                set(obj.hMeasField,'String',num2str(meas_field));
            else
                ok = 0;
                return;
            end
        end
    end
    
    %Internal functions
    methods (Access = private)
        function [obj] = set_centre_field(obj,cf)
            cf = max(obj.MIN_FIELD, min(obj.MAX_FIELD, cf));
            obj.dev.write(sprintf('CF%+g',cf));
            obj.get_centre_field(); %update cur_cf
        end
        
        function [obj] = set_sweep_width(obj,sw)
            sw = max(0, min(obj.SW_RANGE, sw));
            obj.dev.write(sprintf('SW%+g',sw));
            obj.get_sweep_width(); %update cur_sw
        end
        
        function [obj] = set_sweep_address(obj,sa)
            sa = max(obj.MIN_SW, min(obj.MAX_SW, sa));
            obj.dev.write(sprintf('SS%d',round(sa)));
        end 
        
        %Wait for steady field
        function [obj] = wait_for_steady_field(obj)
            result = '';
            while strcmp(result,'LE4')==0
                result = strtrim(obj.dev.ask('LE'));
                pause(0.1);
            end
        end
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = field_check(obj,value) %GHz
            flag = 1;
            
            if(any(value < obj.MIN_FIELD | value > obj.MAX_FIELD)) 
                flag = 0;
                obj.msgbox(['Magnetic field must be set between ' ...
                    num2str(obj.MIN_FIELD) ' G and ' num2str(obj.MAX_FIELD) ' G']);
            end
        end
    end
end


%%%%%
%%%%% Stepper Motor:
%%%%% HeeJin Lim
%%%%% 19/08/2016
%%%%%
classdef STMClass < ModuleClass
    %Internal parameters
    properties (SetAccess = private, GetAccess = public)
        HOST = 'localhost';
        PORT = 4223;
        UID = '5W3iJs'; % Change to your UID
        step_mode = 4;% 1 2 4 8
        motor_rotation_steps = 200;
        motor_gear = 25;
        probe_gear = 75;
        
        %%%%%%%%%%%%
        gear_ratio=0;
        motor_deg_fullstep = 1.0;
        probe_deg_fullstep = 1;
        probe_step = 1;
        %%%%%%%%%%%%%%%%
        
        probe_angle_0 = 0;
        motor_position_0 =0;
        motor_position_f =0;
        probe_angle_f=0;
        theta=0;
        theta_f=0;
        
        ipcon=[];
        stepper=[];
    end
    
    %Main parameters
    properties (Access = public)
        hMeasAng; %Handle to UI showing current angle
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = STMClass()
            %Module name% param {1} ==1 no sweep, {4}==1 linear, {2} =
            %start, {3}= step
            obj.name = 'Step Controller';
            obj.gear_ratio = obj.probe_gear/obj.motor_gear; % default = 3
            obj.motor_deg_fullstep = 360.0/obj.motor_rotation_steps; % deg motor rotation per motor full step
            obj.probe_deg_fullstep = obj.motor_deg_fullstep/obj.gear_ratio; % deg probe rotation per motor full step
            obj.probe_step = obj.probe_deg_fullstep/obj.step_mode;
            
            obj.INST_brand = 'ni';
            obj.INST = {{' ' '' ''}};
            
            obj.params{1} = ParameterClass(obj,'ang','Angle~(degree)',{1 0 0 1},...
                                           @obj.ang_check,@obj.ang_set);
                                       fprintf('created?\n');
        end
        
        %Connect
        function connect(obj)
            import com.tinkerforge.IPConnection;
            import com.tinkerforge.BrickStepper;
                obj.ipcon=IPConnection();
                obj.stepper = handle(BrickStepper(obj.UID, obj.ipcon), 'CallbackProperties'); % Create device object
                obj.ipcon.connect(obj.HOST, obj.PORT); % Connect to brickd
                 %1/8 step mode, options are 1,2,4,8 (1/1,1/2,1/4,1/8)
                obj.stepper.setMotorCurrent(750); % 750mA
                obj.stepper.setStepMode(obj.step_mode); % set step mode
                obj.stepper.setMaxVelocity(10); % Velocity 25 steps/s
                obj.stepper.setSpeedRamping(50, 50); % Higher accelerations cause jitters in full step mode
               
                obj.stepper.setCurrentPosition(0);
                obj.motor_position_0 = obj.stepper.getCurrentPosition();
                obj.probe_angle_0 = obj.stepper.getCurrentPosition()*obj.probe_step;
                obj.theta=0;
                
                obj.dev=1;
                fprintf('connected\n?');
                obj.stepper.enable();
        end
        
        %Disconnect
        function disconnect(obj)
            obj.reset();
        end
        
        %Reset to some defaut parameter
        function reset(obj) 
           obj.stepper.disable();
           obj.ipcon.disconnect();
           obj.dev=[];
        end
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Set sweep width
            %fieldobj = obj.get_param('ang');
            
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
            if(~isempty(obj.stepper))
                ok_flag = 1;
            else
                ok_flag = 0;
            end
        end
        
        function ok = ang_set(obj,theta)
            set_final_rel_pos(obj,theta-obj.theta);
            move(obj);
            set(obj.hMeasAng,'String',num2str(obj.theta));
            ok=1;
        end
    end
   
    
    %Internal functions
    methods (Access = private)

        function set_index_pos(obj)
            obj.motor_position_0 = obj.stepper.getCurrentPosition();
            obj.probe_angle_0 = obj.stepper.getCurrentPosition()*obj.probe_step;
        end
        function ok = set_final_rel_pos(obj,theta_set)
            set_index_pos(obj);
            %theta_set = ang; % Desired probe rotation in degrees
            % Calculale angle nearest to but not exceeding set angle, which can be
            % reached in an integer number of motor steps
            motor_fullstep = fix(theta_set/(obj.probe_deg_fullstep));% Calculates integer number 
            % nearest to zero (sign(Z)*floor(|Z|)) of full motor steps to desired step angle
            motor_step_set = motor_fullstep*obj.step_mode; % number of motor steps corrected for mode
            if motor_step_set ~= 0
                fprintf('theta set = %f\n',theta_set);
                theta_probe = motor_fullstep*obj.probe_deg_fullstep; %  Recommended rotation step
                obj.motor_position_f = obj.motor_position_0+motor_step_set;
                obj.probe_angle_f = obj.probe_step*obj.motor_position_f;
                fprintf('Probe deg per step= %g, full motor steps per theta rotation = %g.\n', obj.probe_deg_fullstep, motor_fullstep);
                fprintf('Desired rotation step = %g degrees, actual step = %g degrees.\n', theta_set, theta_probe);
                obj.theta_f=obj.theta+theta_probe;
            end
            ok=1;
        end
        function ok = move(obj)
            pause(0.1);
            
            if obj.motor_position_f-obj.motor_position_0 ~= 0
                fprintf('Need to move!.\n');
                obj.stepper.setSteps(obj.motor_position_f-obj.motor_position_0);
                tmp = obj.stepper.getCurrentPosition();
                while ~(tmp == obj.motor_position_f),
                    %fprintf('still in wandering?\n');
                    pause(0.1);
                    tmp = obj.stepper.getCurrentPosition();
                end
                fprintf('Position has reached step %g.\n',tmp);
                obj.theta=obj.theta_f;
            end
            
            ok=1;
        end
        

    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag=ang_check(obj,value)
            flag=1;
        end
    end
end


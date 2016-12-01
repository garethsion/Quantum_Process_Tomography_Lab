function trigger_step_motor_20160410()
    import com.tinkerforge.IPConnection;
    import com.tinkerforge.BrickStepper;

    HOST = 'localhost';
    PORT = 4223;
    UID = '5W3iJs'; % Change to your UID

    ipcon = IPConnection(); % Create IP connection
    stepper = handle(BrickStepper(UID, ipcon), 'CallbackProperties'); % Create device object

    ipcon.connect(HOST, PORT); % Connect to brickd
    % Don't use device before ipcon is connected

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set stepper motor settings
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    step_mode = 8; %1/8 step mode, options are 1,2,4,8 (1/1,1/2,1/4,1/8)
    
    stepper.setMotorCurrent(750); % 750mA
    stepper.setStepMode(step_mode); % set step mode
    stepper.setMaxVelocity(10); % Velocity 25 steps/s
    stepper.setSpeedRamping(50, 50); % Higher accelerations cause jitters in full step mode
 
    % Gear settings
    motor_rotation_steps = 200;
    motor_gear = 25;
    probe_gear = 75;
    
    gear_ratio = probe_gear/motor_gear; % default = 3
    motor_deg_fullstep = 360.0/motor_rotation_steps; % deg motor rotation per motor full step
    probe_deg_fullstep = motor_deg_fullstep/gear_ratio; % deg probe rotation per motor full step

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set step size 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

    theta_set = 1; % Desired probe rotation in degrees
    
    % Calculale angle nearest to but not exceeding set angle, which can be
    % reached in an integer number of motor steps
    motor_fullstep = fix(theta_set/(probe_deg_fullstep));% Calculates integer number 
    % nearest to zero (sign(Z)*floor(|Z|)) of full motor steps to desired step angle
    motor_step_set = motor_fullstep*step_mode; % number of motor steps corrected for mode
    probe_step = probe_deg_fullstep/step_mode; % angle of theta step corrected for mode
    theta_probe = motor_fullstep*probe_deg_fullstep; %  Recommended rotation step
    
    fprintf('Probe deg per step= %g, full motor steps per theta rotation = %g.\n', probe_deg_fullstep, motor_fullstep);
    fprintf('Desired rotation step = %g degrees, actual step = %g degrees.\n', theta_set, theta_probe);
    
    stepper.enable(); % Enable motor power

   % Set starting motor position to 0 
   % stepper.setCurrentPosition(0); % Sets initial motor position to 0
    motor_position_0 = stepper.getCurrentPosition() % Record initial position
    probe_angle_0 = motor_position_0*probe_step;
    fprintf('Position has reached step %g.\n',probe_angle_0);
    stepper.setSteps(motor_step_set); % Step forward by corrected rotation
    
   % Set motor steps to rotate by desired angle

    motor_position_f = motor_position_0+motor_step_set;
    probe_angle_f = probe_step*motor_position_f;
    fprintf('Motor position set to step %g. Probe angle set to %g degrees.\n', motor_position_f, probe_angle_f);

    tmp = stepper.getCurrentPosition();
    while ~(tmp == motor_position_f),
        tmp = stepper.getCurrentPosition();
    end
    fprintf('Position has reached step %g.\n',tmp);
    
    stepper.disable();
    ipcon.disconnect();
end



classdef L78Class < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% L78Class is a GARII Module %%%%%%%%%%%%%%
    %%%%%%%%%% NTK Koheras Boostik 1078 Laser %%%%%%%%%%%%% 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)
    
        % This is the laser module we're adressing as decimal. Get it from the official software.
        destination;
        % This is us :) We must have an address greater than 64 (0x40)
        source;
        % Serial connection to the laser
        s = 0
    end

    properties(GetAccess = 'public', SetAccess = 'private')
        % Internally the laser has an offset in nm and an setpoint in pm the real setpoint is then offset+setpoint
        wavelengthOffset = 0

        % laser status: constant current mode (0) or constant power mode(1)
        constantPowerMode = 0
        % laser status: piezo tuning input port enabled(1) or disabled(0)
        piezoTuningEnabled = 0
        %laser status: hfGainCircuitEnabled
        hfGainCircuitEnabled = 0
        %laser status: using wavelength(1) or temperature(0) tuning mode
        wavelengthTuningMode = 0
        %laser status: fiber laser temperature stable(0) or unstable(1)
        fiberLaserTemperatureStable = 0
        %laser status: pump temperature stable(0) or unstable(1)
        pumpTemperatureStable = 0        
    end

    %Public properties
    properties (Access = public)
        wavelengthSetpoint = 1078.14;
        % Only allow to set wavelength above this value [nm]
        wavelengthMin = 0
        % Only allow to set wavelength below this value [nm]
        wavelengthMax = 0
        %this can be used to make sure you never send a setpoint in pm
        %outside the desired range due to offset calibration
        referenceOffset = 0
        % Only allow to set power above this value [mW]
        powerMin = 0
        % Only allow to set power below this value [mW]
        powerMax = 2000
        
        calib_SetPointWavelength = 0
        calib_MeasuredWavelength = 0
        calib_Difference = 0
        % laser status: emission
        emission = 0
        
        WS7
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = L78Class()
            %Module name
            obj.name = 'NKT 1078';
            
            %Instrument properties
            obj.INST_brand = 'ni';
            obj.INST = {{' ' '' ''}};

            %Define parameters
            obj.params{1} = ParameterClass(obj,'wavelength','Wavelength (nm)',{1 1078.140 0 1},...
                                           @obj.wavelengthSetpoint_check,@obj.set_laser_wavelength_PID);
                                       
                                       
            obj.settings{1} = SettingClass(obj,'tolerance','Tolerance (nm)', 0.002,...
                                           @obj.tolerance_check, []);
                              
            %obj.params{2} = ParameterClass(obj,'power','Power (mW)',{1 25 0 1},...
            %                               @obj.power_check,@obj.set_power);
                              
        end
        
        %Connect
        function connect(obj)
            % Laser Instantiate laser object at a given serial connection
            %   Supply the virtual $comPort and the $baudRate of the
            %   system. Specify the address (in decimal) of the laser
            %   module $destination and assign yourself as sender a address
            %   $source (that needs to be greater than 64).
            %   On instantiation the laser is queried for its status and
            %   wavelength offset.
            obj.s = openSerial('COM3', 115200); %ComPort, Baudrate
            if obj.s ~= 0
                obj.destination = 10;
                obj.source = 66;
                obj.autoSelectLaserType();
                obj.getStatus();
                obj.getWavelengthSetpoint();
                obj.getWavelengthOffset()
                obj.dev=1;
            else
                obj.dev=[];
            end
        end
        
        %Disconnect
        function disconnect(obj)
            fclose(obj.s);
            delete(obj.s)
            obj.s= 0;
            obj.dev=[];
        end
        
        %Reset to some defaut parameter
        function reset(obj)
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            obj.WS7 = obj.child_mods{1};
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
    
    % High level set wavelength functions sweep functions
    methods (Access = public)
        
        function calibrate_Offset(obj,~,~)
            obj.WS7 = obj.child_mods{1};
            obj.calib_SetPointWavelength = obj.getWavelengthSetpoint(); 
            obj.calib_MeasuredWavelength = obj.WS7.get_wavelength();
            obj.calib_Difference = obj.calib_MeasuredWavelength -...
                                    obj.calib_SetPointWavelength; 
        end
            
        
        function set_laser_wavelength_PID(obj, target_wavelength)
            Kp = 0*1;
            Ki = 0*0.01;
            Kd = 0*-0.2;
            tol=obj.get_setting('tolerance').val; % to [nm]
            firstSetPoint=obj.getWavelengthSetpoint(); % obj.WS7.get_wavelength();
            integral= 0;
            previous_error=0;
            dt = 0.05;
            ctRound = 0;
            current_wavelength=obj.WS7.get_wavelength();
            err = target_wavelength-current_wavelength;
            while  abs(err) > tol
                ctRound = ctRound+1;
                current_wavelength=obj.WS7.get_wavelength();
                err = target_wavelength-current_wavelength;
                integral = integral + min(err,0.005)*dt;
                if ctRound == 1
                    derivative = 0;
                else
                    derivative = (err - previous_error)/dt;
                end
                
                output = Kp*max(0.005,err) + Ki*integral + Kd*derivative;
                if obj.calib_SetPointWavelength ~= 0
                    
                    newSetPoint = target_wavelength - obj.calib_Difference +...
                                + output;
                else
                    newSetPoint = firstSetPoint + output;
                end
                
                %Limit setpoint to interval given by wavelengthMin
                %wavelengthMax
                newSetPoint(newSetPoint>obj.wavelengthMax) = obj.wavelengthMax;
                newSetPoint(newSetPoint<obj.wavelengthMin) = obj.wavelengthMax;
                obj.setWavelengthSetpoint(newSetPoint);
                pause(dt)
            end
        end
    end
        
    
    %Lower level set wavelength for internal functions
    methods (Access = public)
        function warning = getStatus(obj)
            %FIXME: Somethings odd here...
            register = hex2dec('1F');
    
            t = telegram(obj.source, obj.destination, register, false);
            [result payload] = t.send(obj.s);
            payload = hex2dec(payload);
            
            if result == false
                error('Getting status failed with error %d', result)
            end
            
            status = dec2bin(payload(1),8);
            warning = payload(2);
            
            if(status(8) == 1) 
                obj.emission = 1;
            else
                obj.emission = 0;
            end
            
            if(status(7) == 1) 
                obj.constantPowerMode = 1;
            else
                obj.constantPowerMode = 0;
            end
            
            if(status(6) == 1) 
                obj.piezoTuningEnabled = 1;
            else
                obj.piezoTuningEnabled = 0;
            end
            
            if(status(5) == 1) 
                obj.hfGainCircuitEnabled = 1;
            else
                obj.hfGainCircuitEnabled = 0;
            end                
                        
            if(status(4) == 1) 
                obj.wavelengthTuningMode = 1;
            else
                obj.wavelengthTuningMode = 0;
            end
            
            if(status(3) == 1) 
                obj.fiberLaserTemperatureStable = 0;
            else
                obj.fiberLaserTemperatureStable = 1;
            end  
            
            if(status(2) == 1) 
                obj.pumpTemperatureStable = 0;
            else
                obj.pumpTemperatureStable = 1;
            end  
            
        end
        
        function offset = getWavelengthOffset(obj)
            register = hex2dec('28');
            
            t = telegram(obj.source, obj.destination, register, false);
            [result payload] = t.send(obj.s);

            if result == true
                offset = hex2dec(cell2mat(rot90(payload,2))); %payload transmitted in little-endian = LSB first
                obj.wavelengthOffset = offset;
            else
                error('Getting the wavelength offset failed with the error %d', result)
            end
        end
        
        
        function obj = setWavelengthSetpoint(obj, NewWavelengthSetPoint)
            %% Set wavelength setpoit in to $wavelength in [nm]
            % matlab is right, this setter should not boldly access other
            % properties without checking if they are up-to-date
            if obj.wavelengthTuningMode ~= 1
                obj.useWavelengthTuning(true);
                pause(0.5)
            end
            if NewWavelengthSetPoint< obj.wavelengthMin || NewWavelengthSetPoint  > obj.wavelengthMax
                error(sprintf('Your setpoint + calibrated offset results in wavelength = %d, which is out of range!',tmp))
            end
            
            register = hex2dec('25'); 
            value = round((NewWavelengthSetPoint - obj.wavelengthOffset)*1000); % write difference to reference offset in pm
            
            t = telegram(obj.source, obj.destination, register, true, value);
            response = t.send(obj.s);   
            obj.wavelengthSetpoint = NewWavelengthSetPoint;
        end

%         function obj = setWavelengthSetpoint(obj, NewWavelengthSetPoint)
%             %% Set wavelength setpoit in to $wavelength in [nm]
%             % No bullshit about Offset
%             if obj.wavelengthTuningMode ~= 1
%                 obj.useWavelengthTuning(true);
%                 pause(0.5)
%             end
%             tmp = NewWavelengthSetPoint - (obj.wavelengthOffset-obj.referenceOffset)
%             if NewWavelengthSetPoint - (obj.wavelengthOffset-obj.referenceOffset) < obj.wavelengthMin || NewWavelengthSetPoint - (obj.wavelengthOffset-obj.referenceOffset) > obj.wavelengthMax
%                 error(sprintf('Your setpoint + calibrated offset results in wavelength = %d, which is out of range!',tmp))
%             end
%             
%             register = hex2dec('25'); 
% 
%             value = round((NewWavelengthSetPoint - obj.wavelengthOffset)*1000); % write difference to reference offset in pm
%             
%             t = telegram(obj.source, obj.destination, register, true, value);
%             response = t.send(obj.s);   
%             obj.wavelengthSetpoint = NewWavelengthSetPoint;
%         end
        
        function wavelengthSetpoint = getWavelengthSetpoint(obj)
            
            % ensure we're reading the right value
            if obj.wavelengthTuningMode ~= 1
                obj.useWavelengthTuning(true);
                pause(0.2)
            end
            
            % get the setpoint
            register = hex2dec('25');
            t = telegram(obj.source, obj.destination, register, false);
            [result payload] = t.send(obj.s);
            
            if result == true
                setpoint = hex2dec(cell2mat(rot90(payload,2))); %payload transmitted in little-endian = LSB first
                wavelengthSetpoint = obj.wavelengthOffset + setpoint/1000;
                obj.wavelengthSetpoint = wavelengthSetpoint;
            else
                error('Getting the wavelength setpoint failed with the error %d', result)
            end
        end
        
        function obj = useWavelengthTuning(obj, value )
            % Whether the wavelength or the fiber temperature is to be set.
            register = hex2dec('34');

            if value == true || value == 1
                value = 1;
            elseif value == false || value == 0
                value = 0;
            else
                error('Can only set tuning mode to wavelength (true) or temperature (false).')
            end

            t = telegram(obj.source, obj.destination, register, true, value, true);
            response = t.send(obj.s);

            if response == false
                if value == 1
                    error('Setting wavelength tuning mode failed')
                else
                    error('Setting temperature tuning mode failed')
                end
            end
            obj.wavelengthTuningMode = value;
        end
        
    end
    
    %Internal functions
    methods (Access = private)
        function autoSelectLaserType(obj)
            % get the serial number
            register = hex2dec('65');
            t = telegram(obj.source, obj.destination, register, false);
            [result payload] = t.send(obj.s);
            
            if result == true
                serial = sprintf('%X',cell2mat(rot90(payload,2))); %payload transmitted in little-endian = LSB first
                if strcmp(serial,'33303330333233303337333233323331') %ARSENIC LASER
                    disp('Arsenic laser set up.');
                    % Only allow to set wavelength above this value [nm]
                    obj.wavelengthMin = 1078.350;
                    % Only allow to set wavelength below this value [nm]
                    obj.wavelengthMax = 1079.110;
                    obj.powerMax = 100;

                elseif strcmp(serial,'33363335333133303330333533313331') %PHOSPHORUS LASER
                    disp('Phosphorus laser set up.');
                    % Only allow to set wavelength above this value [nm]
                    obj.wavelengthMin = 1077.760;
                    % Only allow to set wavelength below this value [nm]
                    obj.wavelengthMax = 1078.520;
                    obj.powerMax = 300;

                else
                    error('This is a unfamiliar laser, please contact the lab manager to set up this new laser properly')
                end
            else
                error('Getting the wavelength setpoint failed with the error %d', result)
            end
        end
    end
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = wavelengthSetpoint_check(obj,value)
            flag =1; 
            if any([value<obj.wavelengthMin,value>obj.wavelengthMax])
                flag=0;
                obj.msgbox(sprintf('Select wavelength between [%.9g %.9g]',...
                    obj.wavelengthMin,obj.wavelengthMax))
            end 
        end
        
        function flag = tolerance_check(obj,value)
            flag = 1;
            if any([value<0,value>1])
                flag=0;
                obj.msgbox(sprintf('Select tolerance for wavelength setpoint between [%.9g %.9g] nm',...
                    0, 1))
            end 
        end

    end
end


classdef OS2000Class < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% OS2000Class is a GARII Module %%%%%%%%%
    %%%%% Ocean Optics Spectrometer USB 2000+ %%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)
    end
    
    %Main parameters
    properties (Access = public)
        %Spectrometer connected
        spec = {};
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = OS2000Class()
            %Module name
            obj.name = 'Ocean Optics Spectrometer USB 2000+';
            
            %Instrument properties
            obj.INST_brand = '';
            obj.INST = {{' ' '' ''}};
            
            %Define measures
            obj.measures{1} = MeasureClass(obj,'spectrum','Intensity (counts)',...
                                    @()obj.acquire_spectrum,'Wavelength (nm)');
            obj.measures{1}.state = 1;
            
            %Define settings
            %Connected spectrometers
            obj.settings{1} = SettingClass(obj,'spectroIndex','Spectrometer',...
                                           '',[],[],{''});
            %Channel ?
            obj.settings{end+1} = SettingClass(obj,'spectroChannel','Channel',...
                                           '0',[],[],{'0'});
            %Integration time for sensor
            obj.settings{end+1} = SettingClass(obj,'integtime','Integration time (s)',...
                                           10,@obj.integtime_check,@obj.integtime_set);
                                       
            %Correct for detector non-linearity
            obj.settings{end+1} = SettingClass(obj,'nonlincor','Non-linearity correction?',...
                                           1,[],@obj.nonlincor_set);
            
            %Correct for electrical dark
            obj.settings{end+1} = SettingClass(obj,'elecdarkcor','Dark correction?',...
                                           1,[],@obj.elecdarkcor_set);
        end
        
        %Connect
        function connect(obj)
            %This has no usual SCPI connection, but its own driver
            %The OceanOptics matlab package must be downloaded
            obj.dev = icdevice('OceanOptics_OmniDriver.mdd');
            if(~isempty(obj.dev))
                obj.dev.connect(); %icdevice connect function, not GARII
                if(strcmpi(obj.dev.Status,'close'))
                    delete(obj.dev);
                    obj.dev = [];
                else
                    obj.reset();
                end
            end
        end
        
        %Disconnect
        function disconnect(obj)
            obj.dev.disconnect();
            delete(obj.dev);
            obj.dev = [];
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            %Identify the spectrometer connected
            num_spec = obj.dev.invoke('getNumberOfSpectrometersFound');
            if(num_spec ~= 0)
                obj.spec = cell(num_spec,1);
                names = cell(num_spec,1);
                for ct = 1:num_spec
                    obj.spec{ct} = struct('name',obj.dev.invoke('getName',ct),...
                                          'serial',obj.dev.invoke('getSerialNumber',ct));
                    names{ct} = obj.spec{ct}.name;
                end
                
                %Send spec names to UI
                set(obj.get_setting('spectroIndex').hText,'String',names,'Value',1);
            end
        end        
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            %Setup sweep axis & send initial values to device
            ok_flag = obj.tool_exp_setup('no_check');
            if(ok_flag)
                obj.spectrowavelength_set();
            end
        end
        
        function experiment_setread(obj)
        end
        
        function ok_flag = experiment_next(obj,type,pos)
            ok_flag = 1;
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
    end
    
    %Internal functions
    methods (Access = private)
        %Integration time for sensor
        function integtime_set(obj,value)
            spec_index = get(obj.get_setting('spectroIndex').hText,'Value');
            channel = str2double(obj.get_setting('channel').val);
            
            obj.dev.invoke('setIntegrationTime', spec_index, channel, value);
        end
        
        %Correct for non-linearity
        function nonlincor_set(obj,value)
            spec_index = get(obj.get_setting('spectroIndex').hText,'Value');
            channel = str2double(obj.get_setting('channel').val);
            
            obj.dev.invoke('setCorrectForDetectorNonlinearity', ...
                spec_index, channel, value);
        end
        
        %Correct for electrical dark
        function elecdarkcor_set(obj,value)
            spec_index = get(obj.get_setting('spectroIndex').hText,'Value');
            channel = str2double(obj.get_setting('channel').val);
            
            obj.dev.invoke('setCorrectForElectricalDark', ...
                spec_index, channel, value);
        end
        
        %Obtain spectrometer wavelength axis
        function spectrowavelength_set(obj)
            spec_index = get(obj.get_setting('spectroIndex').hText,'Value');
            channel = str2double(obj.get_setting('channel').val);
            
            wl = obj.dev.invoke('getWavelengths', spec_index, channel);
            obj.get_measure('spectrum').transient_axis.vals = wl;
        end
        
        %Acquire spectrum
        function spectralData = acquire_spectrum(obj)
            spec_index = get(obj.get_setting('spectroIndex').hText,'Value');
            
            spectralData = obj.dev.invoke('getSpectrum', spec_index);
        end
        
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = integtime_check(obj,value)
            flag = 1;
            
            if(any(value < 0)) 
                flag = 0;
                obj.msgbox('Integration time must be positive.');
            end
        end
    end
end


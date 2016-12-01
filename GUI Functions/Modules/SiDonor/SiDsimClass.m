classdef SiDsimClass < ModuleClass
    %SiDsimClass is a Module for the experiment GUI
    
    properties
        %GUI handles
        hFreq %Frequency 
        hDonor %Donor type
        hCal %Setup calibration
        hTemp %Temperature
        hT1 %T1 output
        hTABLE %Result table
        hCompute %Compute start button
        
        %Donor types
        donors = {'31P' '75As' '121Sb' '123Sb' '209Bi' '77Se+'};
    end
    
    %Main methods
    methods (Access = public)
        function obj = SiDsimClass()
            obj.name = 'Si:D simulator';
        end
        
        %% Si Donor SETTINGS
        
        %% EXPERIMENT FUNCTIONS (NOT USED FOR THIS MODULE)
        %Setup the experiment
        function ok_flag = experiment_setup(~,~)
            ok_flag = -1;
        end
        
        %During experiment
        function ok_flag = experiment_next(~)
            ok_flag = -1;
        end
        
        %End of experiment
        function ok_flag = experiment_stop(~)
            ok_flag = -1;
        end
        
    end
    
    %GUI methods
    methods (Access = public)
        %Get frequency from VSG settings (start value)
        function get_freq_from_VSG(obj,~,~)
            VSG = obj.MAIN.get_mods_from_name('VSG');
            VSG = VSG{1};
            
            if(~isempty(VSG))
                set(obj.hFreq,'String',VSG.get_param('freq').param{2});    
            end
        end
        
        %Computation of donor parameters: field/trans proba etc...
        function compute(obj,~,~)
            global SYSPARAM;

            freq = str2double(get(obj.hFreq,'String'))*1e9;
            if(~isnan(freq))
                donor_type = obj.donors{get(obj.hDonor,'Value')};

                %Start computation
                set(obj.hCompute,'Enable','off','BackgroundColor','red','String','Computing...');
                drawnow;

                SYSPARAM = SiDonorClass(donor_type);
                B0sweep = linspace(0,1.5*abs((freq+SYSPARAM.A*SYSPARAM.I)/SYSPARAM.E),5000);
                SYSPARAM.set('B',B0sweep);
                [B,MWparam] = findResonantField3(freq); %Could do ENDOR too

                %Field calibration
                type = get(obj.hCal, 'Value');
                switch(type)
                    case 2 %X
                        B = XFieldCalibration(B,1);
                    case 3 %EMX
                        B = XFieldCalibration(B,1);
                end

                data = [B(:)*1e3 MWparam{3}(:) MWparam{1}(:)/SYSPARAM.E MWparam{2}(:)];
                set(obj.hTABLE,'Data',data);

                clear SYSPARAM;

                %End computation
                set(obj.hCompute,'Enable','on','BackgroundColor','green','String','Simulate');
            end
        end

        %Compute T1
        function compute_T1(obj,~,~)
            %Temperature
            temperature = str2double(get(obj.hTemp,'String'));

            %Donor type
            donor_type = obj.donors{get(obj.hDonor,'Value')};
            SYSPARAM = SiDonorClass(donor_type);

            %T1 value
            T1val = interp1(SYSPARAM.T1(1,:),SYSPARAM.T1(2,:),temperature);
            set(obj.hT1,'String',num2str(T1val,3));
        end
    end
end


classdef MainClass < handle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MainClass is the main resource for the GARII program. It connects all the
% modules and GUI together, stores all the important data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %Metadata = global parameters
    properties
        metadata_types = {'SRT' 'AVG' 'SPP' 'XPTS' 'YPTS' 'STSW'};
        hMETA %handle for metadata control
        
        SRT = 0.001; %shot-repetition-point (s)
        AVG = 1; %Nb of average
        SPP = 1; %Shot per points
        XPTS = 1; %X axis points
        YPTS = 1; %Y axis points
        STSW = 0; %Stochastic flag
        
        %This is a flag (no button) to know if X axis is now for transient
        %measurement
        transient = 0;
    end
    
    %Sweep and variable controls
    properties
        %Sweep control
        hSWEEP %Handle to sweep control
        UserData = {'' ''}; %Panel name, cursorPos within panel
        
        %Variables/Phase cycling programs
        PCPTS = 1;
        PC_types = {}; %names
        PC_data = []; %values: each col for each name
        PC_weight = 1; %how to sum the PCs: sum(PC_weight.*measure)
    end
    
    %Modules
    properties
        %Main window (UI)
        hWIN
        
        %Module selection (UI)
        hPanelList
        
        %Module name, can be used as nameClass and nameGUI
        %Allowed modules
        %Modules can be set in groups using {}. In this case, only the
        %first one will be displayed for adding/removing, but the whole
        %group goes together.
        mods_name = {{'PG' 'AWG'} 'AWG 81180 with Pulse creator (PG)';...  
                     'MSO' 'Oscilloscope DSO-X 3014A';...
                     'VSG' 'Vector signal generator E8267D';...
                     'FC' 'Zoidberg Field Controller';...
                     'VNA' 'Vector Network Analyzer 8722D';...
                     'SiDsim' 'Simulator for Si:Donor spin systems';...
                     'KEI2400' 'Keithley 2400';...
                     'KEI6430' 'Keithley 6340';...
                     'SR830' 'Stanford Research SR830';...
                    {'L78' 'WS7'} 'Fibre laser control'; ...
                     %'WS7' 'Wavelength Meter WS7';...
                     'A33' 'AWG 33522';...
                     'DAG' 'Data Analysis module for GARII';...
                     'ESR' 'ESR Tools';...
                     'OS2000' 'Ocean Optics Spectrometer USB 2000+';...
                     %'R3271' 'Spectrum Analyzer Advantest R3271';
                     'DG645' 'Pulse Delay Generator DG645';
                     'STM' 'Step Motor Controller';
                     'CB' 'Capacitance Bridge Agilent E4980A' 
                     };
        mods_ID = {};
        mods %handle to modules
        
        %Connections
%         hConnectAll %Button for connecting to all modules
    end
    
    %Measurement
    properties
        %GUI handles
        hPLOT %Plot figure; 1,2: plot 3:axis 4,5:select handle
        hOPT %Options
        hPLAY %PLAY button handle
        hSAVE %Save buttons
        hSTATUS %Status bar handle
        
        %Plot
        plot_autoScale = 1;
        dataCal = struct('status',0,'file',[]); %Calibrate data
        
        %Current plot index
        current_plot = cell(2,1); %{plot #}{module.ID measure.name}
        
        %Current experiment run point (AVG,X,Y,PC,SPP)
        cur_exp_pos = [1 1 1 1 1];
        
        %Log for main measurement
        mLOG = LogClass('Measurement',0); 
        LOG_DEBUG = LogClass('Debug log',0); 
        
        %Run parameters
        run_flag = 0;%-1:BLOCKED (use with UnlockStart)
                      %0:Stopped
                      %1:Running
                      %2:Setting up
                      %3:Stopping at end of current Point
                      %4:Stopping at end of current Averaging
                      %5:Pause
        run_mode = 'Single run';
    end
    
    %Other
    properties
        %Root path of GARII
        root_path
        
        %Creation date
        version
    end
    
    %Main functions
    methods (Access = public)
        %Main class creation
        function obj = MainClass()
            %Creation date
            obj.version = datestr(now);
        end
        
        %Closing Main
        function delete(obj)
             %Disconnect
            try %Use try because some modules may not have .disconnect
                %Or may not disconnect properly
                for ct = 1:length(obj.mods)
                    obj.mods{ct}.disconnect();
                end

                %Another way to disconnect in case first one didn't work (for visa)
                %Any disconnect of FC crashes matlab (TO SOLVE), so prevent
                %intrreset if FC is connected
                %NOT ANYMORE???
%                 if(isempty(obj.get_mods_from_name('FC')))
%                    instrreset; 
%                 end
            catch
            end
        end
        
        %Get module handle from ID
        function [mod_obj, idx] = get_mod(obj,ID)
            idx = find(strcmp(obj.mods_ID,ID) == 1,1);
            if(~isempty(idx))
                mod_obj = obj.mods{idx};
            else 
                mod_obj = [];
            end
        end
        
        %Get module handle from name (all corresponding IDs)
        function [mod_obj, idx] = get_mods_from_name(obj,name)
            names = obj.ID2name(obj.mods_ID);
            idx = find(strcmp(names,name) == 1);
            mod_obj = obj.mods(idx);
        end
        
        function mod_name = ID2name(obj,ID) %#ok<INUSL>
             [~,rem] = strtok(ID,'-');
            if(~iscell(rem))
                mod_name = rem(2:end);
            else
                mod_name = cell(size(rem));
                for ct = 1:numel(rem)
                    mod_name{ct} = rem{ct}(2:end);
                end
            end
        end
        
        %Find modules that can measure
        function IDs = find_MSRE_modules(obj)
            IDs = {};
            for ct = 1:length(obj.mods)
                if(~isempty(obj.mods{ct}.measures))
                    IDs{end+1} = obj.mods{ct}.ID; %#ok<AGROW>
                end
            end
        end
        
        %Save MAIN (and all modules) to matlab file
        function saveAll(obj,~,~,varargin) %("~,~" is for event input from button)
            %Create/Open output file
            if(isempty(varargin))
                [filename, pathname] = uiputfile('*.mat','Save as',...
                                   [obj.root_path 'Library' filesep 'Experiment library']);
                if(filename == 0)
                    return;
                end
                fullpath = [pathname filename(1:end-3) 'mat'];
            else
                fullpath = varargin{1};
            end
                               
            %Save matlab files for loading
            obj.data2save(fullpath,0);
        end
        
        %Save: data preparation
        %varargin = pairs of var,var_name
        function data2save(obj,full_path,temp_flag,varargin)
            if(temp_flag)
                %Load parameters as they were when the experiment was
                %started
                MAIN = load([obj.root_path 'GUI functions' filesep 'Internal' filesep 'TempConfig.mat']);
                MAIN = MAIN.MAIN;
                
                %Reload data
                for ct = 1:length(obj.mods)
                    for ctMeas = 1:numel(obj.mods{ct}.measures)
                        MAIN.mods{ct}.measures{ctMeas}.data = ...
                            obj.mods{ct}.measures{ctMeas}.data;
                    end
                end
                
            else
                MAIN = obj;
            end
            
            var2save = cell(1+length(varargin)/2,1);
            var2save{1} = 'MAIN';
            for ct = 1:length(varargin)/2
                eval([varargin{2*ct} '= varargin{2*ct-1};']);
                var2save{ct+1} = varargin{2*ct};
            end
            
            %Remove dev before saving (otherwise matlab tries to connect when loading)
            %Also remove hWIN (create problems in Matlab > 2014a since handle are now object, not numbers)
            %Have to be careful as MAIN is a handle, so change in MAIN =
            %change in obj
            dev_temp = cell(length(MAIN.mods),1);
            hWIN_temp = MAIN.hWIN;
            MAIN.hWIN = [];
            MAIN.mLOG.close();
            for ctMod = 1:length(MAIN.mods) 
                dev_temp{ctMod} = MAIN.mods{ctMod}.dev;
                MAIN.mods{ctMod}.dev = [];
            end
            try %If by any chance, this gives error, we need to make sure we can add back first dev
                save(full_path,var2save{:});
            catch me
                disp(me.message);
            end
            MAIN.hWIN = hWIN_temp;
            for ctMod = 1:length(MAIN.mods) %Add back dev
                MAIN.mods{ctMod}.dev = dev_temp{ctMod};
            end
        end
       
        %Load MAIN (and all modules) from matlab file
        function loadAll(obj,~,~,varargin)
            if(isempty(varargin))
                [filename, pathname] = uigetfile('*.mat','Open',...
                                   [obj.root_path 'Library' filesep 'Experiment library']);
                if(filename == 0)
                    return;
                end
                fullpath = [pathname filename];
            else
                fullpath = varargin{1};
            end
            
            %Load matlab file
            file = load(fullpath);
            if(~isfield(file,'MAIN'))
                clear file;
                return;
            end
            fMAIN = file.MAIN;

            %Load metadata
            for ct = 1:length(obj.metadata_types)
                cur_meta = obj.metadata_types{ct};

                %Update metadata
                eval(['obj.' cur_meta ' = fMAIN.' cur_meta ';']);

                %Update UI
                if(~strcmp(cur_meta,'STSW'))
                    set(eval(['obj.hMETA.' cur_meta]),'String',...
                        num2str(eval(['obj.' cur_meta])));
                else
                    set(eval(['obj.hMETA.' cur_meta]),'Value',...
                        eval(['obj.' cur_meta]));
                end
            end
            
            %Load transient value
            obj.transient = fMAIN.transient;
            if(obj.transient)
                set(obj.hMETA.XPTS,'Enable','off');
            else
                set(obj.hMETA.XPTS,'Enable','on');
            end

            %Load PC/variables
            obj.PCPTS = fMAIN.PCPTS;
            obj.PC_types = fMAIN.PC_types;
            obj.PC_data = fMAIN.PC_data;
            obj.PC_weight = fMAIN.PC_weight;
            set(obj.hMETA.PCPTS,'String',int2str(obj.PCPTS));

            %Because the same module can be opened in several instances, it
            %is not clear here how to load the data. The current solution
            %is to fill in the various open modules only. For exact loading
            %of the file, use Restart('filepath'); as it will also load all
            %the necessary modules.
            %Load all params, settings, measures
            open_mods = obj.ID2name(obj.mods_ID);
            open_mods = unique(open_mods);
            
            for ct1 = 1:length(open_mods)
                [~,idx] = obj.get_mods_from_name(open_mods{ct1});
                if(length(fMAIN.mods_name) == length(fMAIN.mods) && ...
                    isempty(fMAIN.mods_ID)) %Older version loading
                
                    file_idx = find(strcmp(open_mods{ct1},fMAIN.mods_name) == 1);
                else %Newer version loading
                    [~,file_idx] = fMAIN.get_mods_from_name(open_mods{ct1});
                end
                
                for ct2 = 1:min(length(idx),length(file_idx))
                    old_mod = obj.mods{idx(ct2)};
                    new_mod = fMAIN.mods{file_idx(ct2)};
                    
                    %Load description
                    old_mod.description = new_mod.description;
                    
                    %Load device selection
                    old_mod.INSTnumber = new_mod.INSTnumber;
                    if(~isempty(old_mod.hINSTnumber))
                        set(old_mod.hINSTnumber,'Value',new_mod.INSTnumber);
                    end
                    
                    %Load params
                    if(~isempty(old_mod.user_params_load)) %User specific
                        old_mod.user_params_load(new_mod);
                    else %Standard
                        old_mod.std_params_load(new_mod.params);
                    end
                    
                    %Load settings
                    old_mod.std_settings_load(new_mod.settings);
                    
                    %Load measures
                    old_mod.std_measures_load(new_mod.measures);
                end
            end

            %Clear loaded file
            clear file;
        end
        
        %Select a module
        function UI_module_panel_update(obj,~,~)
            %Delete UserData, update sweep controls
            obj.UserData = {'' []}; 
            set(obj.hSWEEP.type(2),'Value',1);
            set(obj.hSWEEP.type(3),'Visible','off');
            set(obj.hSWEEP.type(4),'Visible','off');
    
            set(obj.hSWEEP.start(1),'String', 'Value:');
            set(obj.hSWEEP.start(2),'String','0');

            set(obj.hSWEEP.step(1),'Visible','off');
            set(obj.hSWEEP.step(2),'Visible','off');

            set(obj.hSWEEP.end(1),'Visible','off');
            set(obj.hSWEEP.end(2),'Visible','off');

            if(~isempty(obj.mods))
                %Turn off all module visibility
                for ct = 1:length(obj.mods)
                    set(obj.mods{ct}.hPanel,'Visible','off');
                end

                %Turn on selected module visibility
                set(obj.mods{get(obj.hPanelList,'Value')}.hPanel,'Visible','on');
            end
        end
        
        %Add a module
        function mod = add_module(obj,mod_name)
            %Check if module is allowed
            grp_mod = [];
            for ct = 1:size(obj.mods_name,1)
                if(any(strcmp(mod_name, obj.mods_name{ct,1})))
                    grp_mod = obj.mods_name{ct,1};
                    if(~iscell(grp_mod))
                        grp_mod = {grp_mod};
                    end
                    break;
                end
            end
            
            if(~isempty(grp_mod))
                mod = cell(length(grp_mod),1);
                for ct = 1:length(grp_mod)
                    %Create Class and UI (do it first in case Class calls other
                    %modules to be created, otherwise messes up the indexing)
                    mod{ct} = eval([grp_mod{ct} 'Class();']); %Create module class object
                    mod{ct}.MAIN = obj;
                    obj.mods{end+1} = mod{ct};               

                    %Create module ID
                    if(~isempty(obj.mods_ID))
                        mod_num = str2double(strtok(obj.mods_ID{end},'-')) + 1;
                    else
                        mod_num = 1;
                    end
                    mod_ID = [int2str(mod_num) '-' grp_mod{ct}];
                    obj.mods_ID{end+1} = mod_ID;
                    mod{ct}.ID = mod_ID;
                    
                    %Add children module to first module
                    if(ct > 1)
                        mod{1}.child_mods{end+1} = mod{ct};
                        mod{ct}.parent_mod = mod{1};
                    end    

                    %Update UI
                    mod{ct}.UI_add_mainpanel(); %Create main module panel
                    eval([grp_mod{ct} 'GUI(mod{ct});']); %Call module GUI
                    
                    set(obj.hPanelList,'String',obj.mods_ID,'Value',length(obj.mods_ID));
                    obj.UI_module_panel_update();
                    if(~isempty(mod{ct}.window_resize))
                        mod{ct}.window_resize(obj.hWIN);
                    end
                    
                    %Update measurement device list
                    if(~isempty(obj.hOPT))
                        msre_str = obj.find_MSRE_modules();
                        msre_idx = get(obj.hOPT(1), 'Value');
                        msre_idx(end+1) = max(1,length(msre_str)); %#ok<AGROW>
                        set(obj.hOPT(1), 'String',msre_str,'Value',msre_idx)
                    end
                end     
            else
                disp('Module type is not allowed.');
                mod{ct} = [];
            end
        end
        
        %Remove a module
        function remove_module(obj,mod_ID,varargin)
            [cur_mod,idx] = obj.get_mod(mod_ID);
            if(~isempty(idx))                
                %If parent, get to parent
                if((isempty(varargin) || ~strcmp(varargin{1},'child')) && ...
                    ~isempty(cur_mod.parent_mod))
                
                    obj.remove_module(cur_mod.parent_mod.ID);
                end
                
                %If has child, remove childs first
                if(~isempty(cur_mod.child_mods))
                    for ct = 1:length(cur_mod.child_mods)
                        obj.remove_module(cur_mod.child_mods{ct}.ID,'child');
                    end
                end                    
                
                if(~isempty(cur_mod.dev))
                    cur_mod.msgbox('Module must be disconnected before removal.');
                    return;
                end
                
                %Reupdate idx as parent/child removal could have change
                %indexing
                [~,idx] = obj.get_mod(mod_ID);
                remain_idx = setdiff(1:length(obj.mods),idx);
                
                %Delete module panel UI
                for ct = 1:length(idx)
                    delete(obj.mods{idx(ct)}.hPanel);
                end

                %Remove from module list
                obj.mods = obj.mods(remain_idx);
                obj.mods_ID = obj.mods_ID(remain_idx);

                %Update UI
                if(~isempty(remain_idx))
                    set(obj.hPanelList,'String',obj.mods_ID,'Value',1);
                else
                    set(obj.hPanelList,'String',' ','Value',1);
                end
                obj.UI_module_panel_update();
                
                %Update measurement device list
                if(~isempty(obj.hOPT))
                    msre_str = get(obj.hOPT(1), 'String');
                    msre_idx = get(obj.hOPT(1), 'Value');
                    
                    bad_idx = find(strcmp(mod_ID,msre_str) == 1);
                    
                    if(~isempty(bad_idx))
                        msre_str = setdiff(msre_str,mod_ID);
                        msre_idx = [msre_idx(msre_idx < bad_idx) msre_idx(msre_idx > bad_idx)-1];

                        set(obj.hOPT(1),'String',msre_str,'Value',msre_idx);
                    end
                end
            end
        end
    end
    
    %Data: metadata, sweep control, variables
    methods (Access = public)
        %Actions when ``metadata" = Xpts,... are edited
        function metadataEdit(obj,hobj,~,type)
            %Stochastic sweep box
            if(strcmp(type,'STSW')) %string entry (stochastic box)
                obj.STSW = get(hobj,'Value');
            else 
                val = get(hobj,'String');
                val = str2double(val);

                if(~isnumeric(val) || isnan(val) || isinf(val) || ...
                   ~obj.param_check(type,val)) %Metadata check
                    set(hobj,'String',eval(['obj.' type]));
                    return;
                end

                %Check all modules
                for ct = 1:length(obj.mods)
                    if(any(strcmp(type,{'XPTS' 'YPTS'})))
                        ok_flag = obj.mods{ct}.param_check(type,val);
                        if(~ok_flag)
                            set(hobj,'String',eval(['obj.' type]));
                            return;
                        end
                    end
                end

                %Passed all parameters check
                eval(['obj.' type '= val;']);

                %if function metadataEdit exist
                for ct = 1:length(obj.mods)
                    temp = obj.mods{ct};
                    if(~isempty(temp.metadataEdit))                
                        temp.metadataEdit(type,val);
                    end
                end

                %Update current sweep control
                if(~strcmp(obj.UserData{1},''))
                    temp_par = obj.get_mod(obj.UserData{1}).params{obj.UserData{2}};
                    if(isa(temp_par,'ParameterClass'))
                        obj.value2sweepControls(temp_par);
                    end
                end
            end
        end

        %Actions when sweep controls are edited
        function sweepControlsEdit(obj,~,~,edit_type)
            switch(edit_type)
                case 'SWEEPTYPE'
                    edit_type = 1;
                    test_val = get(obj.hSWEEP.type(2),'Value'); %sweep type

                case 'STARTVAL'
                    edit_type = 2;
                    test_val = get(obj.hSWEEP.start(2),'String'); %start val

                case 'STEPVAL'
                    edit_type = 3;
                    test_val = get(obj.hSWEEP.step(2),'String'); %step val

                case 'STEPTYPE'
                    edit_type = 4;
                    test_val = get(obj.hSWEEP.type(3),'Value'); %step type
            end

            %Update selected module parameter
            [cur_par, cur_mod] = obj.get_selected_parameter();
            if(~isempty(cur_par))        
                %Test if new input is viable (right variable type)
                [test_val, flag] = cur_par.param_input_check(test_val,edit_type);
                if(flag)
                    %Add to PC if it is variable
                    if(~isnumeric(test_val))
                        obj.PC_update(test_val);
                    end

                    %Check new value
                    if(cur_par.param_sweep_check(edit_type,test_val))
                        %Update new value
                        cur_par.param{edit_type} = test_val;
                        cur_par.update_label();

                        %If necessary, call additional module functions
                        if(~isempty(cur_mod.sweepControlsEdit))
                            cur_mod.sweepControlsEdit();
                        end
                    end
                end

                %Update (or put back if ~flag) sweep control
                obj.value2sweepControls(cur_par);
            end
        end

        %Get selected parameter (and associated module) (basically when clicking in the UI)
        function [cur_par, cur_mod] = get_selected_parameter(obj)
             %Update selected module parameter
            if(~strcmp(obj.UserData{1},''))
                cur_mod = obj.get_mod(obj.UserData{1});

                %Find parameter to update
                cursorPos = obj.UserData{2};
                if(~isempty(cursorPos))
                    cur_par = cur_mod.params{cursorPos};
                    if(isa(cur_par,'ParameterClass'))
                        return;
                    end
                end
            end
            cur_par = []; cur_mod = [];
        end
        
        %Send some parameter value to sweep control
        function value2sweepControls(obj,cur_par)
            hS = obj.hSWEEP;
            param_val = cur_par.param;
            
            %Send parameter value to sweep control
            set(hS.type(2),'Value', param_val{1});
            set(hS.start(2),'String', num2str(param_val{2},9));
            set(hS.step(2),'String', num2str(param_val{3},9));
            set(hS.type(3),'Value', param_val{4});

            %Update sweep control when sweep/no sweep
            if(param_val{1} == 1) %No sweep
                set(hS.type(3),'Visible','off');
                set(hS.type(4),'Visible','off');
                set(hS.start(1),'String', 'Value:');
                set(hS.step(1),'Visible','off');
                set(hS.step(2),'Visible','off');
                set(hS.end(1),'Visible','off');
                set(hS.end(2),'Visible','off');
            else %Sweep
                set(hS.type(3),'Visible','on');
                if(param_val{4} == 1)
                    set(hS.type(4),'Visible','off');
                else
                    set(hS.type(4),'Visible','on');
                end
                set(hS.start(1),'String', 'Start value:');
                set(hS.step(1),'Visible','on');
                set(hS.step(2),'Visible','on');
                set(hS.end(1),'Visible','on');
                set(hS.end(2),'Visible','on');
                
                [~,end_val] = cur_par.get_sweep_start_end();
                if(length(end_val) == 1)
                    set(hS.end(2),'String',num2str(end_val,3));  
                else
                    set(hS.end(2),'String',[num2str(min(end_val),3) '-'...
                                            num2str(max(end_val),3)]);  
                end
            end
        end
        
        %Get value of a variable/PC by its name and cycle number
        function values = get_PC_values(obj,PCname,ctPC)
            if(isnumeric(PCname))
                values = PCname;
            else
                idx = find(strcmp(PCname,obj.PC_types));
                if(isempty(idx))
                    values = [];
                    msgbox(['Variable "' PCname '" is used but not defined.']);
                    return;
                end

                if(isempty(ctPC)) %all cycles
                    values = obj.PC_data(:,idx);
                else %specific cycle
                    values = obj.PC_data(ctPC,idx);
                end
            end
        end 
        
        %Update PC/variable when a new value is given in tables
        function PC_update(obj,new_val)
            %Add new variable if not yet known
            idx_new = find(strcmp(new_val,obj.PC_types),1);
            if(isempty(idx_new)) %New PC variable
                obj.PC_types{end+1} = new_val;
                if(isempty(obj.PC_data))
                    obj.PC_data = 0; 
                else
                    obj.PC_data(:,end+1) = 0; 
                end
            end
            
            %Update weight for first PC or none left.
            if(isempty(obj.PC_weight) && ~isempty(obj.PC_data))
                obj.PC_weight = 1;
            elseif(~isempty(obj.PC_weight) && isempty(obj.PC_data))
                obj.PC_weight = [];
            end
            obj.PCPTS = length(obj.PC_weight);
        end 
        
        %Transient measurement mode: X axis modification
        %PROBLEM IF MORE THAN ONE MEASUREMENT DEVICE IN TRANSIENT MODE
        function trans_flag = set_transient_mode(obj,trans_flag)
            if(~trans_flag)
                obj.transient = 0;
                set(obj.hMETA.XPTS,'Enable','on');
            elseif(trans_flag && ~obj.transient)
                    answer = questdlg(['X axis sweep will be disabled to ' ...
                                       'accomodate measurement data. Continue?'],...
                                       'Sweep modification','Yes','No','Yes');
                    if(strcmpi(answer,'yes'))
                        obj.XPTS = 1;
                        obj.transient = 1;
                        set(obj.hMETA.XPTS,'String',1,'Enable','off');
                    else
                        obj.transient = 0;
                    end
            end
            
            trans_flag = obj.transient;
        end
    end
    
    %Measurements
    methods (Access = public)
        %Start (setup)/ stop experiment
        function playnstop(obj,flag)
            switch(flag)
                case 'run' %Experiment stop -> run -> stop
                    if(obj.run_flag == 0) %Experiment must be stopped to start setup
                        %Setup
                        [INST,MSRE] = obj.setup_all();

                        %Check that INST or MSRE are present
                        if(~(isempty(INST) && isempty(MSRE)))
                            %Run
                            full_data = obj.run_experiment(INST,MSRE);
                            
                            %Temporary save in any case
                            obj.temp_save(full_data);

                            %User save
                            obj.data_save(full_data);
                        else
                            obj.stop_all();
                        end
                    end

                case 'stop' %Experiment run -> stop at end of current point
                    if(obj.run_flag == 1) %Experiment running
                        obj.run_flag = 3;
                    end
                    if(obj.run_flag == -1) %Experiment blocked
                         obj.stop_all();
                    end
                    
                case 'stopatavg' %Experiment run -> stop at end of current averaging
                    if(obj.run_flag == 1) %Experiment running
                        obj.run_flag = 4;
                    end
                    
                case 'pause' %Experiment run -> pause
                    if(obj.run_flag == 1) %Experiment running
                        obj.run_flag = 5;
                    end
                    
                case 'unpause' %Experiment pause -> run
                    if(obj.run_flag == 5) %Experiment paused
                        obj.run_flag = 1;
                    end
            end   
        end
        
        %Setup all modules for experiment
        function [INST,MSRE] = setup_all(obj)
            obj.run_flag = 2; %Setting up
            
            %Change PLAY button and temporarily disable it
            set(obj.hPLAY,'String','STOP','BackgroundColor','red');
            set(obj.hPLAY,'Enable','off');
            obj.mLOG.update('Preparing ...',1);
            
            %Device for measurement
            idx = get(obj.hOPT(1),'Value');
            msre_dev = get(obj.hOPT(1),'String');
            if(~isempty(msre_dev))
                msre_dev = msre_dev(idx);
            end

            %Calling each modules to setup (.experiment_setup)
            INST = {}; %Container for instrument that will be used as parameters
            MSRE = {}; %Container for instrument that will be used for measurement
            total_flag = 1;
            xsw = {}; ysw = {}; %plot axis
            
            list_plot_str = {}; %plot lists (which measures are good)
            list_plot_id_str = {};
            list_plot_lbl_str = {};
            for ct = 1:length(obj.mods)
                temp = obj.mods{ct};

                %Check module is connected
                if(ismethod(temp,'connect') && isempty(temp.dev))
                    total_flag = 0;
                    obj.mLOG.update(['- ' temp.name ' could NOT setup (bad connect).'],0);
                    break;              
                end

                %Check all module parameters
                if(~temp.param_check('all'))
                    total_flag = 0;
                    obj.mLOG.update(['- ' temp.name ' could NOT setup (bad parameters).'],0);
                    break;
                end
                
                %Check all module settings
                if(~temp.check_all_settings)
                    total_flag = 0;
                    obj.mLOG.update(['- ' temp.name ' could NOT setup (bad settings).'],0);
                    break;
                end

                %Setup module
                if(ismethod(temp,'experiment_setup'))
                    ok_flag = temp.experiment_setup();
                else
                    ok_flag = -1;
                end

                if(ok_flag == 1) %Normal instrument
                    %Add module to INSTruments
                    INST{end+1} = temp; %#ok<AGROW>

                    %Add module to MeaSuRemEnts if necessary
                    if(any(strcmp(msre_dev,temp.ID)))
                        %Update list of plots
                        temp_msre_flag = 0;
                        for ctMeas = 1:numel(temp.measures)
                            cur_meas = temp.measures{ctMeas};
                            if(cur_meas.state)
                                temp_msre_flag = 1;
                                list_plot_str{end+1} = cur_meas.name; %#ok<AGROW>
                                list_plot_id_str{end+1} = temp.ID; %#ok<AGROW>
                                list_plot_lbl_str{end+1} = [temp.ID ' - ' cur_meas.label]; %#ok<AGROW>
                                if(~obj.transient)
                                    cur_meas.data = nan*ones(obj.XPTS,obj.YPTS);
                                else
                                    cur_meas.data = nan*ones(length(cur_meas.transient_axis.vals),obj.YPTS);
                                end
                            end
                        end

                        %If at least one measure is state on
                        if(temp_msre_flag)
                            MSRE{end+1} = temp; %#ok<AGROW>
                        end
                    end
                    
                    obj.mLOG.update(['- ' temp.name ' is setup.'],0);
                elseif(ok_flag == 0)
                    total_flag = 0;
                    obj.mLOG.update(['- ' temp.name ' could NOT setup.'],0);
                    break;
                end
                
                %Create axis for plot
                %1 = normal instrument, 2 = only add for plotting
                if(ok_flag == 1 || ok_flag == 2)
                    for ctPAR = 1:numel(temp.params)
                        cur_par = temp.params{ctPAR};
                        if(isa(cur_par,'ParameterClass'))
                            if(cur_par.param{1} == 2) %X
                                xsw{end+1} = cur_par; %#ok<AGROW>
                            elseif(cur_par.param{1} == 3) %Y
                                ysw{end+1} = cur_par; %#ok<AGROW>
                            end
                        end
                    end
                end
            end
            
            %Update plot measure list
            if(~isempty(list_plot_lbl_str))
                set(obj.hPLOT(4),'String',list_plot_lbl_str,'Value',1);
                if(length(list_plot_lbl_str) == 1)
                    set(obj.hPLOT(5),'String',list_plot_lbl_str,'Value',1);
                else
                    set(obj.hPLOT(5),'String',list_plot_lbl_str,'Value',2);
                end
            else
                set(obj.hPLOT(4),'String',' ','Value',1);
                set(obj.hPLOT(5),'String',' ','Value',1);
            end

            %If not all setup passed
            if(~total_flag)
                pause(2);
                INST = {};
                MSRE = {};
                
                obj.stop_all();
                return;
            end
            
            %Check for transient axis
            if(obj.transient)
                for ctMSRE = 1:length(MSRE)
                    for ctMeas = 1:numel(MSRE{ctMSRE}.measures)
                        meas_axis = MSRE{ctMSRE}.measures{ctMeas}.transient_axis;
                        if(~isempty(meas_axis.vals))
                            xsw{end+1} = meas_axis; %#ok<AGROW>
                        end
                    end
                end
            end

            %In case dummy axis (X or Y pts > 1 yet no parameter sweped)
            if((obj.XPTS > 1 || obj.transient) && isempty(xsw))
                dummy_mod.MAIN = obj;
                dummy_par = ParameterClass(dummy_mod,'','Point',{2 1 1 1},[],[]);
                dummy_par.create_sweep_vals();
                xsw{1} = dummy_par;
            end
            
            if(obj.YPTS > 1 && isempty(ysw))
                dummy_mod.MAIN = obj;
                dummy_par = ParameterClass(dummy_mod,'','Point',{3 1 1 1},[],[]);
                dummy_par.create_sweep_vals();
                ysw{1} = dummy_par;
            end    
            
            %Setup plot window (NOT GOOD FOR MORE THAN ONE SWEEP PER AXIS)
            set(get(obj.hPLOT(3),'Xlabel'),'String','');
            set(get(obj.hPLOT(3),'Ylabel'),'String','');
            
            if(~isempty(MSRE))
                obj.current_plot{1} = {list_plot_id_str{1} list_plot_str{1}};
                if(length(list_plot_id_str) == 1)
                    obj.current_plot{2} = {list_plot_id_str{1} list_plot_str{1}};
                else
                    obj.current_plot{2} = {list_plot_id_str{2} list_plot_str{2}};
                end
            else
                obj.current_plot = cell(2,1);
            end

            %Update axis
            if((obj.XPTS > 1 || obj.transient) && obj.YPTS > 1 && ...
                ~isempty(xsw) && ~isempty(ysw)) %2D map
                obj.hPLOT(1) = imagesc(xsw{1}.vals(:,1),ysw{1}.vals(:,1),...
                    nan*ones(length(ysw{1}.vals(:,1)),length(xsw{1}.vals(:,1))),...
                    'Parent',obj.hPLOT(3));

                set(get(obj.hPLOT(3),'Xlabel'),'String',xsw{end}.label,...
                    'FontUnits','Normalized','FontSize',0.07);
                set(get(obj.hPLOT(3),'Ylabel'),'String',ysw{end}.label,...
                    'FontUnits','Normalized','FontSize',0.07);
                set(obj.hPLOT(3),'YDir','normal');
                colorbar('peer',get(obj.hPLOT(1),'Parent'));

            elseif((obj.XPTS > 1 || obj.transient) && ~isempty(xsw)) %X sweep  
                obj.hPLOT(1:2) = plot(xsw{1}.vals(:,1),nan*ones(length(xsw{1}.vals(:,1)),1),'.-r',...
                                      xsw{1}.vals(:,1),nan*ones(length(xsw{1}.vals(:,1)),1),'.-b','Parent',obj.hPLOT(3));

                set(get(obj.hPLOT(3),'Xlabel'),'String',xsw{end}.label,...
                    'FontUnits','Normalized','FontSize',0.07);

            elseif(obj.YPTS > 1 && ~isempty(ysw)) %Ysweep
                obj.hPLOT(1:2) = plot(ysw{1}.vals(:,1),nan*ones(length(ysw{1}.vals(:,1)),1),'.-r',...
                                      ysw{2}.vals(:,1),nan*ones(length(ysw{2}.vals(:,1)),1),'.-b',...
                                    'Parent',obj.hPLOT(3));
                set(get(obj.hPLOT(3),'Xlabel'),'String',ysw{end}.label,...
                    'FontUnits','Normalized','FontSize',0.07);
            end
            
            %Save current configuration
            %This is important so that if changes are made to settings
            %during the experiment run, the actual experiment settings are
            %unchanged.
            obj.data2save([obj.root_path 'GUI functions' filesep 'Internal' filesep 'TempConfig.mat'],0);
            
            %Reset all waitbar
            obj.hSTATUS{1}.range = [0 obj.XPTS*obj.YPTS]; obj.hSTATUS{1}.percent = 0;
            obj.hSTATUS{2}.range = [0 obj.AVG]; obj.hSTATUS{2}.percent = 0;
            obj.estimate_remaining_time(0,1,1);
            
            %Enable STOP button
            set(obj.hPLAY,'Enable','on');
            
            %Wait briefly before running
            pause(1);
            obj.mLOG.close;
        end
        
        %THE experiment function (run the actual x,y,pc,avg,... loop)
        %INST = instrument to set parameters, MSRE = instrument for measure
        %[full_data_name,full_data] if MAIN.full_save_flag = 1 otherwise empty
        function full_data = run_experiment(obj,INST,MSRE)
            full_data.name = []; full_data.data = [];
            
            if(~(isempty(INST) && isempty(MSRE)))
                obj.run_flag = 1; %Running now
                exp_run_time = tic;
                obj.LOG_DEBUG.update(sprintf('%gms: \t Starting Experiment', toc(exp_run_time)*1000),0,1);
            else
                return;
            end
            
            %Prepare sweep axis
            %Y before X here so that actually first X sweep than Y sweep in loop
            %HOW TO MIX STOCHASTIC WITH AWG CLASS MULTI-LOADING
            axisXY = allcomb(1:obj.YPTS,1:obj.XPTS); 

            %Find measure channel to use
            MSRElist = {};
            for ctMdev = 1:length(MSRE)
                for ctMchan = 1:numel(MSRE{ctMdev}.measures)
                    if(MSRE{ctMdev}.measures{ctMchan}.state)
                        MSRElist{end+1} = MSRE{ctMdev}.measures{ctMchan}; %#ok<AGROW>
                    end
                end
            end
            
            %Prepare data storage variable
            cur_data = cell(length(MSRElist),obj.PCPTS);
            for ctMeas = 1:length(MSRElist)
                for ctPC = 1:obj.PCPTS
                    cur_data{ctMeas,ctPC} = 0;
                end
            end
            
            %Prepare full data storage (SHOULD CHECK MEMORY)
            if(get(obj.hSAVE(3),'Value'))
                full_data.data = cell(length(MSRElist),1);
                full_data.name = cell(length(MSRElist),1);
                for ctMeas = 1:length(MSRElist)
                    full_data.data{ctMeas} = nan*ones(size(MSRElist{ctMeas}.data,1),...
                                                obj.YPTS,obj.PCPTS,obj.SPP,obj.AVG);
                    full_data.name{ctMeas} = MSRElist{ctMeas}.name;
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%% MAIN EXPERIMENT LOOP %%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            run = 1;
            try
            while(run) 
                for ctMeas = 1:length(MSRElist)
                    MSRElist{ctMeas}.data(:) = nan; %#ok<AGROW>
                end
                if(~strcmp(obj.run_mode,'Continuous run'))
                    run = 0;
                end
                
                totalPCweight = sum(abs(obj.PC_weight));
                norm = obj.PC_weight/obj.SPP/totalPCweight/obj.AVG;
                
                for ctAVG = 1:obj.AVG
                    obj.hSTATUS{2}.pvalue = ctAVG;

                    %Recreate sweep axis every avg if stoch is on
                    %PREVENT STOCH WHEN MANY LOAD AWG
                    if(obj.STSW)
                        axisXY = axisXY(randperm(obj.XPTS*obj.YPTS),:);
                    end

                    newXY = [0 0 0];
                    for ctXY = 1:obj.XPTS*obj.YPTS
                        obj.hSTATUS{1}.pvalue = ctXY;
                        obj.estimate_remaining_time(toc(exp_run_time),ctXY,ctAVG);

                        %Phase cycling
                        for ctPC = 1:obj.PCPTS
                            %Check which sweep type was done
                            oldXY = newXY;
                            newXY = [axisXY(ctXY,[2 1]) ctPC]; %reorder to X,Y,PC
                            sweep_type = find(newXY ~= oldXY);
                            obj.LOG_DEBUG.update(sprintf(...
                                '%gms: \t Current Point:  AVG:%i: X:%i, Y:%i, PC:%i',...
                                toc(exp_run_time)*1000,ctAVG,newXY(1),newXY(2),newXY(3)),0,2);
                            
                            %Set new parameters
                            obj.LOG_DEBUG.update(sprintf('%gms: \t Setting next parameters...', toc(exp_run_time)*1000),0,3);
                            for ctINST = 1:length(INST)
                                ok_flag = INST{ctINST}.experiment_next(sweep_type,newXY); %#ok<FNDSB>

                                if(~ok_flag)
                                    obj.mLOG.update(['ERROR WHILE TRYING TO SWEEP ' ...
                                        INST{ctINST}.name],0);

                                    obj.stop_all();
                                    return;
                                end
                            end
                            obj.LOG_DEBUG.update(sprintf('%gms: \t ... DONE', toc(exp_run_time)*1000),0,3);

                            %Measurements
                            for ctSPP = 1:obj.SPP
                                tShot = tic;
                                %Update current experiment position
                                obj.cur_exp_pos = [ctAVG newXY ctSPP];
                                % obj.LOG_DEBUG.update(sprintf('%gms: \t Current SPP %i', toc(exp_run_time)*1000, ctSPP),0,3);
                                
                                %Setup measurement devices
                                % obj.LOG_DEBUG.update(sprintf('%gms: \t experiment_setread...', toc(exp_run_time)*1000),0,3);
                                for ctMSRE = 1:length(MSRE)
                                    MSRE{ctMSRE}.experiment_setread();
                                end
                                % obj.LOG_DEBUG.update(sprintf('%gms: \t ... DONE', toc(exp_run_time)*1000),0,3);
                                
                                %Trigger instruments
                                % obj.LOG_DEBUG.update(sprintf('%gms: \t experiment_trigger...', toc(exp_run_time)*1000),0,3);
                                for ctINST = 1:length(INST)
                                    INST{ctINST}.experiment_trigger();
                                end
                                % obj.LOG_DEBUG.update(sprintf('%gms: \t ... DONE', toc(exp_run_time)*1000),0,3);
                                

                                %Measure
                                 for ctMeas = 1:length(MSRElist)
                                    % fetch data
                                    % obj.LOG_DEBUG.update(sprintf('%gms: \t Fetch data (%s, %s)', ...
                                    %    toc(exp_run_time)*1000, MSRElist{ctMeas}.mod.ID, MSRElist{ctMeas}.name),0,3);
                                    new_data = MSRElist{ctMeas}.get_data(); 
                                    cur_data{ctMeas,ctPC} = cur_data{ctMeas,ctPC}  + new_data;
                                    
                                    if(~isempty(full_data.data))
                                        if(~obj.transient)
                                            full_data.data{ctMeas}(newXY(1),newXY(2),ctPC,ctSPP,ctAVG) = new_data;
                                        else
                                            full_data.data{ctMeas}(:,newXY(2),ctPC,ctSPP,ctAVG) = new_data;
                                        end
                                    end
                                    % obj.LOG_DEBUG.update(sprintf('%gms: \t ... DONE', toc(exp_run_time)*1000),0,3);
                                
                                 end

                                %Shot repetition time
                                %When run by computer, there is a minimum delay
                                pause(obj.SRT-toc(tShot));
                                
                                obj.LOG_DEBUG.update(sprintf('%gms: \t Time for shot: %gms', toc(exp_run_time)*1000, toc(tShot)*1000),0,2);
                                obj.LOG_DEBUG.update(sprintf('%gms: \t Wait: %gms', toc(exp_run_time)*1000, (obj.SRT-toc(tShot))*1000),0,3);
                                
                            end
                        end
                        
                        %Add current data
                        obj.LOG_DEBUG.update(sprintf('%gms: \t Add current data', ...
                                        toc(exp_run_time)*1000),0,3);
                                    
                        for ctMeas = 1:length(MSRElist)
                            sum_data = 0;
                            for ctPC = 1:obj.PCPTS
                                sum_data = sum_data + norm(ctPC)*cur_data{ctMeas,ctPC};                                
                                cur_data{ctMeas,ctPC} = 0;
                            end
                            
                            if(~obj.transient)
                                if isnan(MSRElist{ctMeas}.data(newXY(1),newXY(2)))
                                    MSRElist{ctMeas}.data(newXY(1),newXY(2)) = 0;
                                end
                                MSRElist{ctMeas}.data(newXY(1),newXY(2)) = ...
                                    MSRElist{ctMeas}.data(newXY(1),newXY(2)) + sum_data; %#ok<AGROW>
                            else % If we have a transient axis
                                % The following is an ugly hack if the
                                % Oscilloscope returns not the same number of points after triggering
                                % as it said it would deliver during setup_all
                                setupAll_size = size(MSRElist{ctMeas}.data(:,newXY(2)));
                                newsize = size(sum_data);
                                % resize data array
                                if any(setupAll_size ~= newsize) && ctAVG==1 ...
                                        && ctXY == 1
                                    MSRElist{ctMeas}.data = nan*ones(length(MSRElist{ctMeas}.transient_axis.vals),obj.YPTS);
                                    
                                end
                                
                                % convert the nan value to zero if this is
                                % the first data point (can not sum spp's with
                                % nan as start
                                if any(isnan(MSRElist{ctMeas}.data(newXY(1),newXY(2))))
                                    MSRElist{ctMeas}.data(:,newXY(2)) = 0;
                                end
                                
                                %sum SPP
                                MSRElist{ctMeas}.data(:,newXY(2)) = ...
                                    MSRElist{ctMeas}.data(:,newXY(2)) + sum_data;
                            end
                        end
                        obj.LOG_DEBUG.update(sprintf('%gms: \t ... DONE', toc(exp_run_time)*1000),0,3);
                                
                        
                        obj.LOG_DEBUG.update(sprintf('%gms: \t Check flags', toc(exp_run_time)*1000),0,3);
                        %Stop flag
                        if(obj.run_flag == 3)
                            obj.stop_all();
                            return;
                        end
                        %Pause flag
                        if(obj.run_flag == 5)
                            waitfor(msgbox('Experiment is paused. Press OK to resume.','Pause','non-modal'));
                            obj.run_flag = 1;
                        end
                                
                        %Update plot
                        obj.LOG_DEBUG.update(sprintf('%gms: \t Update plot', toc(exp_run_time)*1000),0,3);
                        obj.update_plot;
                        
                        obj.LOG_DEBUG.update(sprintf('%gms: \t ... DONE', toc(exp_run_time)*1000),0,3);
                        
                        
                    end
                    
                    if(obj.run_flag == 4)
                        obj.stop_all();
                        return;
                    end
                end
            end
            catch me
                disp(['Stopping experiment (error): ' me.message]);
                obj.stop_all();
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
            %End of experiment
            obj.stop_all();
        end

        %Experiment stop/end
        function stop_all(obj)
            obj.mLOG.update('Stopping experiment ...',0);
            set(obj.hPLAY,'String','PLAY','BackgroundColor','green','enable','off');

            %Stop each modules
            for ct = 1:length(obj.mods)
                if(ismethod(obj.mods{ct},'experiment_stop'))
                    ok_flag = obj.mods{ct}.experiment_stop();
                else
                    ok_flag = -1;
                end

                if(ok_flag == 0)                   
                    obj.mLOG.update(['- ' obj.mods{ct}.name ' could not be stopped.'],0);
                end
            end

            %Run stopped
            obj.run_flag = 0;
            
            %Finishing...
            pause(1);
            obj.mLOG.close;

            %Turn on PLAY button
            set(obj.hPLAY,'enable','on');
        end
        
        %Update plot
        function update_plot(obj)
            t1 = tic;
            for ct = 1:2
                if(~isempty(obj.current_plot{ct}))
                    data = obj.get_mod(obj.current_plot{ct}{1}) ...
                              .get_measure(obj.current_plot{ct}{2}).data;
                    
                    obj.LOG_DEBUG.update(sprintf('%gms:\t Fetch data',toc(t1)*1000),0,4)
                    %Data calibration if necessary      
                    if(obj.dataCal.status && ~isempty(obj.dataCal.file))
                        data = obj.dataCal.file(get(obj.hPLOT(1),'XData').',data);
                    end
                    obj.LOG_DEBUG.update(sprintf('%gms:\t Data calibration',toc(t1)*1000),0,4)
                    % If x-dimension of data is different form length of
                    % XData then the MSO transient axis changed size  on the
                    % first trigger
                    changeXaxis = 0;
                    [size_data,~] = size(data);
                    size_xaxis = length(get(obj.hPLOT(1),'XData'));
                    if  (size_data(1) ~= size_xaxis) && obj.transient
                        MSO = obj.get_mods_from_name('MSO');
                        new_transient_axis = MSO{1}.measures{1}.transient_axis.vals;
                        changeXaxis = 1;
                    end
                    
                    obj.LOG_DEBUG.update(sprintf('%gms:\t Check if X-axis changed size',toc(t1)*1000),0,4)
                    %Update plot
                    if(ct == 1 && (obj.XPTS > 1 || obj.transient) && obj.YPTS > 1) %2D plot
                        if changeXaxis
                            set(obj.hPLOT(1),'XData',new_transient_axis','CData',data.');
                        else
                            set(obj.hPLOT(1),'CData',data.');
                        end
                    elseif(~((obj.XPTS > 1 || obj.transient) && obj.YPTS > 1)) %1D plot
                        if changeXaxis
                            set(obj.hPLOT(1),'XData',new_transient_axis','YData',data.');
                            set(obj.hPLOT(2),'XData',new_transient_axis','YData',data.');
                        else
                            set(obj.hPLOT(ct),'YData',data.');
                        end
                    end
                    
                    obj.LOG_DEBUG.update(sprintf('%gms:\t Update plot',toc(t1)*1000),0,4)
                    if(obj.plot_autoScale)
                        axis(obj.hPLOT(3),'tight');
                    end
                end
            end
            drawnow;
            obj.LOG_DEBUG.update(sprintf('%gms:\t drawnow',toc(t1)*1000),0,4)
        end
        
        %Estimate experiment remaining time
        function estimate_remaining_time(obj,run_time,ctXY,ctAVG)
            if(run_time == 0)
                set(obj.hSTATUS{3},'String','Time remaining: ');
            else
                remain_time = run_time*((obj.XPTS*obj.YPTS*obj.AVG)/...
                                        (ctXY+obj.XPTS*obj.YPTS*(ctAVG-1))-1);
                if(remain_time <= 5*60) %Less than 5 mn remaining
                    minutes = floor(remain_time/60);
                    seconds = remain_time - 60*minutes;
                    show_time = [int2str(minutes) ' mn ' int2str(seconds) ' s'];
                elseif(remain_time <= 5*3600)
                    hours = floor(remain_time/3600);
                    minutes = (remain_time - 3600*hours)/60;
                    show_time = [int2str(hours) ' hrs ' int2str(minutes) ' mn'];
                else
                    show_time = [int2str(remain_time/3600) ' hrs'];
                end

                set(obj.hSTATUS{3},'String',['Time remaining: ' show_time]);
            end
        end
        
        %Save data
        function data_save(obj,full_data,varargin)
            pathname = get(obj.hSAVE(1),'String');
            if(~strcmp(pathname(end),filesep))
                pathname = [pathname filesep];
            end

            if(~isempty(varargin))
                full_path = varargin{1};
                
            elseif(get(obj.hSAVE(2),'Value')) %autosave (based on Cheuk's file)
                %Create a folder for the current day
                pathname = [pathname datestr(now,'yyyy-mm-dd') filesep];
                if (exist(pathname,'dir')==0)
                    %the folder doesn't exist, create it
                    mkdir(pathname);
                end

                listing = dir([pathname '*.mat']);
                if(~isempty(listing))
                    default_entry = {listing(end).name(5:end-4)};
                else
                    default_entry = {''};
                end

                comment = inputdlg('Enter a filename:','',[1 max(20,length(default_entry{1}))],default_entry);
                if(~isempty(comment))
                    filename = [sprintf('%03i',length(listing)+1) '_' comment{1} '.mat'];
                else
                    return;
                end        

                full_path = [pathname filename];
                
            else
                %Create/Open output file
                [filename, pathname] = uiputfile('*.mat','Save as',pathname);
                if(filename ~= 0)
                    full_path = [pathname filename];
                else
                    return;
                end
            end
            
            if(isempty(full_data.data))
                obj.data2save(full_path,1);
            else
                obj.data2save(full_path,1,full_data,'full_data');
            end
        end

        %Temporary data save, keep N last data files
        function temp_save(obj,full_data)
            pathname = [obj.root_path 'Temp' filesep];
            listing = dir([pathname '*.mat']);

            N = 10; %Number of data file to keep

            %Push old data pile
            if(length(listing) >= N)
                for ct = 1:length(listing)
                    save_pos = str2double(listing(ct).name(1:3)); %check file number at beginning
                    if(save_pos == 1) %delete oldest file
                        delete([pathname listing(ct).name]);
                    else %rename all others
                        new_name = listing(ct).name;
                        new_name(1:3) = sprintf('%03i',save_pos-1);
                        movefile([pathname listing(ct).name], [pathname new_name]);
                    end
                end
            end

            %Save new_data
            filename = [sprintf('%03i',min(N,length(listing)+1)) '_temp.mat'];
            
            obj.data2save([pathname filename],1,full_data,'full_data'); 
        end
    end
    
    %Parameter check (metadata)
    methods (Access = public)
        function flag = param_check(obj,param,varargin)
            flag = 1;
            
            %'all' to check all metadata
            if(strcmpi(param,'all'))
                for ct = 1:length(obj.metadata_types)
                    flag = flag && obj.param_check(obj.metadata_types{ct});
                end
                return;
            end
            
            %Retrieve value to check
            if(isempty(varargin)) %recheck current_value
                value = eval(['obj.' param]);
            else %check new value given
                value = varargin{1};
            end

            %Check
            switch(param)
                case 'SRT'
                    flag = obj.SRT_check(value);
                case 'AVG'
                    flag = obj.AVG_check(value);
                case 'SPP'
                    flag = obj.SPP_check(value);
                case 'XPTS'
                    flag = obj.XPTS_check(value);
                case 'YPTS'
                    flag = obj.YPTS_check(value);
            end
        end
        
        function flag = SRT_check(~,value)
            flag = 1;
            
            if(value <= 0)
                flag = 0;
                msgbox('Shot Repetition Time must be a value > 0.');
            end
            
        end
        
        function flag = AVG_check(~,value)
            flag = 1;
            
            if(round(value)~=value || value < 1)
                flag = 0;
                msgbox('Number of average must be an integer > 0.');
            end            
        end
        
        function flag = SPP_check(~,value)
            flag = 1;
            
            if(round(value)~=value || value < 1)
                flag = 0;
                msgbox('Number of average must be an integer > 0.');
            end      
        end
        
        function flag = XPTS_check(~,value)
            flag = 1;

            if(round(value)~=value || value < 1)
                flag = 0;
                msgbox('X axis points must be an integer > 0.');
            end
        end
        
        function flag = YPTS_check(~,value)
            flag = 1;
            
            if(round(value)~=value || value < 1)
                flag = 0;
                msgbox('Y axis points must be an integer > 0.');
            end
        end
    end
end


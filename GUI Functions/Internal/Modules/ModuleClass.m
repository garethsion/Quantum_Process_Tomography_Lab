classdef ModuleClass < handle
    %ModuleClass is the primary parent class for a new module
    %It integrates all important methods and properties, such as all the
    %parameters, settings, measurements.
    
    %Main ModuleClass parameters
    properties (Access = public)
        name %Module name for labels
        ID %Module identification
        description %Description for the module (optional)
        
        %Handle for MAIN
        MAIN
        
        %For modules in group
        parent_mod = [];
        child_mods = {};
        
        %Handles
        hPanel %Panel handle
        
        %Module settings
        settings = {}; %SettingClass
        
        %Module parameters (~sweep parameters)
        params = {}; %ParameterClass, careful: this can be multidimensional
                     %So always use "numel" for for loops
                     
        %Module measurements
        measures = {}; %MeasureClass
    end
    
    %Module specific function handles (mostly for PG/AWG)
    properties (Access = public)
        window_resize %Resize function (for tables mainly)
        metadataEdit %Metadata edit event function
        sweepControlsEdit %Sweep control edit event function
        PCwindowClosing %Variable/Phase cycling window closing event      
        
        user_update_all %For update load, specific additional user function
        user_params_load %load function
    end
    
    %Connection parameters
    properties (Access = public)
        %Connection
        dev = []; %Handle to device for communication
        INST_brand = ''; %agilent, hp ... (see help visa)
        INST = {{'', '', ''}}; %{Instrument internal name, connection type, address}
        INSTnumber = 1; %Current instrument selection
        hINSTnumber = []; %Current instrument selection handle for GUI
        
        hConnect = []; %Connect button handle
    end
    
    %Class methods
    methods (Access = public)
        %Create a new module (add properties to module subclass)
        function [obj] = ModuleClass()
        end
        
        %Connection wrapper
        function create_device(obj)
            if(isempty(obj.dev))
                try
                    device_number = obj.INSTnumber;    
                    INname = obj.INST{device_number}{1};
                    INtype = obj.INST{device_number}{2};
                    INaddress = obj.INST{device_number}{3};
                    switch(lower(INtype))
                        case 'gpibio'
                            temp_dev = GPIBIOwrapper(INaddress,INname);

                        case 'visa'
                            temp_dev = VISAwrapper(obj.INST_brand,INaddress,INname,obj.ID);

                        case 'user'
                            temp_dev = eval(INaddress);
                    end
                    if(~isempty(temp_dev.devObj) || strcmpi(INtype,'user'))
                        obj.dev = temp_dev;
                    else
                        obj.dev = [];
                    end
                catch errorMsg
                    disp(errorMsg.message);
                end
            end
        end
    end
    
    %GUI methods
    methods (Access = public)
        %Wrapper for uicontrol in the GIC environment
        function h = ModuleUIC(obj,style,text,position,varargin)
            h = uicontrol('Parent',obj.hPanel,'Style',style,'String',text,...
                          'Units','Normalized','FontUnits','Normalized',...
                          'Position',position,varargin{:});
        end
        
        %Add help button
        function UI_add_help(obj,help_text)
            obj.ModuleUIC('push','?',[0.976 0.955 0.02 0.04],....
                'Units','normalized','FontUnits','Normalized','FontSize',0.6,...
                'Callback',{@help_dialog obj help_text});
            function help_dialog(~,~,obj,text)
                pre_text = ['\bf**** ' obj.name ' ****\rm'];
                if(~iscell(text))
                    text = {text};
                end
                CreateStruct.WindowStyle = 'modal';
                CreateStruct.Interpreter = 'tex';
                msgbox({pre_text '' text{:}},'Module help',CreateStruct);
            end
        end
        
        %Add connect button
        function UI_add_connect(obj)
            if(~(ismethod(obj,'connect') && ismethod(obj,'disconnect')))
                disp(['Connect button for module ' obj.name ' could not be ' ...
                      'added as (dis)connect functions were not defined']);
                return;
            end
            
            [textPos,inputPos] = ModuleUICPos(0.31,1);
            IDNs = cell(length(obj.INST),1);
            for ct = 1:length(obj.INST)
                IDNs{ct} = obj.INST{ct}{1};
            end
            obj.hINSTnumber = obj.ModuleUIC('popupmenu',IDNs,inputPos,'Value',obj.INSTnumber,...
                'FontSize',0.6,'Callback',{@update_INSTnumber obj});
            function update_INSTnumber(hobj,~,obj)
                obj.INSTnumber = get(hobj,'Value');
            end
            
            obj.hConnect = obj.ModuleUIC('push','Disconnected',textPos,...
                'Units','normalized', 'FontUnits','Normalized','FontSize',0.65,...
                'Callback',@(~,~) obj.ModuleConnect(),'BackgroundColor','red');
        end
        
        %Connection dialog
        function ModuleConnect(obj)
           type = get(obj.hConnect,'String');

            switch(type)
                case {'Disconnected' 'Could not connect'}
                    %Create wait dialog
                    log = LogClass('Measurement',0);
                    log.update('Connecting to instrument... (5s timeout)',0);

                    %Connect
                    set(obj.hConnect,'Enable','off');
                    obj.connect(); %#ok<MCNPN>
                    set(obj.hConnect,'Enable','on');

                    %Close wait dialog
                    log.close();
                    clear log;

                    if(~isempty(obj.dev))
                        %Button = green
                        set(obj.hConnect,'String','Connected','BackgroundColor','green');
                        set(obj.hINSTnumber,'Enable','off');
                    else
                        %Button = red
                        set(obj.hConnect,'String','Could not connect','BackgroundColor','red');
                        set(obj.hINSTnumber,'Enable','on');
                    end

                case 'Connected'
                    %Close connection
                    obj.disconnect(); %#ok<MCNPN>

                    set(obj.hConnect,'String','Disconnected','BackgroundColor','red');
                    set(obj.hINSTnumber,'Enable','on');
            end
        end
        
        %Add update button (send immediately all settings and all params start values)
        function UI_add_updateall(obj,varargin)
            [~,inputPos] = ModuleUICPos(0.6,4.17);
            obj.ModuleUIC('push','Update all',inputPos,'Callback',{@update_all obj varargin{:}}); %#ok<CCAT>
            function ok_flag = update_all(~,~,obj,varargin)
                ok_flag = obj.send_all_params(varargin{:});
                ok_flag = ok_flag && obj.send_all_settings(varargin{:});
            end
        end
        
        %Add module main panel
        function UI_add_mainpanel(obj)
            obj.hPanel = uipanel('Parent',obj.MAIN.hWIN,'Title','','Units','normalized',...
            'FontUnits','Normalized','Position',[0 0 1 0.77],'ForegroundColor',...
            'Blue','HighlightColor','Blue','Visible','off');
            uistack(obj.hPanel,'bottom');
        
            [~,inputPos] = ModuleUICPos(-0.25,3.9);
            inputPos(3) = 0.1;
            obj.ModuleUIC('edit','Description',inputPos,...
                'Units','normalized','FontUnits','Normalized','FontSize',0.6,...
                'Callback',{@set_description obj},'BackgroundColor',[1.0 0.95 0.8]); 
            function set_description(hobj,~,mod)
                mod.description = get(hobj,'String');
            end
        end
        
        %Add module sub-panel
        function hsubPanel = UI_add_subpanel(obj,title,varargin)
            if(length(varargin) == 1)
                position = varargin{1};
            else
                position = [0.005 varargin{1} 0.99 varargin{2}];
            end
            hsubPanel = uipanel('Parent',obj.hPanel,'Title',title,'FontSize',9,'Units','normalized',...
            'FontUnits','Normalized','Position',position,...
            'ForegroundColor','Blue','HighlightColor','Blue');
            uistack(hsubPanel,'down');
        end
    end
    
    %Parameter methods
    methods (Access = public)
        %Add a text+button for parameter 'param_str' at position, x,y
        function cur_par = UI_add_param(obj,param_str,x,y)
            [textPos, inputPos] = ModuleUICPos(x,y);
            
            [cur_par,idx] = obj.get_param(param_str);
            cur_par.hLabel = obj.ModuleUIC('text',[cur_par.label ':'],textPos,'FontSize',0.7); 
            
            cur_par.hText = obj.ModuleUIC('edit',num2str(cur_par.param{2}),...
                                inputPos,'Callback',{@obj.paramSelect idx},...
                                'BackgroundColor',[224 255 255]/255,'FontSize',0.6);
        end
        
        %Get parameter idx from name
        function [par_obj,idx] = get_param(obj,name)
            idx = [];
            for ct = 1:numel(obj.params)
                if(isa(obj.params{ct},'ParameterClass'))
                    if(strcmp(obj.params{ct}.name,name))
                        idx = ct;
                        par_obj = obj.params{ct};
                        return;
                    end
                end
            end
        end   
        
        %Global parameter check depending on:
        %'all': recheck all
        %'XPTS',value: check all parameters that sweep X for new Xpts val
        %'YPTS',value: check all parameters that sweep Y for new Ypts val
        %'PC','name',value: check parameters that are PC with 'name' for new val
        function flag = param_check(obj,type,varargin)
            flag = 1;
            
            switch(type)
                case 'all' %Check all parameters
                    for ctPAR = 1:numel(obj.params)
                        cur_par = obj.params{ctPAR};
                        if(isa(cur_par,'ParameterClass'))
                            flag = cur_par.param_sweep_check();
                        end
                        if(~flag)
                            return;
                        end
                    end
                    
                case 'XPTS' %Check all parameters that are sweped along X
                    XPTS = obj.MAIN.XPTS;
                    obj.MAIN.XPTS = varargin{1};
                    
                    for ctPAR = 1:numel(obj.params)
                        cur_par = obj.params{ctPAR};
                        if(isa(cur_par,'ParameterClass'))
                            if(cur_par.param{1} == 2) %X
                                flag = cur_par.param_sweep_check();
                                if(~flag)
                                    obj.MAIN.XPTS = XPTS;
                                    return;
                                end
                            end
                        end
                    end
                    
                    obj.MAIN.XPTS = XPTS;
                    
                case 'YPTS' %Check all parameters that are sweped along Y
                    YPTS = obj.MAIN.YPTS;
                    obj.MAIN.YPTS = varargin{1};
                    
                    for ctPAR = 1:numel(obj.params)
                        cur_par = obj.params{ctPAR};
                        if(isa(cur_par,'ParameterClass'))
                            if(cur_par.param{1} == 3) %Y
                                flag = cur_par.param_sweep_check();
                                if(~flag)
                                    obj.MAIN.YPTS = YPTS;
                                    return;
                                end
                            end
                        end
                    end
                    
                    obj.MAIN.YPTS = YPTS;
                    
                case 'PC' %Check all parameters that have the PC string
                    PC_str = varargin{1};
                    val = varargin{2};
                    
                    %Find PC in params
                    for ctPAR = 1:numel(obj.params)
                        cur_par = obj.params{ctPAR};
                        if(isa(cur_par,'ParameterClass'))
                            idx = find(strcmp(PC_str,cur_par.param)==1);
                            if(~isempty(idx))
                                flag = cur_par.param_sweep_check(idx,val);
                            end
                        end
                    end
            end
        end
        
        %Wrapper for msgbox that adds module name before text
        function msgbox(obj,text)
            cell_str = ['[' obj.name '] '];
            msgbox([cell_str text]);
        end
        
        %Callback function for when a parameter is selected
        function paramSelect(obj,~,~,cursorPos)
            %Save current selected parameter
            obj.MAIN.UserData = {obj.ID cursorPos};

            cur_par = obj.params{cursorPos};
            if(isa(cur_par,'ParameterClass'))
                %Value should only be modified via sweep control
                %If the parameter label was directly modified, put back to original
                cur_par.update_label();

                %Send values to sweep control
                obj.MAIN.value2sweepControls(cur_par);
            end
        end
        
        %Transfer params between a loaded module and the current one
        function std_params_load(obj,new_params)
            for ctPAR = 1:numel(new_params)
                if(isa(obj.params{ctPAR},'ParameterClass'))
                    if(strcmp(obj.params{ctPAR}.name,new_params{ctPAR}.name))
                        %Update params
                        obj.params{ctPAR}.param = new_params{ctPAR}.param;
                        obj.params{ctPAR}.state = new_params{ctPAR}.state;
                        obj.params{ctPAR}.sweep_fun = new_params{ctPAR}.sweep_fun;

                        %Update UI
                        obj.params{ctPAR}.update_label();
                        obj.params{ctPAR}.set_UIvisibility(new_params{ctPAR}.visibility);
                    end
                else
                    obj.params{ctPAR} = new_params{ctPAR};
                end
            end
        end
        
        %Send current parameters (start value) to instrument
        function ok_flag = send_all_params(obj,varargin)
            ok_flag = 1;
            if(~isempty(obj.dev))
                for ctPAR = 1:numel(obj.params)
                    cur_par = obj.params{ctPAR};
                    if(isa(cur_par,'ParameterClass'))
                        if(cur_par.state)
                            %Update sweep vals
                            cur_par.create_sweep_vals();
                            
                            %Send to instrument
                            cur_par.send(1,1);
                        end
                    end
                end

                if(~isempty(varargin) && strcmp(varargin{1},'no_check'))
                    ok_flag = 1;
                else
                    ok_flag = obj.dev.check;
                end
            end
        end
    end
    
    %Setting methods
    methods (Access = public)
        %Get setting idx from name
        function [set_obj,idx] = get_setting(obj,name)
            idx = [];
            set_obj = [];
            for ct = 1:numel(obj.settings)
                if(isa(obj.settings{ct},'SettingClass'))
                    if(strcmp(obj.settings{ct}.name,name))
                        idx = ct;
                        set_obj = obj.settings{ct};
                        return;
                    end
                end
            end
        end 
        
        %Add a text+button for a setting 'setting_str' at position, x,y
        function cur_set = UI_add_setting(obj,type,setting_str,x,y)
            [textPos, inputPos] = ModuleUICPos(x,y);

            cur_set = obj.get_setting(setting_str);
            
            setting_color =  [255 255 200]/255;
            
            switch(type)
                case 'edit'
                    text_flag = 1;
                    str_val = '';
                    color = setting_color;
                    
                case 'checkbox'
                    text_flag = 1;
                    str_val = '';
                    color = [.94 .94 .94]; %background color
                    
                case 'listbox'
                    text_flag = 1;
                    str_val = cur_set.list;
                    color = setting_color;
                    
                case 'popupmenu'
                    text_flag = 1;
                    str_val = cur_set.list;
                    color = setting_color;
                    
                case 'push'
                    text_flag = 0;
                    str_val = cur_set.label;
                    color = [.94 .94 .94]; %background color
            end
            
            if(text_flag)
                cur_set.hLabel = obj.ModuleUIC('text',[cur_set.label ':'],textPos,'FontSize',0.7);

                cur_set.hText = obj.ModuleUIC(type,str_val,inputPos,...
                                 'CallBack',@cur_set.update_val,...
                                 'BackgroundColor',color,'FontSize',0.6);
            else
                cur_set.hText = obj.ModuleUIC(type,str_val,textPos,...
                                 'CallBack',@cur_set.update_val,...
                                 'BackgroundColor',color,'FontSize',0.6);
            end
                          
            cur_set.update_label();
        end
        
        %Transfer settings between a loaded module and the current one
        function std_settings_load(obj,new_settings)
            for ctSET = 1:numel(new_settings)
                if(isa(obj.settings{ctSET},'SettingClass'))
                    if(strcmp(obj.settings{ctSET}.name,new_settings{ctSET}.name))
                        %Update settings
                        obj.settings{ctSET}.val = new_settings{ctSET}.val;
                        obj.settings{ctSET}.state = new_settings{ctSET}.state;

                        %Update UI
                        obj.settings{ctSET}.update_label();
                        obj.settings{ctSET}.set_UIvisibility(new_settings{ctSET}.visibility);
                    end
                else
                    obj.settings{ctSET} = new_settings{ctSET};
                end
            end
        end
        
        %Initialize all settings
        function ok_flag = send_all_settings(obj,varargin)
            ok_flag = 1;
            if(~isempty(obj.dev))
                for ct = 1:numel(obj.settings)
                    if(obj.settings{ct}.state)
                        % display(obj.settings{ct}.name)
                        obj.settings{ct}.send();
                        % obj.dev.check(obj.settings{ct}.name); 
                    end
                end
                if(~isempty(obj.user_update_all))
                    obj.user_update_all();
                end
                
                if(~isempty(varargin) && strcmp(varargin{1},'no_check'))
                    ok_flag = 1;
                else
                    ok_flag = obj.dev.check('All settings check.');
                end
            end
        end
        
        %Setting check
        function ok_flag = check_all_settings(obj)
            ok_flag = 1;
            for ct = 1:numel(obj.settings)
                if(~isempty(obj.settings{ct}.check) && obj.settings{ct}.state)
                    %display(obj.settings{ct}.name)
                    val = obj.settings{ct}.val;
                    ok_flag = ok_flag && obj.settings{ct}.check(val);
                end
            end
        end
    end
    
    %Measurement methods
    methods (Access = public)
        %Get measurement idx from name
        function cur_obj = get_measure(obj,name)
            cur_obj = [];
            for ct = 1:numel(obj.measures)
                if(strcmp(obj.measures{ct}.name,name))
                    cur_obj = obj.measures{ct};
                    return;
                end
            end
        end     
        
        %Transfer params between a loaded module and the current one
        function std_measures_load(obj,new_measures)
            for ctMSRE = 1:numel(new_measures)
                try
                if(isa(obj.measures{ctMSRE},'MeasureClass'))
                    if(strcmp(obj.measures{ctMSRE}.name,new_measures{ctMSRE}.name))
                        %Update params
                        obj.measures{ctMSRE}.state = new_measures{ctMSRE}.state;

                        %Update UI
%                         obj.measures{ctMSRE}.update_label();
                    end
                else
                    obj.measures{ctMSRE} = new_measures{ctMSRE};
                end
                end
            end
        end
    end        
    
    %Experiment toolbox (standard function to use)
    methods (Access = public)
        %Setup the experiment
        function ok_flag = tool_exp_setup(obj,varargin)
            ok_flag = 0;
            if(~isempty(obj.dev))        
                %Set settings
                ok_flag = obj.send_all_settings(varargin{:});
                if(~ok_flag)
                    return;
                end
                
                %Setup sweep axis & Set params to initial values
                ok_flag = obj.send_all_params(varargin{:});
                if(~ok_flag)
                    return;
                end
            end
        end
        
        %During experiment, sweep to next point
        %pos = [X Y PC] index value, type = which pos is changed
        %varargin = optional 'no_check' flag
        function ok_flag = tool_exp_next(obj,type,pos,varargin)
            %Use a try-catch sequence to easily stop experiment 
            %if there is some trouble
            try 
                %Sweep
                for ct = 1:numel(obj.params)
                    cur_par = obj.params{ct};
                    
                    %In send function, if no sweep, input 1 doesn't matter
                    %                  if no PC, input 2 doesn't matter
                    if((any(type == 1) || any(type == 3)) && cur_par.param{1} == 2) %X or PC
                        cur_par.send(pos(1),pos(3));
                    elseif((any(type == 2) || any(type == 3)) && cur_par.param{1} == 3) %Y or PC
                        cur_par.send(pos(2),pos(3));
                    end
                end
                
                if(~isempty(varargin) && strcmp(varargin{1},'no_check'))
                    ok_flag = 1;
                else
                    ok_flag = obj.dev.check;
                end
                
            catch ME
                ok_flag = 0;
                report = getReport(ME);
                disp(report);
            end
        end
    end
end


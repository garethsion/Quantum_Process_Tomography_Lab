classdef SettingClass < handle
    %This class helps define specific settings
    
    properties (Access = public)
        %Labels/Texts
        name  %Setting name
        label %Label for text
        hText = []; %Handle to UI text/list
        hLabel = [] %Handle to UI label
        hUpdate = []; %Handle to UI update button if used
        
        %State
        state = 1 % State status, if active setting is send to instrument 
        visibility = 1;
        
        %Function handles
        check %Handle to setting_check function
        send_fun %Handle to function to send value to device
        
        %Setting value
        list %List of value/choices
        val %Value,index or string depending on choice
        
        %Parent module
        mod
    end
    
    %Main methods
    methods (Access = public)
        %Create a new parameter
        function obj = SettingClass(mod,name,label,val,check,send_fun,varargin)
            obj.mod = mod;
            obj.name = name;
            obj.label = label;
            obj.val = val;
            obj.check = check;
            obj.send_fun = send_fun;
            
            if(~isempty(varargin))
                obj.list = varargin{1};
            end
        end
           
        %Send value to instrument
        function send(obj)
            if(~isempty(obj.mod.dev) && ~isempty(obj.send_fun) && obj.state)
                obj.send_fun(obj.val);
            end
        end
        
        %Set value from UI
        function update_val(obj,~,~)
            type = get(obj.hText,'Style');
            switch(type)
                case 'edit'                    
                    temp = get(obj.hText,'String');
                    if(~isnan(str2double(temp)))
                        temp = str2double(temp);
                    end
                    
                case 'listbox'
                    temp = get(obj.hText,'Value');
                    %Here we just save index because listbox can take more
                    %than one value
                    
                case 'popupmenu'
                    idx = get(obj.hText,'Value');
                    temp = obj.list{idx};
                    if(~isnan(str2double(temp)))
                        temp = str2double(temp);
                    end
                    
                case 'checkbox'
                    temp = get(obj.hText,'Value');
                    
                case 'pushbutton'
                    return;
            end
            
            if(isempty(obj.check) || (~isempty(obj.check) && obj.check(temp)))
                obj.val = temp;
            else
                obj.update_label();
            end            
        end
        
        %Add event function in addition to any
        %that might already be set (e.g. update_val)
        function add_event_fun(obj,new_fun)
            cur_list = get(obj.hText,'Callback');
            if(~iscell(cur_list))
                cur_list = {cur_list};
            end
            cur_list{end+1} = new_fun;
            
            set(obj.hText,'Callback',{@wrapper cur_list});
             
           function wrapper(hobj, eventData, cur_list)
                for iFcn = 1:length(cur_list)
                  feval(cur_list{iFcn}, hobj, eventData);
                end
           end
        end
        
        %Add update button for immediate send to instrument
        function UI_add_update(obj)
            button_pos = get(obj.hText,'Position');
            button_pos([1 3]) = [button_pos(1)+button_pos(3)+0.001 0.01];
            
            obj.hUpdate = obj.mod.ModuleUIC('push','^',button_pos,...
                'Callback',{@(~,~) obj.send()},'FontSize',0.6);
        end   
        
        % Set setting active/inactive
        function set_state(obj, val)
            % Set the activation status. 0: inactive, 1: active
            if(val == 0 || val == 1)
                obj.state = val;
            else
                error('Wrong input parameter for Setting.set_state')
            end
        end
        
         % Set visibility of the UI components
        function set_UIvisibility(obj,val)
            if(val == 1 || val == 0)
                if(val == 0)
                    val = 'off';
                    obj.visibility = 0;
                else
                    val = 'on';
                    obj.visibility = 1;
                end
                set(obj.hText,'Visible',val,'Enable',val);
                set(obj.hLabel,'Visible',val,'Enable',val);
                if(~isempty(obj.hUpdate))
                    set(obj.hUpdate,'Visible',val,'Enable',val);
                end
            else
                error('Wrong input value to toggle visibility');
            end
        end
        
        % Set state status and UI visibility
        function set_state_and_UIvisibility(obj,val)
            obj.set_state(val)
            obj.set_UIvisibility(val)
        end
    end
    
    %UI methods
    methods (Access = public)
       %Update GUI
       function update_label(obj)
            %Find which type of uicontrol
            type = get(obj.hText,'Style');
            
            switch(type)
                case 'edit'
                    set(obj.hText,'String',num2str(obj.val,5));
                    
                case 'listbox'
                    set(obj.hText,'Value',obj.val);
                    
                case 'popupmenu'
                    idx = find(strcmp(obj.list,num2str(obj.val)) == 1,1);
                    if(~isempty(idx))
                        set(obj.hText,'Value',idx);
                    end
                    
                case 'checkbox'
                    set(obj.hText,'Value',obj.val);
            end
           end
    end
end


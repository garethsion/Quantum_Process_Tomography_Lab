classdef ParameterClass < handle
    %This class helps define what sweep need to be made during experiment
    
    properties
        %Labels/Texts
        name  %Sweep name
        label %Label for text
        hText = []; %Handle to UI text
        hLabel = []; %Handle to UI label
        hUpdate = []; %Handle to UI update button if used
        
        %State
        state = 1 % State status, if active parameter is send to instrument 
        visibility = 1;
        
        %Function handles
        check %Handle to parameter_check function
        send_fun %Handle to function to send value to device
        
        %Parameter values
        param %Parameters = {swtype(1=no,2=X,3=Y),startval,stepval,steptype}
        vals %Values of sweep, will be dim = [X or Y, PC]  
        
        %Convertion function: param to point
        sweep_fun = [];
        
        %Parent module
        mod
    end
    
    %General methods
    methods
        %Create a new parameter
        function obj = ParameterClass(mod,name,label,param,check,send_fun)
            obj.mod = mod;
            obj.name = name;
            obj.label = label;
            obj.param = param;
            obj.check = check;
            obj.send_fun = send_fun;
        end
        
        %Copy parameter class (because it is a handle)
        function parObj = copy(obj)
            parObj = ParameterClass(obj.mod,obj.name,obj.label,obj.param,...
                                    obj.check,obj.send_fun);
            parObj.hText = obj.hText;
            parObj.hLabel = obj.hLabel;
            parObj.state = obj.state;
            parObj.vals = obj.vals;
            parObj.sweep_fun = obj.sweep_fun;
        end
        
        %Send value @ sweep index to instrument
        function send(obj,varargin)
            if(length(varargin) == 1)
                val = varargin{1};
            else
                ctXY = varargin{1};
                ctPC = varargin{2};
                
                
                if(size(obj.vals,2) == 1)
                    val = obj.vals(ctXY,1);
                elseif(size(obj.vals,1) == 1)
                    val = obj.vals(1,ctPC);
                else
                    val = obj.vals(ctXY,ctPC);
                end
            end
            
            if(~isempty(obj.mod.dev) && obj.check(val) && obj.state)
                obj.send_fun(val);
            end
        end
        
        %Send current value to textbox
        function text = make_label(obj)
            sw_axis = {'X' 'Y'};
            sw_type = {'lin' 'usr'};

            if(obj.param{1} == 1)
                text = num2str(obj.param{2},3);
            else
                text = [sw_axis{obj.param{1}-1} ',' sw_type{obj.param{4}} ',' ...
                        num2str(obj.param{2},4) ',' num2str(obj.param{3},4)];
            end
        end %Separated to be usable for PGGUI
        function update_label(obj)
            if(~isempty(obj.hText))
                text = obj.make_label();

                %Update GUI and parameter
                set(obj.hText,'String',text); 
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
            
            set(obj.hText,'Callback',{@wrapper {cur_list}});
             
           function wrapper(hobj, eventData, cur_list)
                for iFcn = 1:length(cur_list)
                  feval(cur_list{iFcn}, hobj, eventData);
                end
           end
        end
        
        %Add update button for immediate send to instrument (start value only)
        function UI_add_update(obj)
            button_pos = get(obj.hText,'Position');
            button_pos([1 3]) = [button_pos(1)+button_pos(3)+0.001 0.01];
            
            obj.hUpdate = obj.mod.ModuleUIC('push','^',button_pos,...
                'Callback',{@immediate_update obj},'FontSize',0.6);
            
            function immediate_update(~,~,obj)
                %Update param value first
                obj.create_sweep_vals();

                %Send value
                obj.send(1,1);
            end
        end
        
        % Set parameter active/inactive
        function set_state(obj, val)
            % Set the activation status. 0: inactive, 1: active
            if(val == 0 || val == 1)
                obj.state = val;
            else
                error('Wrong input parameter for Parameters.set_state')
            end
        end
        
        %Set visibility of UI elements on/off
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
    
    %Parameter value methods
    methods (Access = public)
        %Make parameter value (does not use .param because they can still be variables)
        function val = make_val(obj,start,point,step)
            if(obj.param{1} == 1) %No sweep
                val = start;
            else %Sweep
                if(obj.param{4} == 1 || isempty(obj.sweep_fun)) %Linear
                    val = start +  step.*(point-1);
                else %User
                    val = start + obj.sweep_fun(point,step);
                end
            end
        end
        
        %From start-step create all vals to prepare for sweeps
        %Return vector: [X or Y,PC]
        function create_sweep_vals(obj)
            MAIN = obj.mod.MAIN;
            
            %Get real values from PC
            start = MAIN.get_PC_values(obj.param{2},[]);
            step = MAIN.get_PC_values(obj.param{3},[]);
            
            %Number of points
            if(obj.param{1} == 2) %X   
                NbPts = MAIN.XPTS;
            elseif(obj.param{1} == 3) %Y
                NbPts = MAIN.YPTS;
            else
                NbPts = 1;
            end
            
            %Get both step and start to have the same size
            if(length(start) == 1 && length(step) ~= 1)
                start = start*ones(size(step));
            elseif(length(start) ~= 1 && length(step) == 1)
                step = step*ones(size(start));
            end
            
            %Compute values
            obj.vals = zeros(NbPts,length(start));
            for ctPC = 1:length(start)
                obj.vals(:,ctPC) = obj.make_val(start(ctPC),1:NbPts,step(ctPC));
            end
        end
        
        %Check that what is sent to param is acceptable
        %This checks mainly for variable types.
        function [test_val, flag] = param_input_check(~,test_val,varargin)
            if(~isempty(varargin))
                edit_type = varargin{1};
            else
                edit_type = 1:4;
            end
            
            cell_flag = 1;
            if(~iscell(test_val))
                cell_flag = 0;
                test_val = {test_val};
            end
            
            if(length(test_val) ~= length(edit_type))
                flag = 0;
                return;
            end
            
             flag = 1;
             for ct = 1:length(edit_type)
                 %"Translate" start and step values
                if(edit_type(ct) == 2 || edit_type(ct) == 3)
                    if(~isnan(str2double(test_val{ct}))) 
                        test_val{ct} = str2double(test_val{ct});
                    elseif(~isnumeric(test_val{ct}))
                        if(strcmpi(test_val{ct},'NaN'))
                            flag = 0;
                            msgbox('Value cannot be NaN.');
                        elseif(isempty(test_val{ct}))
                            flag = 0;
                            msgbox('No input value.');
                        end
                    end
                end

                if(edit_type(ct) == 3 && test_val{ct} == 0)
                    flag = 0;
                    msgbox('Step value must not be 0.');
                end
             end
             
             if(~cell_flag)
                 test_val = test_val{1};
             end
        end
        
        %Parameter check considering sweep parameters
        %No varargin = recheck
        %Varargin = {val_type new_val} = check new value of given type
        function flag = param_sweep_check(obj,varargin)
            if(isempty(varargin)) %recheck value
                test = obj;
            else %new_value
                test = obj.copy();
                param_type = varargin{1};
                val = varargin{2};

                test.param{param_type} = val;
            end

            test.create_sweep_vals();
            if(~isempty(test.check))
                flag = test.check(test.vals);
            else
                flag = 1;
            end
        end
        
        %Get real value for specific X,Y,PC for typical parameter
        %If ctPC = [], will send values for every PC
        function values = get_values(obj,ctX,ctY,ctPC)
            MAIN = obj.mod.MAIN;
            
            data = obj.param;
            data{2} = MAIN.get_PC_values(data{2},ctPC);
            data{3} = MAIN.get_PC_values(data{3},ctPC);
            
            switch data{1}
                case 1 %Sweep type = None
                    values = data{2};

                case 2 %Sweep type = X
                    values = obj.make_val(data{2},ctX,data{3});

                case 3 %Sweep type = Y
                    values = obj.make_val(data{2},ctY,data{3});
            end
        end
        
        %Get Start-End value of a sweep (list of values for each PC)
        function [start_val,end_val] = get_sweep_start_end(obj)
            MAIN = obj.mod.MAIN;
            
            start_val = obj.get_values(1,1,[]);
            end_val = obj.get_values(MAIN.XPTS,MAIN.YPTS,[]);
            
            if(length(start_val) == 1 && length(end_val) > 1)
                start_val = repmat(start_val,size(end_val));
            elseif(length(end_val) == 1 && length(start_val) > 1)
                end_val = repmat(end_val,size(start_val));
            end
        end
        
        %Get Min-Max value of a sweep (either specific PC or overall min max)
        %varargin = specific PC
        function [min_val,max_val] = get_sweep_min_max(obj,varargin)
            obj.create_sweep_vals();
            if(isempty(varargin) || size(obj.vals,2) == 1)
                min_val = min(obj.vals(:));
                max_val = max(obj.vals(:));
            else
                ctPC = varargin{1};
                min_val = min(obj.vals(:,ctPC));
                max_val = max(obj.vals(:,ctPC));
            end
        end
    end
    
    %Script methods
    methods (Access = public)
%         function script.set_param(obj,param) 
%             flag = obj.param_input_check(test_val,edit_type);
%             
%             %Update UI
%             update_label();
%         end
    end
end


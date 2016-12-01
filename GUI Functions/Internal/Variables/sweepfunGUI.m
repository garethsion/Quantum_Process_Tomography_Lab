function sweepfunGUI(~,~,MAIN,closing_fcnHandle)
%This function opens an interface for defining a
%user-defined function for sweeping the parameter

%Get current parameter
cur_par = MAIN.get_selected_parameter();

%Dimensions
%Figure
fig_width = 0.3;
fig_height = 0.04;

close(findobj(0,'Name','Sweep function definition'));
figure('Name','Sweep function definition','NumberTitle','off',...
            'Visible','on','Units','normalized','MenuBar','None',...
            'Position', [0.4,0.5,fig_width,fig_height],'ResizeFcn',@window_resize,...
            'CloseRequestFcn',@window_close,...
            'windowstyle','modal');
        
%Help text  
hHelp = uicontrol('Style','text','String','Example: logsweep(point,step,1)',...
         'Units','normalized','FontUnits','Normalized',...
         'Position',[0.15    0    0.7    0.4]);           
        
%Edit function
if(isempty(cur_par.sweep_fun))
    fun_str = '';
else
    fun_str = func2str(cur_par.sweep_fun);
    if(strcmp('@(point,step)', fun_str(1:13)))
        fun_str = fun_str(14:end);
    end    
end
hEdit = uicontrol('Style','edit','String',fun_str,...
         'Units','normalized','FontUnits','Normalized',...
         'Position',[0.15    0.45   0.7    0.5],...
         'Callback',{@function_check hHelp});  

%Load function        
uicontrol('Style','push','String','Load function',...
         'Units','normalized','FontUnits','Normalized',...
         'Position',[0    0    0.15    1],...
         'Callback',{@function_load MAIN hEdit hHelp});      
     
%Accept button  
uicontrol('Style','push','Visible','on','String','Accept',...
              'FontWeight','Bold',...
              'Units','normalized','FontUnits','Normalized',...
              'Position',[0.85    0    0.15   1],...
              'Callback',{@function_accept MAIN hEdit hHelp closing_fcnHandle});
end

%Load function
function function_load(~,~,MAIN,hEdit,hHelp)
    filename = uigetfile({'*.m'},'Open',...
                               [MAIN.root_path 'Library' filesep 'Sweep functions']);
    
    if(filename ~= 0)
        set(hEdit,'String',[filename(1:end-2) '(point,step,varargin)']);
    
        function_check(hEdit,[],hHelp);
    end
end

%Check function:
%The first two arguments of the function must be "point","step"
%Output value for point=1 must be 0 (start)
function flag = function_check(hEdit,~,hHelp)
    flag = 1;
    
    fun_str = get(hEdit,'String');
    if(length(fun_str)>1 && ~isempty(strfind(fun_str,'@')))
        flag = 0;
        set(hHelp,'String','This is NOT a valid sweep function: there must not be @(...) in string.');
        return;
    end
    fun_str = ['@(point,step)' fun_str];
    
    try
        sweep_fun = str2func(fun_str);
        
        if(sweep_fun(1,1) ~=0)
            flag = 0;
            set(hHelp,'String','This is NOT a valid sweep function: point=1 must give value=0.');
        end
    catch me
        flag = 0;
        set(hHelp,'String',['This is NOT a valid sweep function: ' me.message]);
    end
    
    if(flag)
        set(hHelp,'String','This is a valid sweep function.');
    end
end

%Accept and close function
function function_accept(~,~,MAIN,hEdit,hHelp,closing_fcnHandle)
    if(function_check(hEdit,[],hHelp))
        %Update parameter
        cur_par = MAIN.get_selected_parameter();
        fun_str = ['@(point,step)' get(hEdit,'String')];
        cur_par.sweep_fun = str2func(fun_str);
        
        %Close GUI
        closing_fcnHandle();
        window_close([],[]);
    end
end

%Closing GUI
function window_close(~,~)
    figure(findobj(0,'Name','GARII: parameters'));
    delete(findobj(0,'Name','Sweep function definition'));
end

%Window resizing update
function window_resize(~,~)
end
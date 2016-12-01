%Main GUI that contains all modules GUI
%Input modules_on = string of modules to turn on for session
function ParamGUI(MAIN,modules_on)
%Close all windows
delete(findobj(0,'Name','GARII: parameters'));
delete(findobj(0,'Name','AWG arbitrary pulse shaping'));
delete(findobj(0,'Name','Phase cycling program'));

%UIs position = [X,Y,width,height], X = Y = 0 = bottom left corner
set(0,'Units','Pixel');

%Figure window
monpos = get(0,'MonitorPositions');
MAIN.hWIN = figure('Name','GARII: parameters','NumberTitle','off','Visible','on',...
                   'Units','normalized','Position', [0.35+size(monpos,1)-1,0.1,0.6,0.7], ...
                   'ResizeFcn',{@window_resize MAIN},'CloseRequestFcn',{@window_closing MAIN});
%'MenuBar','None'

ui_props = {'Units','Normalized','FontUnits','Normalized'};

%% CREATE GLOBAL PARAMETERS
uipanel('Title','Global parameters',ui_props{:},'FontSize',0.15,...
        'Position',[0 0.875 1 0.125],'ForegroundColor','Blue','HighlightColor','Blue');
setting_color = [255 255 200]/255;    
    
%HELP
uicontrol('Style','push','String','?',ui_props{:},...
                 'Position',[0.975 0.95 0.02 0.03],'Callback',@help_dialog,'FontSize',0.6);    
    function help_dialog(~,~)
        CreateStruct.WindowStyle = 'modal';
        CreateStruct.Interpreter = 'tex';
        hmsg = msgbox(...
               {'\bf**** General ARbitrary Instrument Interface (GARII) *****\rm' ...
                'Gary Wolfowicz' ...
                '2014-2015' ...
                ' ' ...
                'Requirements: MATLAB, Instrument Control Toolbox (Visa)' ...
                ' ' ...
                ['GARII is a software for setting and sweeping parameters and acquiring data from '....
                'remote instruments. All instruments are connected via the software to realize 1D or 2D '...
                'parameter sweeps and obtain the corresponding data.']...
                '**********************************************************' ...
                '\bfSave experiment:\rm save the current configuration.' ...
                ['\bfLoad experiment:\rm load a saved configuration to the current modules in GARII. ' ...
                'If the saved data uses other modules, the Restart function (using MATLAB Command Window) ' ...
                'can be used to reload completely the saved configuration.'] ...
                ' ' ...
                ['\bfTime/Shot (s):\rm Time between each shot as set by the computer (pause function).' ...
                'The minimum time/shot will be about 1 ms from the pause function and probably much longer ' ...
                'due to instrument communication. Proper timing should be realized via hardware triggering.'] ...
                '\bfNb of Averages:\rm number of averages. Averages are taken after each full X,Y,Phase cycling sweep.' ...
                '\bfShots/Point\rm: each point in the X/Y sweep are taken Shots/Point time.' ...
                '\bfX axis points:\rm number of points to sweep in the X axis.' ...
                '\bfY axis points:\rm number of points to sweep in the X axis.' ...
                '\bfPhase Cycling:\rm number of points in the phase cycling sequence (set by Variables).' ...
                '\bfStochastic?:\rm if checked, X/Y sweep is done randomly.' ...
                ' ' ...
                ['\bfSweep type:\rm for sweep parameters (blue controls in modules), this sets the type of sweep. ' ...
                'It can be a linear sweep or a user-defined sweep (using an external function which can be loaded from button.).'] ...
                ['\bfStart value:\rm for sweep parameters (blue controls in modules), this sets the start value of the sweep. ' ...
                'Note that for a user-defined sweep, the function must be equal to 0 for point X/Y=1 as this value defines the start time.'] ...
                '\bfStep value:\rm for sweep parameters (blue controls in modules), this sets the step value between points of the sweep.' ...
                ['\bfVariables:\rm open window to define variables value (if used). Multiple line of values correspond to a ' ...
                'phase cycling where within each points the data is acquired for each of these values and summed according to weight. ' ...
                'WARNING: there is currently a single weight for every instrument.']},...
                'GARII help.',CreateStruct);
    end

%SAVE EXPERIMENT
[textPos,~] = UIcontrolPosition(0.7,1);
uicontrol('Style','push','String','Save experiment',ui_props{:},...
           'Position',textPos,'Callback',@MAIN.saveAll,'FontSize',0.6);    
       
%LOAD EXPERIMENT
[textPos,~] = UIcontrolPosition(1.6,1);
uicontrol('Style','push','String','Load experiment',ui_props{:},...
           'Position',textPos,'Callback',@MAIN.loadAll,'FontSize',0.6);  
    
%FIELD: SHOT REPETITION TIME
[textPos, inputPos] = UIcontrolPosition(0.8,1.9);
uicontrol('Style','text','String','Time/Shot (s):',ui_props{:},'Position',textPos,'FontSize',0.65);
MAIN.hMETA.SRT = uicontrol('Style','edit','String',num2str(MAIN.SRT),...
           ui_props{:},'BackgroundColor', setting_color,'FontSize',0.5,...
          'Position',inputPos, 'Callback',{@MAIN.metadataEdit,'SRT'});

%FIELD: NUMBER OF AVERAGES
[textPos, inputPos] = UIcontrolPosition(0.8,3.1);
uicontrol('Style','text','String','# of Averages:',ui_props{:},'Position',textPos,'FontSize',0.65);
MAIN.hMETA.AVG = uicontrol('Style','edit','String',num2str(MAIN.AVG),...
          ui_props{:},'BackgroundColor', setting_color,'FontSize',0.5,...
          'Position',inputPos,'Callback',{@MAIN.metadataEdit,'AVG'});

%FIELD: SHOTS PER POINT
[textPos, inputPos] = UIcontrolPosition(0.8,4.3);
uicontrol('Style','text','String','Shots/Point:',ui_props{:},'Position',textPos,'FontSize',0.65);
MAIN.hMETA.SPP = uicontrol('Style','edit','String',num2str(MAIN.SPP),...
          ui_props{:},'BackgroundColor', setting_color,'FontSize',0.5,...
          'Position',inputPos,'Callback',{@MAIN.metadataEdit,'SPP'});
             
%FIELD: X-AXIS
[textPos, inputPos] = UIcontrolPosition(1.7,1.7);
uicontrol('Style','text','String','X axis points:',ui_props{:},'Position',textPos,'FontSize',0.65);
MAIN.hMETA.XPTS = uicontrol('Style','edit','String',num2str(MAIN.XPTS),...
          ui_props{:},'BackgroundColor', setting_color,'FontSize',0.5,...
          'Position',inputPos,'Callback',{@MAIN.metadataEdit,'XPTS'});
             
%FIELD: Y-AXIS
[textPos, inputPos] = UIcontrolPosition(1.7,2.7);
uicontrol('Style','text','String','Y axis points:',ui_props{:},'Position',textPos,'FontSize',0.65);
MAIN.hMETA.YPTS = uicontrol('Style','edit','String',num2str(MAIN.YPTS),...
          ui_props{:},'BackgroundColor', setting_color,'FontSize',0.5,...
          'Position',inputPos,'Callback',{@MAIN.metadataEdit,'YPTS'});   
      
%FIELD: PC-AXIS
[textPos, inputPos] = UIcontrolPosition(1.7,3.7);
uicontrol('Style','text','String','Phase cycling:',ui_props{:},'Position',textPos,'FontSize',0.65);
MAIN.hMETA.PCPTS = uicontrol('Style','edit','String',num2str(MAIN.PCPTS),...
          ui_props{:},'Enable','off','BackgroundColor', setting_color,'FontSize',0.5,...
          'Position',inputPos);        
      
%FIELD: STOCHASTIC SWEEP
[textPos, inputPos] = UIcontrolPosition(1.7,4.7);
uicontrol('Style','text','String','Stochastic?',ui_props{:},'Position',textPos,'FontSize',0.65);
MAIN.hMETA.STSW = uicontrol('Style','checkbox',ui_props{:},'Position',inputPos,...
           'Callback',{@MAIN.metadataEdit,'STSW'});         
      
%% SWEEP CONTROLS
uipanel('Title','Sweep controls',ui_props{:},'FontSize',0.19,...
        'Position',[0 0.78 1 0.095],'ForegroundColor','Blue','HighlightColor','Blue');
    
param_color = [224 255 255]/255;

%FIELD: VARIABLES/PHASE CYCLINGS
[textPos,~] = UIcontrolPosition(3.3,5);
uicontrol('Style','push','String','Variables',ui_props{:},...
          'Position',textPos,'Callback',{@phasecyclingGUI MAIN});   
    
%FIELD: CURRENT TABLE PARAMETER: SWEEP TYPE
[textPos, inputPos] = UIcontrolPosition(3.3,1);
hSWEEP.type(1) = uicontrol('Style','text','String','Sweep type:',...
          ui_props{:},'Position',textPos,'FontSize',0.65);
hSWEEP.type(2) = uicontrol('Style','popup','String',{'None','X' 'Y'},ui_props{:},'BackgroundColor', param_color,...
          'Position',[inputPos(1) inputPos(2)+0.005 inputPos(3) inputPos(4)],'FontSize',0.5,...
          'Callback',{@MAIN.sweepControlsEdit,'SWEEPTYPE'});
      
hSWEEP.type(3) = uicontrol('Style','popup','String',{'Linear','User'},ui_props{:},'BackgroundColor', param_color,...
          'Position',[inputPos(1) inputPos(2)-0.025 inputPos(3) inputPos(4)],'FontSize',0.5,...
          'Callback',{@MAIN.sweepControlsEdit,'STEPTYPE'},'Visible','off');
hSWEEP.type(4) = uicontrol('Style','push','String','...',ui_props{:},...
          'Position',[inputPos(1)+inputPos(3) inputPos(2)-0.019 0.02 inputPos(4)-0.01],'FontSize',0.5,...
          'Callback',{@sweepfunGUI MAIN @() MAIN.sweepControlsEdit(hSWEEP.type(3),[],'STEPTYPE')},'Visible','off');

%FIELD: CURRENT TABLE PARAMETER: START VALUE    
[textPos, inputPos] = UIcontrolPosition(3.3,2);
hSWEEP.start(1) = uicontrol('Style','text','String','Value:',...
          ui_props{:},'Position',textPos,'FontSize',0.65);
hSWEEP.start(2) = uicontrol('Style','edit','String',0,ui_props{:},'BackgroundColor', param_color,...
          'Position',inputPos,'Callback',{@MAIN.sweepControlsEdit,'STARTVAL'},'FontSize',0.5);

%FIELD: CURRENT TABLE PARAMETER: STEP VALUE            
[textPos, inputPos] = UIcontrolPosition(3.3,3);
hSWEEP.step(1) = uicontrol('Style','text','Visible','off','String','Step value:',...
          ui_props{:},'Position',textPos,'FontSize',0.65);
hSWEEP.step(2) = uicontrol('Style','edit','Visible','off','String',0,ui_props{:},'BackgroundColor', param_color,...
          'Position',inputPos,'Callback',{@MAIN.sweepControlsEdit,'STEPVAL'},'FontSize',0.5); 
      
%FIELD: CURRENT TABLE PARAMETER: END VALUE            
[textPos, inputPos] = UIcontrolPosition(3.3,4);
hSWEEP.end(1) = uicontrol('Style','text','Visible','off','String','End value:',...
          ui_props{:},'Position',textPos,'FontSize',0.65);
hSWEEP.end(2) = uicontrol('Style','edit','Visible','off','String',0,ui_props{:},...
          'Position',inputPos,'Enable','off','FontSize',0.5); 

%Send hSWEEP handle to MAIN      
MAIN.hSWEEP = hSWEEP;
      
%% MODULE PANELS     
%Choose module
MAIN.hPanelList = uicontrol('Parent',MAIN.hWIN,'Style','popup','String',' ',ui_props{:},...
            'FontSize',0.6,'ForegroundColor','Blue','FontWeight','Bold',...
            'Position',[0.008 0.747 0.15 0.03],'Callback',@MAIN.UI_module_panel_update);
        
%Add module
uicontrol('Parent',MAIN.hWIN,'Style','push','String','+',ui_props{:},'FontSize',0.7,...
        'ForegroundColor','Blue','FontWeight','Bold',...
        'Position',[0.16 0.747 0.035 0.03],'Callback',{@add_module_event MAIN});
    
%Delete module    
uicontrol('Parent',MAIN.hWIN,'Style','push','String','-',ui_props{:},'FontSize',0.7,...
        'ForegroundColor','Blue','FontWeight','Bold',...
        'Position',[0.195 0.747 0.035 0.03],'Callback',{@remove_module_event MAIN});

%%%%%%%%%%%%
%Turn on modules
for ct = 1:length(modules_on)
    MAIN.add_module(modules_on{ct});
end
    
%Default panel
if(~isempty(MAIN.mods))
    dft_idx = 1;
    set(MAIN.hPanelList,'Value',dft_idx);
    MAIN.UI_module_panel_update();
end

end

%% MODULE (Selection/add/removal)
function add_module_event(~,~,MAIN)
    %Select module UI
    mod_name = cell(size(MAIN.mods_name,1),1);
    mod_list = cell(size(MAIN.mods_name,1),1);
    for ct = 1:size(MAIN.mods_name,1)
        if(~iscell(MAIN.mods_name{ct,1}))
            mod_name{ct} = MAIN.mods_name{ct,1};
        else
            mod_name{ct} = MAIN.mods_name{ct,1}{1};
        end
        mod_list{ct} = [mod_name{ct} ' - ' MAIN.mods_name{ct,2}];
    end
    screensize = get(0,'ScreenSize');
    dlgsize = [screensize(3)/4 screensize(4)/3];
    [sel_mods,flag] = listdlg('Name','Module selection','ListString',mod_list,'ListSize',dlgsize);
    
    %Add module
    if(flag)
        for ct = 1:length(sel_mods)
            MAIN.add_module(mod_name{sel_mods(ct)});
        end
    end
end

function remove_module_event(~,~,MAIN)
    mod_idx = get(MAIN.hPanelList,'Value');
    if(~isempty(MAIN.mods_ID))
        MAIN.remove_module(MAIN.mods_ID{mod_idx});
    end
end

%% WINDOW FUNCTIONS
%This function provides the location for UIcontrols (similar to the subplot fct)
function [textPos, inputPos] = UIcontrolPosition(pos1,pos2)
    borders = 0.011;
    
    text_width = 0.11;
    text_height = 0.03;
    
    input_width = 0.06;
    input_height = 0.04;
    
    total_width = 4*borders + text_width + input_width;
    
    textPos = [borders + (pos2-1)*total_width, ... %X
               1-2*borders - pos1*(text_height + 2*borders),... %Y
               text_width,... %width
               text_height]; %height
    
    inputPos = [textPos(1) + text_width + borders,... %X
                textPos(2),... %Y
                input_width,... %width
                input_height]; %height
end

%Window resizing update
function window_resize(hobj,~,MAIN)
    %Check all modules
    for ct = 1:length(MAIN.mods)
        temp = MAIN.mods{ct};

        if(~isempty(temp) && ~isempty(temp.window_resize))
            temp.window_resize(hobj,[]);
        end
    end
end

%Main window is being closed
function window_closing(hobj,~,MAIN)
    %Close window
    delete(findobj(0,'Name','GARII: measurements'));
    delete(hobj);
    
    delete(MAIN);
end
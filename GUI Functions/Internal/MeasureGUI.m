%GUI for running experiments
function MeasureGUI(MAIN)
%Figure window
delete(findobj(0,'Name','GARII: measurements'));

hMeasWin = figure('Name','GARII: measurements',...
                  'NumberTitle','off','Visible','on','Units','Normalized',...
                  'Position', [0.02,0.2,0.6,0.7]); 
    
ui_props = {'Units','Normalized','FontUnits','Normalized'};
   
%% MEASUREMENT PLOT
h = uipanel('Title','Plot',ui_props{:},'FontSize',0.027,...
        'Position',[0 0.3 1 0.7],'ForegroundColor','Blue','HighlightColor','Blue');

Xaxis = 0;
Yaxis = 0;
ax = axes;
MAIN.hPLOT(1:2) = plot(ax,Xaxis,Yaxis,Xaxis,Yaxis);
MAIN.hPLOT(3) = ax;
set(MAIN.hPLOT(3),'Parent',h,ui_props{:},'Position',[0.1 0.14 0.8 0.7],...
    'FontSize',0.06,'YTickLabel',[],'XTickLabel',[]);

%Choose which data from which measure to plot          
[textPos, ~] = UIcontrolPosition(0.6,1);    
MAIN.hPLOT(4) = uicontrol('Parent',hMeasWin,'Style','popup',ui_props{:},...
          'FontSize',0.65,'String',{' '},'FontWeight','Bold','ForegroundColor','Red',...
          'Position',textPos,'Callback',{@plot_select MAIN 1});
      
[textPos, ~] = UIcontrolPosition(0.6,1.8);    
MAIN.hPLOT(5) = uicontrol('Parent',hMeasWin,'Style','popup',ui_props{:},...
          'FontSize',0.65,'String',{' '},'FontWeight','Bold','ForegroundColor','Blue',...
          'Position',textPos,'Callback',{@plot_select MAIN 2});       
      
%Log scale: auto
[textPos,~] = UIcontrolPosition(0.6,3.7); 
uicontrol('Parent',hMeasWin,'Style','checkbox',ui_props{:},...
          'FontSize',0.65,'String','Auto scale','Position',textPos,...         
          'Value',1,'Callback',{@plotSetScale MAIN 'auto'});
      
%Log scale: X
uicontrol('Parent',hMeasWin,'Style','checkbox',ui_props{:},...
          'FontSize',0.65,'String','Log scale (X)','Position',...
          [textPos(1)+0.1 textPos(2) textPos(3)-0.05 textPos(4)],...
          'Value',0,'Callback',{@plotSetScale MAIN 'X'});
      
%Log scale: Y      
uicontrol('Parent',hMeasWin,'Style','checkbox',ui_props{:},...
          'FontSize',0.65,'String','Log scale (Y)','Position',...
          [textPos(1)+0.2 textPos(2) textPos(3)-0.05 textPos(4)],...
          'Value',0,'Callback',{@plotSetScale MAIN 'Y'});     
      
%Calibrate function
[textPos,~] = UIcontrolPosition(1.4,3.7); 
uicontrol('Parent',hMeasWin,'Style','checkbox',ui_props{:},...
          'FontSize',0.65,'String','Calibrate?','Position',...
          [textPos(1)+0.1 textPos(2) textPos(3)-0.05 textPos(4)],...
          'Value',0,'Callback',{@plotSetCal MAIN}); 
      
uicontrol('Parent',hMeasWin,'Style','push',ui_props{:},...
          'FontSize',0.65,'String','Calibrate function','Position',...
          [textPos(1)+0.2 textPos(2) textPos(3)-0.05 textPos(4)],...
          'Value',0,'Callback',{@plotGetCalFun MAIN}); 
    
%% MEASUREMENT OPTIONS
uipanel('Title','Measurement options',ui_props{:},'FontSize',0.06,...
             'Position',[0 0 1 0.298],'ForegroundColor','Blue','HighlightColor','Blue');

%Measurement device (multiple device measurement possible)
msre_dev_str = MAIN.find_MSRE_modules();
MAIN.hOPT(1) = uicontrol('Parent',hMeasWin,'Style','listbox',ui_props{:},...
          'FontSize',0.2,'FontWeight','Bold','ForegroundColor','Blue',...
          'String',msre_dev_str,'Position',[0.01 0.17 0.2 0.10],'Min',1,'Max',3);

%Experiment run option
MAIN.hOPT(2) = uicontrol('Parent',hMeasWin,'Style','popup',ui_props{:},...
          'FontSize',0.4,'FontWeight','Bold','ForegroundColor','Blue',...
          'Position',[0.3 0.22 0.15 0.05],'Callback',{@exp_options_selected MAIN},...
          'String',{'Single run' 'Continuous run'},'Value',1,'enable','on');
MAIN.run_mode = 'Single run';
      
%Run/Trigger mode           
% [textPos, ~] = UIcontrolPosition(1,3);    
% MAIN.hOPT(3) = uicontrol('Parent',hMeasWin,'Style','popup',ui_props{:},...
%           'FontSize',0.65,'FontWeight','Bold','ForegroundColor','Blue',...
%           'Position',[0.5 0.22 0.15 0.05],'Callback',@trigger_options_selected,...
%           'String',{'Computer Trigger' 'External Trigger'},'enable','off');

%% EXPERIMENT RUN
%Play button
MAIN.hPLAY = uicontrol('Parent',hMeasWin,'Style','push',ui_props{:},...
            'FontSize',0.45,'String','PLAY','FontWeight','Bold',...
            'ForegroundColor','Black','Callback',{@UI_playnstop_event MAIN 'runstop'},...
            'Position',[0.01 0.01 0.1 0.1],'BackgroundColor','green');
        
uicontrol('Parent',hMeasWin,'Style','push',ui_props{:},...
            'FontSize',0.45,'String','Pause','Callback',{@UI_playnstop_event MAIN 'pause'},...
            'Position',[0.12 0.01 0.07 0.05]);
        
uicontrol('Parent',hMeasWin,'Style','push',ui_props{:},...
            'FontSize',0.45,'String','End Avg','Callback',{@UI_playnstop_event MAIN 'stopatavg'},...
            'Position',[0.12 0.06 0.07 0.05]);
        
%% SAVING        
%Data save folder
MAIN.hSAVE(1) = uicontrol('Parent',hMeasWin,'Style','edit',ui_props{:},...
          'FontSize',0.65,'String',[MAIN.root_path 'Data'],'Position',[0.22 0.01 0.2 0.03]);
uicontrol('Parent',hMeasWin,'Style','push',ui_props{:},'FontSize',0.8,'String','...',...
          'Callback',{@get_save_folder MAIN},'Position',[0.421 0.01 0.03 0.03]);

%Autosave data
uicontrol('Parent',hMeasWin,'Style','text',ui_props{:},'FontSize',0.65,...
          'String','Autosave','Position',[0.22 0.05 0.06 0.03]);
MAIN.hSAVE(2) = uicontrol('Parent',hMeasWin,'Style','checkbox',ui_props{:},...
          'Position',[0.29 0.05 0.03 0.03],'Value',1);
      
%Full data save
uicontrol('Parent',hMeasWin,'Style','text',ui_props{:},...
          'FontSize',0.65,'String','Full save','Position',[0.32 0.05 0.06 0.03]);
MAIN.hSAVE(3) = uicontrol('Parent',hMeasWin,'Style','checkbox',ui_props{:},...
          'Position',[0.39 0.05 0.03 0.03],'Value',1);
      
%% EXPERIMENT STATUS
cur_axis = gca;
uicontrol('Parent',hMeasWin,'Style','text',ui_props{:},...
          'FontSize',0.65,'String','X/Y sweep:','Position',[0.75 0.245 0.1 0.03]);
MAIN.hSTATUS{1} = progressbar(hMeasWin, [0.84 0.245 0.15 0.03], [0 1]);

uicontrol('Parent',hMeasWin,'Style','text',ui_props{:},...
          'FontSize',0.65,'String','Averaging:','Position',[0.747 0.205 0.1 0.03]);
MAIN.hSTATUS{2} = progressbar(hMeasWin, [0.84 0.205 0.15 0.03], [0 1]);
axes(cur_axis); %Axis prior to status bar must be reloaded, crashes otherwise when using Restart

MAIN.hSTATUS{3} = uicontrol('Parent',hMeasWin,'Style','text',ui_props{:},...
          'FontSize',0.65,'String','Time remaining:','Position',[0.78 0.16 0.2 0.03]);
      
%% Module connections
% MAIN.hConnectAll = uicontrol('Parent',hMeasWin,'Style',push',ui_props{:},...
%           'FontSize',0.65,'String','Disconnected','Position',[0.8 0.1 0.1 0.3],...
%           'BackgroundColor','red');
      
end

%This function provides the location for UIcontrols (similar to the subplot fct)
function [textPos, inputPos] = UIcontrolPosition(pos1,pos2)
    borders = 0.011;
    
    text_width = 0.15;
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

%% RUN functions
function UI_playnstop_event(~,~,MAIN,type)
    switch(type)
        case 'runstop'
            if(MAIN.run_flag == 0) %If stopped
                MAIN.playnstop('run'); %Run
            elseif(any(MAIN.run_flag == [-1 1])) %If running
                MAIN.playnstop('stop'); %Stop at end of current point
            end
            
        case 'pause'
            if(MAIN.run_flag == 1) %If running
                MAIN.playnstop('pause'); %Pause
            end
            
        case 'stopatavg'
            if(MAIN.run_flag == 1) %If running
                MAIN.playnstop('stopatavg'); %Stop at end of current averaging
            end
    end
end

%% Option functions
%Specific experiment type
function exp_options_selected(hobj,~,MAIN)
    list = get(hobj,'String');
    MAIN.run_mode = list{get(hobj,'Value')};
end

%% Plot functions
%Select plot
function plot_select(hobj,~,MAIN,plot_nb)
    %Selected plot
    idx = get(hobj,'Value');
    plot_str = get(hobj,'String');
    plot_str = plot_str(idx);
    
    for ct = 1:length(MAIN.mods)
        temp = MAIN.mods{ct};       
        for ctMSRE = 1:numel(temp.measures)
            if(strcmp([temp.ID ' - ' temp.measures{ctMSRE}.label],plot_str))
                MAIN.current_plot{plot_nb} = {temp.ID temp.measures{ctMSRE}.name};
                MAIN.update_plot;
                return;
            end
        end
    end
end

%Select plot scale: type = X or Y
function plotSetScale(hobj,~,MAIN,type)
    flag = get(hobj,'Value');
    
    switch(type)
        case 'auto'
                MAIN.plot_autoScale = flag;
            
        case 'X'
            if(flag)
                set(MAIN.hPLOT(3),'XScale','log');
            else
                set(MAIN.hPLOT(3),'XScale','linear');
            end
            
        case 'Y'
            if(flag)
                set(MAIN.hPLOT(3),'YScale','log');
            else
                set(MAIN.hPLOT(3),'YScale','linear');
            end
    end       
end

%Activate calibration
function plotSetCal(hobj,~,MAIN)
    MAIN.dataCal.status = get(hobj,'Value');
end

function plotGetCalFun(~,~,MAIN)
[filename, pathname] = uigetfile('*.m','Open',...
                           [MAIN.root_path 'Library' filesep 'Acquisition filters']);
    
     if(filename ~= 0)
         filename = filename(1:end-2);
         addpath(pathname);
         MAIN.dataCal.file = str2func(filename);
     end
end

%% Saving functions
%Get folder for saving files
function get_save_folder(~,~,MAIN)
    set(MAIN.hSAVE(1),'String',uigetdir([MAIN.root_path 'Data'],'Data saving directory'));
end
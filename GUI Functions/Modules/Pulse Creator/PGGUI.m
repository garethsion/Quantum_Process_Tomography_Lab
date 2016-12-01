%Pulse Creator GUI module
function PGGUI(PG)
%% Module definition
help_text = {'This module enables the creation of pulse sequences for the 81180 AWG.' ...
              'Pulses are defined by the following properties:' ...
             ['\bfFrequency (MHz):\rm pulse frequency synthesized by the AWG, will also modulate any arbitrary shape.' ...
              'Note that frequency > 1 GHz are not reliable due to sampling rate.'] ...
              '\bfPhase (degree):\rm pulse phase.' ...
              '\bfAmplitude:\rm Pulse amplitude with 1 corresponding to the maximum AWG output.' ...
              '\bfDuration (ns):\rm Pulse duration.' ...
              '\bfStart time (ns):\rm Pulse starting time. Actual channel switching might be at different time, due to "defense pulse".' ...
             ['\bfPeriod (ns):\rm Pulses can be reproduced periodically. This is the period value. Note that if used ' ...
              'with a pulse with a certain frequency, this purely reproduces the shape, therefore this is NOT phase continuous.'] ...
              '\bf# of Periods:\rm Number of time the pulse must be repeated.' ...
             ['\bfShape:\rm Pulse shape. By default, is "square", i.e. constant amplitude.' ...
              'More shapes can be loaded using the "Load arbitrary shape" button, or it can refer to subtables.'] ...
             ['\bfChannel:\rm Pulse channel corresponding to different path within the spectrometer. ' ...
              'Channels are "Acquisition" for measurement (turns on internal LNA, as well as determine oscilloscope trigger),' ...
              '"MW" for pulses to the cavity (and which can be amplified), "RF" for pulses straight out of AWG ' ...
              '(spectrometer left side, normally for ENDOR), "User" to be used for additional markers/triggers (best to put amplitude to 0).']};
PG.UI_add_help(help_text);


%Optional function handles
PG.window_resize = @PG.window_resize_fun;
PG.metadataEdit = @PG.metadataEdit_fun;
PG.sweepControlsEdit = @PG.sweepControlsEdit_fun;
PG.PCwindowClosing = @PG.PCwindowClosing_fun;
PG.user_params_load = @PG.load_for_main;
    
%% PULSE TABLE
PG.UI_add_subpanel('Pulse parameters',0.40,0.57);

%Main figure dimensions
borders = 0.02;
fig_dim = get(PG.MAIN.hWIN,'Position');
fig_width = fig_dim(3);
    
%Table dimensions
tab_width = 0.7;
tab_height = 0.52;
tab_Y = 0.4;
PG.hTABLE = uitable('Parent',PG.hPanel,'Visible','on','Units','Normalized','FontUnits','Normalized',...
            'Position',[0.5-tab_width/2,tab_Y+borders,tab_width,tab_height],'BackgroundColor',[224 255 255]/255,...
            'FontSize',0.04);

set(PG.hTABLE, 'ColumnName', {'Frequency (MHz)', 'Phase (deg)', 'Amplitude', ...
       'Duration (ns)', 'Start time (ns)', 'Period (ns)','# of Periods', 'Shape', 'Channel'});
col_width = get(0,'ScreenSize');
col_width = col_width(3)*fig_width*tab_width/(size(PG.data,2)+0.2);
set(PG.hTABLE, 'ColumnWidth', {col_width});
set(PG.hTABLE, 'RowName', '');

set(PG.hTABLE, 'ColumnEditable', [false false false false false false false true true]);
set(PG.hTABLE, 'ColumnFormat', {[] [] [] [] [] [] [] ...
             {'Square'} {'Acquisition' 'MW' 'RF' 'User'}});
set(PG.hTABLE, 'Data', {'0' '0' '0' '0' '0' '0' '1' 'Square' 'MW'});

set(PG.hTABLE, 'CellSelectionCallback', {@PG.tableCellSelected}); %Cell selection update                    
set(PG.hTABLE, 'CellEditCallback', @PG.tableCellModified); %For shape   

set(PG.hTABLE,'UserData',1); %Set TABLE to Main table

%Buttons
button_width = 0.12;
button_height = 0.05;

posLeft = 0.49-tab_width/2-button_width;
posTop = -0.02+tab_Y+tab_height+borders-1*button_height;

%SUBTABLES
PG.ModuleUIC('push','Tables (beta)',[posLeft posTop button_width button_height],...
             'FontWeight','Bold','FontSize',0.5,'Enable','Inactive');

%Add subtable
PG.ModuleUIC('push','+',[posLeft posTop-button_height button_width/2 ...
             button_height],'Enable','on','Callback',@PG.addsubtable);

%Remove subtable
PG.ModuleUIC('push','-',[posLeft+button_width/2 posTop-button_height ...
             button_width/2 button_height],'Enable','on','Callback',@PG.deletesubtable);

%Tables list
PG.hSUBTABLE = PG.ModuleUIC('popup',{'MAIN'},[posLeft posTop-2*button_height ...
             button_width button_height],'FontSize',0.5,'Callback',@PG.subtableSelected);

%PULSES
PG.ModuleUIC('push','Pulses',[posLeft posTop-3*button_height button_width ...
             button_height],'FontWeight','Bold','FontSize',0.5,'Enable','Inactive');

%Add pulse to table
PG.ModuleUIC('push','+',[posLeft posTop-4*button_height button_width/2 ...
             button_height],'Enable','on','Callback',@PG.addpulse);

%Remove pulse from table
PG.ModuleUIC('push','-',[posLeft+button_width/2 posTop-4*button_height ...
             button_width/2 button_height],'Enable','on','Callback',@PG.deletepulse);
     
%% ARB PULSES, COMPILE, SAVE/LOAD 
button_height = 0.08;
posLeft = 1.01-button_width-1.5*borders;
posTop = -0.02+tab_Y+tab_height+borders;

%Load Arbitrary pulses
PG.ModuleUIC('push','Load arbitrary shapes',[posLeft,posTop-1*button_height,...
             button_width,button_height],'Callback',{@PGarbitraryfcnGUI PG},...
             'FontSize',0.3);

%Save experiment
PG.ModuleUIC('push','Save sequence',[posLeft,posTop-2*button_height,...
             button_width,button_height],'Callback',@PG.savePG,...
             'FontSize',0.3);   
       
%Load experiment
PG.ModuleUIC('push','Load sequence',[posLeft,posTop-3*button_height,...
             button_width,button_height],'Callback',@PG.loadPG,...
             'FontSize',0.3);    
         
%Check (compile and plot) sequence
PG.ModuleUIC('push','Check sequence',[posLeft,posTop-6*button_height,...
             button_width,button_height],'Callback',@PG.check_sequence,...
             'FontSize',0.3);             
       
%% CREATE SEQUENCE PLOTTER
hseqpanel = PG.UI_add_subpanel('Sequence preview',0.005,0.395);
    
time = 0; plotdata = [0 0 0].';
cur_ax = axes; %Create a new axis for the plot
PG.hPLOT = plot(cur_ax,time,plotdata);
xlabel('Time (ns)');
ylabel('Parameter');

plot_height = 0.7;
plot_width = 0.85;
set(cur_ax,'Parent',hseqpanel,'Units','normalized','FontUnits','Normalized',...
        'Position',[2*borders 0.28 plot_width plot_height],...
        'FontSize',0.12,'YTickLabel',[])
    
Linewidth = [8 5 2];    
Color = [[0 128 255];[0 0 0];[255 0 0]]/255;
for ct = 1:length(PG.hPLOT)
    set(PG.hPLOT(ct),'LineWidth',Linewidth(ct),'Color',Color(ct,:));
end

hLEGEND = legend('Frequency','Phase','Amplitude','Location','NorthEastOutside');
set(hLEGEND,'FontSize',10);
xlim([0 1]);

for ct = 1:length(PG.hPLOT)
    ydata = plotdata(ct,:); %#ok<NASGU>
    set(PG.hPLOT(ct),'XDataSource','time','YDataSource','ydata');
    refreshdata(PG.hPLOT,'caller');
end

%Slide X-value for plotting
PG.ModuleUIC('text','X',[1-0.09 3.2*borders+0.25 0.015 0.04]); 
PG.hPLOTCONTROL(1) = PG.ModuleUIC('slider','X',[1-0.09 2*borders 0.02 0.28],...
          'Enable','off','Value',1,'Max',2,'Min',1','Callback',@PG.plot_update);
     
%Slide Y-value for plotting
PG.ModuleUIC('text','Y',[1-0.06 3.2*borders+0.25 0.015 0.04]); 
PG.hPLOTCONTROL(2) = PG.ModuleUIC('slider','Y',[1-0.06 2*borders 0.02 0.28],...
          'Enable','off','Value',1,'Max',2,'Min',1','Callback',@PG.plot_update);
     
%Slide PC-value for plotting
PG.ModuleUIC('text','PC',[1-0.03 3.2*borders+0.25 0.02 0.04]); 
PG.hPLOTCONTROL(3) = PG.ModuleUIC('slider','PC',[1-0.03 2*borders 0.02 0.28],...
          'Enable','off','Value',1,'Max',2,'Min',1','Callback',@PG.plot_update);

%Channel selection for plotting
PG.ModuleUIC('text','Channel:',[0.785 3.2*borders+0.03 0.06 0.02],'FontSize',0.9); 
PG.hPLOTCONTROL(4) = PG.ModuleUIC('popup',{'MW' 'RF' 'User'},[0.79 3.2*borders 0.1 0.02],...
          'Callback',@PG.plot_update,'FontSize',0.9);
      
%% Warning/Issues
PG.ModuleUIC('text','Warning: period is not phase continuous.',...
           [0.35 0.96 0.3 0.03],'ForegroundColor','Red','FontSize',0.7);
end  

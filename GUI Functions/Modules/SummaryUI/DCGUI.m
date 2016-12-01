%DC Creator GUI module
function DCGUI(DC)
%% Module definition

%Optional function handles
DC.window_resize = @window_resize;
DC.metadataEdit = @metadataEdit;
DC.sweepControlsEdit = @sweepControlsEdit;
DC.load = @load_for_main;
    
%% DC TABLE
DC.UI_add_subpanel('DC parameters',0.40,0.57);

%Main figure dimensions
borders = 0.02;
fig_dim = get(DC.MAIN.hWIN,'Position');
fig_width = fig_dim(3);
fig_height = fig_dim(4);
    
%Table dimensions
tab_width = 0.7;
tab_height = 0.52;
tab_Y = 0.4;
DC.hTABLE = uitable('Parent',DC.hPanel,'Visible','on','Units','Normalized','FontUnits','Normalized',...
            'Position',[0.5-tab_width/2,tab_Y+borders,tab_width,tab_height]);

set(DC.hTABLE, 'ColumnName', {'Device', 'Channel', 'Voltage (V)', ...
    'Min (V)', 'Max (V)', 'Sweep rate (V/s)', 'Compliance (A)'});
col_width = get(0,'ScreenSize');
col_width = col_width(3)*fig_width*tab_width/(size(DC.data,2)+0.2);
set(DC.hTABLE, 'ColumnWidth', {col_width});
set(DC.hTABLE, 'RowName', '');

set(DC.hTABLE, 'ColumnEditable', [true true false true true true true]);
set(DC.hTABLE, 'ColumnFormat', {{' '} {' '} [] [] [] [] []});
set(DC.hTABLE, 'Data', {});

set(DC.hTABLE, 'CellSelectionCallback', {@tableCellSelected}); %Cell selection update                    
set(DC.hTABLE, 'CellEditCallback', @tableCellModified); %For shape   

set(DC.hTABLE,'UserData',1); %Set TABLE to Main table

%Buttons
button_width = 0.12;
button_height = 0.05;

posLeft = 0.5-tab_width/2-button_width;
posTop = -0.02+tab_Y+tab_height+borders-1*button_height;

%DC parameters
DC.ModuleUIC('push','DC parameter',[posLeft posTop-0*button_height button_width ...
             button_height],'FontWeight','Bold','FontSize',0.5,'Enable','Inactive');

%Add pulse to table
DC.ModuleUIC('push','+',[posLeft posTop-1*button_height button_width/2 ...
             button_height],'Enable','on','Callback',@addpulse);

%Remove pulse from table
DC.ModuleUIC('push','-',[posLeft+button_width/2 posTop-1*button_height ...
             button_width/2 button_height],'Enable','on','Callback',@deletepulse);
     
end
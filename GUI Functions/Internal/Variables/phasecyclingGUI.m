function phasecyclingGUI(~,~,MAIN)
%This function opens an interface for defining phase cycling/variables

%Cleanup variables in MAIN, i.e. remove those that are unused
PCvars = {};
for ct = 1:length(MAIN.mods)
    for ctPAR = 1:numel(MAIN.mods{ct}.params)
        if(isa(MAIN.mods{ct}.params{ctPAR},'ParameterClass'))
            if(~isnumeric(MAIN.mods{ct}.params{ctPAR}.param{2})) %Start
                PCvars{end+1} = MAIN.mods{ct}.params{ctPAR}.param{2}; %#ok<AGROW>
            end
            if(~isnumeric(MAIN.mods{ct}.params{ctPAR}.param{3})) %Step
                PCvars{end+1} = MAIN.mods{ct}.params{ctPAR}.param{3}; %#ok<AGROW>
            end
        end
    end
end
[MAIN.PC_types,idx] = intersect(MAIN.PC_types,PCvars);
MAIN.PC_data = MAIN.PC_data(:,idx);
if(isempty(idx))
    MAIN.PC_data = [];
    MAIN.PC_weight = 1;
    MAIN.PC_types = {};
    MAIN.PCPTS = 1;
    set(MAIN.hMETA.PCPTS,'String',int2str(MAIN.PCPTS));
end    

%UI figure
fig_width = 0.15;
fig_height = 0.2;
borders = 0.02;
close(findobj(0,'Name','Phase cycling program'));
hPCMAIN = figure('Name','Phase cycling program','NumberTitle','off',...
            'Visible','on','Units','normalized','MenuBar','None',...
            'Position', [0.4,0.5,fig_width,fig_height],...
            'CloseRequestFcn',{@window_close MAIN},...
            'windowstyle','modal');

%Buttons
button_height = 0.10;
button_width = [1 1]; 
button_width = button_width/sum(button_width);
button_width_sum = cumsum([0 button_width(1:end-1)]);        
        
%Table
tab_width = 1;
tab_height = 1-1.5*button_height;
tab_Y = 0;
hPCTABLE = uitable('Visible','on','Units','normalized','FontUnits','Normalized',...
            'Position',[0.5-tab_width/2,tab_Y+borders,tab_width,tab_height],'FontSize',0.08);
set(hPCTABLE, 'RowName', '');

nbPC = length(MAIN.PC_types);
if(nbPC > 0)
    titles = cell(1,nbPC+1);
    titles{1} = '# Weight #';
    titles(2:end) = MAIN.PC_types;
    set(hPCTABLE, 'ColumnName', titles);
    set(hPCTABLE, 'ColumnFormat', {[]});
    set(hPCTABLE, 'ColumnEditable', true(1,nbPC+1));
    set(hPCTABLE, 'Data', [MAIN.PC_weight MAIN.PC_data]);
end

set(hPCTABLE, 'CellSelectionCallback', {@PCtableCellSelected});
set(hPCTABLE, 'CellEditCallback', {@PCtableCellModified MAIN}); %For shape 

%Add PC to table
uicontrol('Style','push','String','+',...
         'Units','normalized','FontUnits','Normalized','Position',...
         [button_width_sum(1),1-button_height,button_width(1),button_height],...
         'Callback',{@add_button MAIN hPCTABLE});

%Remove PC from table
uicontrol('Style','push','String','-',...
         'Units','normalized','FontUnits','Normalized','Position',...
         [button_width_sum(2),1-button_height,button_width(2),button_height],...
         'Callback',{@delete_button MAIN hPCTABLE});
       
%UI resize function
set(hPCMAIN, 'ResizeFcn',{@window_resize hPCTABLE});
end

function PCtableCellSelected(hobj,event)
    %Keep current selected cell in memory for add/delete
    set(hobj,'UserData',event.Indices);
end

function PCtableCellModified(hobj,event,MAIN)
    cursorPos = event.Indices;
    table_data = get(hobj,'Data');
    new_val = table_data(cursorPos(1),cursorPos(2));
    
    %Must be numerical value only here
    if(isnan(new_val))
        table_data(cursorPos(1),cursorPos(2)) = ...
                    MAIN.PC_data(cursorPos(1),cursorPos(2)-1);
        set(hobj,'Data',table_data);
        msgbox('Input must be numeric.');
        return;
    end
    
    if(cursorPos(2) == 1) %Weight column
        MAIN.PC_weight(cursorPos(1),1) = new_val;
    else %All other PC columns (WARNING: cursorPos-1 for PG.PC/table)
        PCname = MAIN.PC_types{cursorPos(2)-1};

        %Check all modules that new value is adequate
        for ct = 1:length(MAIN.mods)
            flag = MAIN.mods{ct}.param_check('PC',PCname,new_val);
            if(~flag)
                table_data(cursorPos(1),cursorPos(2)) = ...
                    MAIN.PC_data(cursorPos(1),cursorPos(2)-1);
                set(hobj,'Data',table_data);
                return;
            end
        end
        
        %Accept value
        MAIN.PC_data(cursorPos(1),cursorPos(2)-1) = new_val;
    end
end

function add_button(~,~,MAIN,hPCTABLE)
    if(~isempty(MAIN.PC_types))
        old_table_data = get(hPCTABLE, 'Data');

        cursorPos = get(hPCTABLE, 'UserData');

        if(isempty(cursorPos))
            new_table_data = old_table_data;
            new_table_data(end+1,:) = 0;
        else
            new_table_data = zeros(size(old_table_data,1)+1,size(old_table_data,2));
            new_table_data([1:cursorPos(1) cursorPos(1)+2:end],:) = old_table_data;
            new_table_data(cursorPos(1)+1,:) = old_table_data(cursorPos(1),:);
        end
        set(hPCTABLE, 'Data', new_table_data);

        MAIN.PC_weight = new_table_data(:,1);
        MAIN.PC_data = new_table_data(:,2:end);
        
        MAIN.PCPTS = length(MAIN.PC_weight);
    else
        MAIN.PCPTS = 1;
        MAIN.PC_weight = 1;
    end
    
    %Update PCPTS UI
    set(MAIN.hMETA.PCPTS,'String',int2str(MAIN.PCPTS));
end

function delete_button(~,~,MAIN,hPCTABLE)
    if(~isempty(MAIN.PC_types))
        cursorPos = get(hPCTABLE, 'UserData');
        if(~isempty(cursorPos) && size(MAIN.PC_data,1) > 1)
            old_table_data = get(hPCTABLE, 'Data');
            new_table_data = old_table_data([1:cursorPos(1)-1 cursorPos(1)+1:end],:);        
            set(hPCTABLE, 'Data', new_table_data);  

            MAIN.PC_weight = new_table_data(:,1);
            MAIN.PC_data = new_table_data(:,2:end);

            set(hPCTABLE, 'UserData', []); %delete cursorPos
            
            MAIN.PCPTS = length(MAIN.PC_weight);
        end
    else
        MAIN.PCPTS = 1;
        MAIN.PC_weight = 1;
    end
    
    %Update PCPTS UI
    set(MAIN.hMETA.PCPTS,'String',int2str(MAIN.PCPTS));
end

%Closing phase cycling GUI
function window_close(~,~,MAIN)
    figure(findobj(0,'Name','GARII: parameters'));
    delete(findobj(0,'Name','Phase cycling program'));
    
    %Call user defined events for each module when variables are updated.
    for ct = 1:length(MAIN.mods)
        temp = MAIN.mods{ct};

        if(~isempty(temp.PCwindowClosing))
            temp.PCwindowClosing();
        end
    end
end

%Window resizing update
function window_resize(hPCMAIN,~,hPCTABLE)
    screen_width = get(0,'ScreenSize');
    fig_width = get(hPCMAIN(1),'Position');
    tab_width = get(hPCTABLE,'Position');
    nbPC = size(get(hPCTABLE, 'Data'),2);
    
    if(nbPC > 0)
        col_width = max(100,screen_width(3)*fig_width(3)*tab_width(3)/(nbPC+0.01));
        set(hPCTABLE, 'ColumnWidth', {col_width});
    end
end

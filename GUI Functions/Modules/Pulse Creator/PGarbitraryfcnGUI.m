%% Arbitrary waveform
%Arbitrary function generator
function PGarbitraryfcnGUI(~,~,PG)
    %Create new window
    fig_width = 0.3;
    fig_height = 0.25;
    
    close(findobj(0,'Name','AWG arbitrary pulse shaping'));
    figure('Name','AWG arbitrary pulse shaping','NumberTitle','off',...
                'Visible','on','Units','normalized','MenuBar','None',...
                'Position', [0.6,0.5,fig_width,fig_height],...
                'CloseRequestFcn',@window_close,...
                'windowstyle','modal');
            
    %Create plot
    time = 0; Idata = zeros(1000,1); Qdata = zeros(1000,1);
    hARB_PLOT = plot(time,Idata,time,Qdata);
    set(hARB_PLOT(1),'XDataSource','time','YDataSource','Idata');
    set(hARB_PLOT(2),'XDataSource','time','YDataSource','Qdata');

    plot_height = 0.53;
    plot_width = 0.6;
    borders = 0.02;
    set(gca,'Units','Normalized','FontUnits','Normalized',...
            'Position',[6*borders 1-3*borders-plot_height plot_width plot_height],...
            'FontSize',0.12)
    xlabel('Time (Duration - e.g. 1000 ns for functions)');
    ylabel('Signal');
    axis([0 1 -1 1]);
    
    %Create input controls
    %Help
    hARB_HELP = uicontrol('Style','text','Visible','on','String',...
              ['The output pulse is modulated by the Pulse parameters in the '....
              'Sequence creation table.'],...
              'Units','normalized','FontUnits','Normalized',...
              'Position',[0.015    0.05    1-2*0.019    0.05]);
          
    %Input function
    uicontrol('Style','text','Visible','on','String','Input function:',...
              'Units','normalized','FontUnits','Normalized',...
              'Position',[0.015    0.15    0.15    0.05]);
    hARB_TEXT = uicontrol('Style','edit','Visible','on','String',...
              'Matlab code, e.g. sin(2*pi*(10*t).*t + pi/8) (Time in ns!)',...
              'Units','normalized','FontUnits','Normalized',...
              'Position',[0.18    0.15    0.8    0.05],...
              'Callback',{@arbitrary_plot_update  hARB_PLOT hARB_HELP});
          
    %Create button
    uicontrol('Style','push','Visible','on','String','Load file',...
              'Units','normalized','FontUnits','Normalized',...
              'Position',[plot_width+7.5*borders 0.8 0.23 0.15],...
              'Callback',{@arbitrary_pulse_load PG hARB_TEXT hARB_PLOT hARB_HELP});
          
    uicontrol('Style','push','Visible','on','String','Save function',...
              'Units','normalized','FontUnits','Normalized',...
              'Position',[plot_width+7.5*borders 0.6 0.23 0.15],...
              'Callback',{@arbitrary_pulse_save PG hARB_TEXT});
          
    uicontrol('Style','push','Visible','on','String','Accept',...
              'FontWeight','Bold',...
              'Units','normalized','FontUnits','Normalized',...
              'Position',[plot_width+7.5*borders 0.4 0.23 0.15],...
              'Callback',{@arbitrary_pulse_accept hARB_TEXT hARB_PLOT hARB_HELP PG});
end

%Update plot in arbitrary pulse generator when text is edited
function load_error = arbitrary_plot_update(hARB_TEXT,~,hARB_PLOT,hARB_HELP)
    load_error = 0;

    %Convert text to pulse
    text = get(hARB_TEXT,'String');
    try
        %Create pulse for plotting
        if(length(text) > 4 && strcmp('.mat',text(end-3:end))) %mat file with values
            text_data = load(text);
            text_data = text_data.data; %ANY NAME WOULD BE BETTER!!!!!

            time = text_data(:,1)/text_data(end,1); %#ok<NASGU>
            ydata = text_data(:,2:end);
            if(~any(ydata))
                error('Data cannot be all zero');
            end

        else %function from either loaded script or input writing
            fun = @(t) eval(text);
            
            Tend = 1000; %This is just an example for plotting
            time = linspace(0,Tend,1000).';
            ydata = fun(time);
                
            time = time/Tend; %#ok<NASGU>
        end        
        
        Idata = ydata(:,1)/max(abs(ydata(:)));
        if(size(ydata,2) == 2)
            Qdata = ydata(:,2)/max(abs(ydata(:))); %#ok<NASGU>
        else
            Qdata = 0*Idata; %#ok<NASGU>
        end
        
        %Plot update (uses time,Idata,Qdata)
        refreshdata(hARB_PLOT(1),'caller');
        refreshdata(hARB_PLOT(2),'caller');
        
        set(hARB_HELP,'String',...
            ['The output pulse is modulated by the Pulse parameters in the '...
            'Sequence creation table.']);
    catch
        load_error = 1;
        set(hARB_HELP,'String','This is not a valid Matlab code/data file.');
    end
end

%Load arbitrary pulse from Matlab file
function arbitrary_pulse_load(~,~,PG,hARB_TEXT,hARB_PLOT,hARB_HELP)
    [filename, pathname, file_type] = uigetfile({'*.m'; '*.mat'},'Open',...
                               [PG.MAIN.root_path 'Library' filesep 'Pulse library']);
    
    if(filename ~= 0)
        switch(file_type)
            case 1 %.m file           
                set(hARB_TEXT,'String',[filename(1:end-2) '(t)']);
                
            case 2 %.mat file
                set(hARB_TEXT,'String',[pathname filename]);  
        end
    end
    
    arbitrary_plot_update(hARB_TEXT,[],hARB_PLOT,hARB_HELP);
end

%Save arbitrary pulse to Matlab file
function arbitrary_pulse_save(~,~,PG,hARB_TEXT)
    [filename, pathname] = uiputfile('*.m','Save as',...
                           [PG.MAIN.root_path 'Library' filesep ...
                           'Pulse library' filesep 'ArbPulse.m']);
    if(filename ~= 0)
        fid = fopen([pathname filename], 'w');
        
        fprintf(fid,['function y = ' filename(1:end-2) '(t)\n' ...
                     'y = ' get(hARB_TEXT,'String') '; \nend']);
        
        fclose(fid);
    end
end

%Accept and go back to sequence table
function arbitrary_pulse_accept(~,~,hARB_TEXT,hARB_PLOT,hARB_HELP,PG)
    load_error = arbitrary_plot_update(hARB_TEXT,[],hARB_PLOT,hARB_HELP);
    if(load_error)
        msgbox('This is not a valid Matlab code/data file. Cannot accept.');
        return;
    end
    
    name = inputdlg({'Pulse shape name:'});
    if(~isempty(name))
        table_col_format = get(PG.hTABLE, 'ColumnFormat');
        
        shape_list = 'Square';
        if(~isempty(PG.library))
            shape_list = [shape_list PG.library(:,1).'];
        end
        
        %Check if new name already exists
        continue_flag = 1;
        arb_pulse_idx = find(strcmpi(shape_list,name{1}) == 1);
        if(~isempty(arb_pulse_idx))
            question = questdlg({'Pulse shape name already exists. Overwrite?'},...
                '','Yes','No','No');
            switch(question)
                case 'Yes' %Overwrite, i.e. accept without change
                    continue_flag = 2; 
                    
                case 'No' %Do not accept
                    continue_flag = 0;
                
                otherwise
                    continue_flag = 0;
            end
        end   
        
        %Write
        if(continue_flag ~= 0) 
            text = get(hARB_TEXT,'String');
            if(length(text) > 4 && strcmp('.mat',text(end-3:end))) %mat file with values
                pulse = load(text);
                pulse = pulse.data;
            else
                pulse = text;
            end
            
            if(continue_flag == 1)
                %Update table
                table_col_format{PG.tabcol({'SHAP'})}{end+1} = name{1};
                set(PG.hTABLE, 'ColumnFormat', table_col_format);
                
                %Add to library
                PG.update_library({name{1} pulse});
            elseif(continue_flag == 2)
                %Overwrite library
                PG.update_library(arb_pulse_idx,{name{1} pulse});
            end
            
            window_close([],[]);
        else
            arbitrary_pulse_accept([],[],hARB_TEXT,hARB_PLOT,hARB_HELP);
        end
    end
end

%Closing GUI
function window_close(~,~)
    figure(findobj(0,'Name','GARII: parameters'));
    delete(findobj(0,'Name','AWG arbitrary pulse shaping'));
end
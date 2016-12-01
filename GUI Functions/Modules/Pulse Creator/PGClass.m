classdef PGClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% PGClass is a GARII Module %%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%% Pulse generator/compiler (mostly for the AWG) %%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %PulseGUIClass holds all the parameters for the pulseGUI.
    
    %Main parameters
    properties (Access = public)
        %Table
        tables = {'MAIN'}; %Tables name
        
        %Data = pulse table parameters
        data_types = {'FREQ' 'PHAS' 'AMPL' 'DURA' 'STAR' 'PERI' 'NBPE' ...
                      'SHAP' 'CHAN'};
        param_type = 1:7; %'FREQ' 'PHAS' 'AMPL' 'DURA' 'STAR' 'PERI' 'NBPE'
        data = cell(1); %table data: {ctTable} = [param_row]
        
        %Compile data
        EXP
        skip_compile = 0; %This flag is to skip compiling (TO DO)

        %Library = arbitrary pulse data
        %{name, data = (time,I) OR (time,I,Q) OR script string}
        library = {};  
    end
    
    %GUI parameters
    properties (Access = public)
        hTABLE %Table handle
        hSUBTABLE %Subtable control handle
        
        hPLOT %Pulse plotter
        hPLOTCONTROL %Pulse plotter control
    end
    
    %Main methods
    methods (Access = public)
        function obj = PGClass()
            obj.name = 'Pulse Creator';
            
            obj.add_pulse_to_data(1); %1 = Main table
        end
        
        %Class Copy object (Does not copy what is in handle obj)
        %Should be in ModuleClass
        function newObj = copyMod(obj)
            newObj = PGClass();
            
            p = properties(obj);
            for i = 1:length(p)
                newObj.(p{i}) = obj.(p{i});
            end
        end
          
        function ok_flag = experiment_setup(obj) %Compile
            %Duplicate table and create concatenated data from many tables
            PG2 = obj.copyMod(); %IS THIS STILL NECESSARY WITH UPDATED CONC?
            PG2.params = PG2.concatenate_params();
            
            %Launch compiler
            if(~isempty(PG2))
                compData = PGcompiler(PG2);
            else
                ok_flag = 0;
                return;
            end
            
            if(~isempty(compData)) %WHAT ABOUT WARNINGS FROM COMPILE??? ok_flag = ??
                obj.EXP = compData;
                
                %Create sweep vals
                for ct = 1:numel(obj.params)
                    if(isa(obj.params{ct},'ParameterClass'))
                        obj.params{ct}.create_sweep_vals();
                    end
                end
                
                ok_flag = 2; %Continue but do not add PG to instruments
                             %Add params to axis though
            else
                ok_flag = 0;
            end
        end
        
        function ok_flag = experiment_next(~) %Not used
            ok_flag = -1;
        end
        function ok_flag = experiment_stop(~) %Not used
            ok_flag = -1;
        end
        function experiment_trigger(~)
        end %Not used
    end
    
    %VALUES CONVERSION FUNCTIONS
    methods (Access = public)
        %Return data column number from name
        function val = tabcol(obj,string)
            val = zeros(1,length(string));
            for ct = 1:length(string)
                val(ct) = find(strcmp(string{ct},obj.data_types) == 1);
            end
        end
        
        %From an index position in param get [tb row col]
        function dataPos = ind2sub(obj,cursorPos)
            if(~isempty(cursorPos))
                [param_row, col] = ind2sub(size(obj.params),cursorPos);
                for ctTb = 1:length(obj.data)
                    row = find(obj.data{ctTb} == param_row,1);
                    if(~isempty(row))
                        dataPos = [ctTb row col];
                        return;
                    end
                end
            end
            dataPos = [];
        end
        
        %From [tb row col] get index position in param
        function cursorPos = sub2ind(obj,dataPos)
            idx = obj.data{dataPos(1)}(dataPos(2));
            cursorPos = sub2ind(size(obj.params),idx,dataPos(3));
        end
        
        %Gives real value for given columns for specific row of params,X,Y,PC
        %Used in compiler
        function values = row_to_values(obj,row_params,ctX,ctY,ctPC)
            values = zeros(1,length(row_params));
            for ctCol = 1:length(row_params)
                val = row_params{ctCol}.get_values(ctX,ctY,ctPC);
                if(~isempty(val)) %May happen if variable called but not defined
                    values(ctCol) = val;
                else
                    values = [];
                    return;
                end
            end
        end 
    end
    
    %TABLE MODIFICATION FUNCTIONS
    methods (Access = public)
        %Add pulse (row) to data
        %cursorPos = [table_index] (row_index = auto last) or [table_index row_index]
        function add_pulse_to_data(obj,cursorPos)
            tb = cursorPos(1);
            if(tb < 1  || tb > length(obj.data))
                 error('@(PG.add_pulse_to_data)  Table index invalid');
            end
            
            old_data = obj.data{tb};
            
            new_idx = size(obj.params,1)+1;
            
            %Only table given, add to the end 
            if(length(cursorPos) == 1)
                obj.params(new_idx,:) = {...
                    ParameterClass(obj,'FREQ','Frequency (MHz)',{1 0 0 1},@obj.FREQ_check,[]) ...
                    ParameterClass(obj,'PHAS','Phase (Deg)',{1 0 0 1},@obj.PHAS_check,[]) ...
                    ParameterClass(obj,'AMPL','Amplitude (a.u.)',{1 0 0 1},@obj.AMPL_check,[]) ...
                    ParameterClass(obj,'DURA','Duration (ns)',{1 0 0 1},@obj.DURA_check,[]) ...
                    ParameterClass(obj,'STAR','Start time (ns)',{1 0 0 1},@obj.STAR_check,[]) ...
                    ParameterClass(obj,'PERI','Period (ns)',{1 0 0 1},@obj.PERI_check,[]) ...
                    ParameterClass(obj,'NBPE','Nb of Periods',{1 1 0 1},@obj.NBPE_check,[]) ...
                    'Square' ...
                    'MW'};
                
                new_data = [old_data new_idx];
                
            else %Add after cursor position (for params always at the end)
                row = cursorPos(2);
                if(row < 1  || row > length(obj.data{tb}))
                     error('@(PG.add_pulse_to_data)  Row index invalid');
                end
                
                for ct = 1:size(obj.params,2)
                    if(isa(obj.params{old_data(row),ct},'ParameterClass'))
                        obj.params{new_idx,ct} = obj.params{old_data(row),ct}.copy();
                    else
                        obj.params{new_idx,ct} = obj.params{old_data(row),ct};
                    end
                end
                
                new_data = [old_data(1:row) new_idx old_data(row+1:end)];
            end
            
            obj.data{tb} = new_data;
        end
        
        %Delete pulse (row) from data
        function delete_pulse_from_data(obj,cursorPos)
            tb = cursorPos(1);
            row = cursorPos(2);
            
            if(tb < 1  || tb > length(obj.data))
                 error('@(PG.delete_pulse_to_data)  Table index invalid');
            end
            if(row < 1  || row > length(obj.data{tb}))
                 error('@(PG.delete_pulse_to_data)  Row index invalid');
            end
            
            bad_row = obj.data{tb}(row);
            
            %Remove from params
            remain_idx = setdiff(1:size(obj.params,1),bad_row);
            obj.params = obj.params(remain_idx,:);
            
            %Remove from data
            for ctTb = 1:length(obj.data) %reduce all row above bad_row by 1
                new_data = obj.data{ctTb};
                new_data(new_data > bad_row) = new_data(new_data > bad_row) - 1;
                obj.data{ctTb} = new_data;
            end
            obj.data{tb} = obj.data{tb}([1:row-1 row+1:end]);
        end
        
        %Load new parameters (special version of the one in moduleClass)
        function load_new_params(obj,new_params)
            %It is assumed here that the right PG.data was loaded
            cur_data = obj.data;

            obj.params = {};
            for ctTb = 1:length(cur_data)
                for ctRow = 1:length(cur_data{ctTb})
                    obj.add_pulse_to_data(ctTb); %This is necessary to get the right check fun
                end
            end

            obj.data = cur_data; %add_pulse_to_data modifies data too, which we do 
                                                %not want here

            %Now load new_params 
            obj.std_params_load(new_params); %ModuleClass function
        end
        
        %Send data to table UI
        function send_data_to_table(obj,table_idx)
            if(table_idx < 1  || table_idx > length(obj.data))
                 error('@(PG.send_data_to_table)  Table index invalid');
            end
            
            %Update cursorPos
            obj.MAIN.UserData{2} = obj.sub2ind([table_idx 1 1]);

            %Update table
            data_str = cell(length(obj.data{table_idx}),size(obj.params,2));
            for ctRow = 1:length(obj.data{table_idx});
                real_row = obj.data{table_idx}(ctRow);

                for ctCol = obj.param_type %data types
                    data_str{ctRow,ctCol} = obj.params{real_row,ctCol}.make_label;
                end
                for ctCol = setdiff(1:size(data_str,2),obj.param_type) %shape/channel
                    data_str{ctRow,ctCol} = obj.params{real_row,ctCol};
                end
            end

            set(obj.hTABLE, 'Data', data_str);
        end
    
        %This function concatenate all tables.
        %THIS FUNCTION IS NOT FINISHED: NEED TO DEAL PROPERLY WITH
        %INHERITANCE
        function full_params = concatenate_params(obj,varargin) 
            if(isempty(varargin))
                lvl = 1;
            else
                lvl = varargin{1};
                if(lvl > 10)
                    check = questdlg('Table concatenation level is > 10. Is that correct?',...
                                     'Warning','Yes','No','No');
                    if(strcmp(check,'No'))
                        full_params = [];
                        return;
                    end                                     
                end
            end            
            
            full_params = {};
            for ctRow = 1:length(obj.data{lvl})
                row_idx = obj.data{lvl}(ctRow);
                
                shape_name = obj.params{row_idx,obj.tabcol({'SHAP'})};
                table_idx = find(strcmp(shape_name,obj.tables) == 1);
                
                if(~isempty(table_idx))
                    new_params = obj.concatenate_params(table_idx);
                    
                    %Modify values of subtable
                    typeplus = {'STAR'};
                    typetime = {'AMPL'};
                    type = [typeplus typetime];
                    
                    for ctType = 1:length(type)
                        start_col = obj.tabcol({type{ctType}});
                        start = obj.params{row_idx,start_col}.param;
                        for ctRowSub = 1:size(new_params,1)
                            sub_start = new_params{ctRowSub,start_col}.param;

                            switch(type{ctType})
                                case typetime
                                    new_params{ctRowSub,start_col}.param{2} = ...
                                        start{2}*sub_start{2}; %Start val
                                    new_params{ctRowSub,start_col}.param([1 3 4]) = ...
                                                        start([1 3 4]);
                                case typeplus
                                    new_params{ctRowSub,start_col}.param{2} = ...
                                        start{2} + sub_start{2}; %Start val
                                    %Sweeps (linear only)
                                    if(start{1} ~= 1 && sub_start{1} ~= 1 && ...
                                       start{4} == 1 && sub_start{4} == 1)
                                        new_params{ctRowSub,start_col}.param{3} = ...
                                            start{3} + sub_start{3}; %Step val
                                    elseif(start{1} ~= 1 && start{4} == 1)
                                            new_params{ctRowSub,start_col}.param([1 3 4]) = ...
                                                        start([1 3 4]);
                                    end
                            end
                        end
                    end
                    
                    full_params(end+(1:size(new_params,1)),:) = new_params; %#ok<AGROW>
                else
                    %Because params are handle, we have to do a copy here                    
                    full_params(end+1,:) = cell(1,size(obj.params,2)); %#ok<AGROW>
                    for ctCol = 1:size(obj.params,2)
                        if(isa(obj.params{row_idx,ctCol},'ParameterClass'))
                            full_params{end,ctCol} = obj.params{row_idx,ctCol}.copy;  %#ok<AGROW>
                        else
                            full_params{end,ctCol} = obj.params{row_idx,ctCol}; %#ok<AGROW>
                        end     
                    end
                end
            end
            
        end
    end
    
    %ARBITRARY WAVEFORM FUNCTIONS
    methods (Access = public)
        %Find a pulse in the library by its name
        function arb_pulse_idx = find_pulse_in_library(obj,pulse)
            if(~isempty(obj.library))
                arb_pulse_idx = find(strcmp(pulse,obj.library(:,1)) == 1);
            else
                arb_pulse_idx = [];
            end
        end
        
        %Add or replace pulse in library
        function update_library(obj,varargin)
            if(nargin == 2) %Add
                obj.library(end+1,:) = varargin{1};       
            elseif(nargin == 3) %Replace
                obj.library(varargin{1},:) = varargin{2};
            end
        end
    end
   
    %GLOBAL AND SWEEP PARAMETERS EDIT
    methods (Access = public)
        %Called when global metadata is edited
        %Returns new values to shown in sweep if necessary
        function metadataEdit_fun(obj,~,~)
            %Update plot slider
            obj.plot_slider_update();
        end

        %Actions when sweep, sweep type, start value, step value are edited
        function sweepControlsEdit_fun(obj)
            cursorPos = obj.MAIN.UserData{2};

            %Update table
            new_data_str = get(obj.hTABLE, 'Data');
            dataPos = obj.ind2sub(cursorPos);

            if(~isempty(dataPos))
                new_data_str{dataPos(2),dataPos(3)} = obj.params{cursorPos}.make_label;
                set(obj.hTABLE, 'Data', new_data_str);

                %Update plot slider
                obj.plot_slider_update();

                %Update plot
               obj.plot_update();
            end
        end

        %Called when the variable/PC window is closed
        function PCwindowClosing_fun(obj)
            obj.plot_update();
            obj.plot_slider_update();
        end
    end

    %PULSE PARAMETERS
    methods (Access = public)
        %Actions when a cell is selected in the table
        %Only for value type (all but CHAN or SHAP)
        function tableCellSelected(obj,~,event)
            %Get cursor position (give to UserData) and update sweep control
            if(size(event.Indices,1) == 1)
                dataPos = [get(obj.hSUBTABLE,'Value') event.Indices];

                if(any(dataPos(3) == obj.param_type))
                    %Send cursorPos to UserData and send values to sweep control
                    obj.paramSelect([],[],obj.sub2ind(dataPos));
                end
            end
        end

        %Actions when a cell is modified in the table
        %Only for list type (only CHAN or SHAP)
        function tableCellModified(obj,~,event)
            if(size(event.Indices,1) == 1)
                cursorPos = [get(obj.hSUBTABLE,'Value') event.Indices];

                %Get current table strings
                cur_data_str = get(obj.hTABLE,'Data');

                %Update params
                obj.params{obj.sub2ind(cursorPos)} = cur_data_str{cursorPos(2),cursorPos(3)};

                %If acquisition, force modify shape value to acquisition too
        %         chan_str = PG.params{PG.sub2ind([cursorPos(1) cursorPos(2) PG.tabcol({'CHAN'})])};
        %         if(strcmp(chan_str,'Acquisition'))
        %             cur_data_str{cursorPos(2),PG.tabcol({'SHAP'})} = 'Acquisition';
        %         end

                %If shape belong to arbitrary shape library, force modify table values
                shap_str = obj.params{obj.sub2ind([cursorPos(1) cursorPos(2) obj.tabcol({'SHAP'})])};
                arb_pulse_idx = obj.find_pulse_in_library(shap_str);

                if(~isempty(arb_pulse_idx) && isnumeric(obj.library{arb_pulse_idx,2}))
                    cur_data_str{cursorPos(2),obj.tabcol({'DURA'})} = ...
                                num2str(max(obj.library{arb_pulse_idx,2}(:,1)));
                end

                %Update table
                set(obj.hTABLE, 'Data', cur_data_str);

                %Update plot
                obj.plot_update();
            end
        end

        %Adds one line in the pulse table after the current selected row
        function addpulse(obj,~,~)
            old_data_str = get(obj.hTABLE, 'Data');
            cursorPos = obj.ind2sub(obj.MAIN.UserData{2});

            %NOT VERY GOOD: should call directly start value of param
            if(isempty(cursorPos))
                cursorPos = get(obj.hSUBTABLE,'Value');
                new_data_str = old_data_str;
                new_data_str(end+1,:) = {'0' '0' '0' '0' '0' '0' '1' 'Square' 'MW'};
            else
                row = cursorPos(2);
                new_data_str = cell(size(old_data_str,1)+1,size(old_data_str,2));
                new_data_str([1:row row+2:end],:) = old_data_str;
                new_data_str(row+1,:) = old_data_str(row,:);
            end

            obj.add_pulse_to_data(cursorPos);
            set(obj.hTABLE, 'Data', new_data_str)
        end

        %Remove one line in the pulse table after the current selected row
        function deletepulse(obj,~,~)
            cursorPos = obj.ind2sub(obj.MAIN.UserData{2});

            if(~isempty(cursorPos) && length(obj.data{cursorPos(1)}) > 1)
                %Update table
                row = cursorPos(2);
                old_data_str = get(obj.hTABLE, 'Data');
                new_data_str = old_data_str([1:row-1 row+1:end],:);        
                set(obj.hTABLE, 'Data', new_data_str);  

                %Delete pulse
                obj.delete_pulse_from_data(cursorPos);

                %Delete local pos
                obj.MAIN.UserData{2} = []; 

                %Update plot
                obj.plot_update();
            end
        end
    end
    
    %PLOT/UI UPDATE
    methods (Access = public)
        %Update plot when changing X or Y slider position
        function plot_update(obj,~,~)
            [timedata,plotdata] = obj.make_plot_from_data();

            %Time axis unit
            if(~isempty(timedata) & ~isnan(timedata)) %#ok<AND2>
                maxTime = max(timedata);
                switch(1)
                    case maxTime < 1e3
                        time = timedata; %#ok<*NASGU>
                        xlabel('Time (ns)');

                    case maxTime >= 1e3 && maxTime < 1e6
                        time = timedata*1e-3;
                        xlabel('Time (\mus)');

                    case maxTime >= 1e6 && maxTime < 1e9
                        time = timedata*1e-6;
                        xlabel('Time (ms)');

                    case maxTime >= 1e9
                        time = timedata*1e-9;
                        xlabel('Time (s)'); 
                end
                
                for ct = 1:length(obj.hPLOT)
                    ydata = plotdata(ct,:);
                    if(~any(isnan(ydata) | isinf(ydata)))
                        set(obj.hPLOT(ct),'XDataSource','time','YDataSource','ydata');
                        refreshdata(obj.hPLOT(ct),'caller');
                        axis(gca,'tight')
                    end
                end
            end
        end

        %This function provides the X and Y axis for plotting the pulse sequence
        function [time,plotdata] = make_plot_from_data(obj)
            chtype = {'MW' 'RF' 'User'};

            ctX = round(get(obj.hPLOTCONTROL(1),'Value'));
            ctY = round(get(obj.hPLOTCONTROL(2),'Value'));
            ctPC = round(get(obj.hPLOTCONTROL(3),'Value'));

            %Concatenate table
            params = obj.concatenate_params();

            %Check which channel is selected for plotting (or always Acquisition)
            k = 0;
            channel_rows = [];
            for ctRow = 1:size(params,1)
                cur_chan = params{ctRow,obj.tabcol({'CHAN'})};
                if(strcmp(cur_chan,chtype{get(obj.hPLOTCONTROL(4),'Value')}) || ...
                   strcmp(cur_chan,'Acquisition'))
                    k = k + 1;
                    channel_rows(k) = ctRow; %#ok<AGROW>
                end
            end

            %Convert data to matrix
            values = zeros(size(params,1),length(obj.param_type));
            bound = zeros(size(params,1),length(obj.param_type),2); %min-max
            for ctRow = 1:size(params,1)
                for ctCol = 1:length(obj.param_type)
                    cur_par = params{ctRow,ctCol};

                    %Get values for specific X,Y,PC
                    val = cur_par.get_values(ctX,ctY,ctPC);
                    if(~isempty(val)) %val = [] can happen when loading but no PC given
                        values(ctRow,ctCol) = val;

                        %Bound values for plot normalization
                        [bound(ctRow,ctCol,1), bound(ctRow,ctCol,2)] = ...
                            cur_par.get_sweep_min_max(ctPC);
                    else
                        values(ctRow,ctCol) = nan;
                        bound(ctRow,ctCol,:) = nan;
                    end
                end
            end   
            norm = max(abs([min(bound(:,:,1),[],1); max(bound(:,:,2),[],1)]),[],1);

            %Create time axis (WILL NOT WORK FOR NEGATIVE SWEEP)
            pt_per_pulse = 4;

            %Tend = start + duration + period*(period_nb-1)
            Tend = max(values(:,5) + values(:,4) + values(:,6).*(values(:,7)-1));

            dt = min(values(values(:,4)~=0,4))/pt_per_pulse;
            if(dt ~= 0)
                if(round(Tend/dt) > 1e5)
                    time = [0 Tend];
                    plotdata = zeros(4,2);
                    return;
                end
                time = 0:dt:Tend;
            else
                time = 0;
            end

            %Create Y data axis
            dataIdx = [1 2 3]; %Freq,Phase,Amp to plot

            plotdata = zeros(length(dataIdx),length(time));
            for ct = 1:length(dataIdx)
                idx = dataIdx(ct);

                if(~isempty(channel_rows))
                    maxVal = zeros(length(channel_rows),1);
                    for ctRow = channel_rows
                        %Create plot data
                        for ctPer = 1:values(ctRow,7)
                            start_val = values(ctRow,5) + values(ctRow,6)*(ctPer-1);
                            time_idx = find(time >= start_val & ...
                                            time <= (start_val + values(ctRow,4)));
                            plotdata(ct,time_idx) = plotdata(ct,time_idx) + values(ctRow,idx);
                        end
                    end

                    if(norm(dataIdx(ct)) ~= 0)
                        plotdata(ct,:) = plotdata(ct,:)/norm(dataIdx(ct));
                    end
                end
            end 

            %Remove too many zeros
            non_zero_idx = find(abs(plotdata(3,:)) ~= 0); %amp = 0
            non_zero_idx = max(1,min(length(time), ...
                unique([1 non_zero_idx-1 non_zero_idx non_zero_idx+1 length(time)])));
            time = time(non_zero_idx);
            plotdata = plotdata(:,non_zero_idx);
        end

        %Update X,Y slider (plotting window)
        function plot_slider_update(obj)
            %X channel
            val = obj.MAIN.XPTS;
            if(val == 1)
                set(obj.hPLOTCONTROL(1),'Enable','off');
            else
                set(obj.hPLOTCONTROL(1),'Enable','on','Max',val,'Value',1,...
                                  'SliderStep',[1/(val-1) max(0.1,1/(val-1))]);
            end

            %Y channel
            val = obj.MAIN.YPTS;
            if(val == 1)
                set(obj.hPLOTCONTROL(2),'Enable','off');
            else
                set(obj.hPLOTCONTROL(2),'Enable','on','Max',val,'Value',1,...
                                  'SliderStep',[1/(val-1) max(0.1,1/(val-1))]);
            end

            %PC channel
            val = length(obj.MAIN.PC_weight);
            if(val < 2)
                set(obj.hPLOTCONTROL(3),'Enable','off');
            else 
                set(obj.hPLOTCONTROL(3),'Enable','on','Max',val,'Value',1,...
                                  'SliderStep',[1/(val-1) max(0.1,1/(val-1))]);
            end
        end

        %Update all UI. Varargin = table idx (default = 1)
        function update_all_UI(obj,varargin)
            if(isempty(varargin))
                table_idx = 1;
            else
                table_idx = varargin{1};
            end

            %Update table
            set(obj.hSUBTABLE,'String',obj.tables,'Value',table_idx);
            obj.send_data_to_table(table_idx);

            %Update library
            if(~isempty(obj.library))
                table_col_format = get(obj.hTABLE, 'ColumnFormat');
                table_col_format{obj.tabcol({'SHAP'})} = ['Square' obj.library(:,1).'];
                table_col_format{obj.tabcol({'SHAP'})}(end+(1:(length(obj.tables)-1))) = obj.tables(2:end);
                set(obj.hTABLE, 'ColumnFormat', table_col_format);
            end

            %Update plot
            obj.plot_update();
            obj.plot_slider_update();
        end

        %Check sequence (do compile)
        function check_sequence(obj,~,~)
            if(~isempty(obj.child_mods) && ~isempty(strfind(obj.child_mods{1}.ID,'AWG')))
                %Duplicate table and create concatenated data from many tables
                PG2 = obj.copyMod();
                PG2.params = obj.concatenate_params();

                %PG compiler
                EXPtemp = PGcompiler(PG2);
                if(~isempty(EXPtemp))
                    obj.EXP = EXPtemp;

                    %AWG compiler
                    AWG = obj.child_mods{1};
                    AWG.compile();

                    %Plot
                    ctX = round(get(obj.hPLOTCONTROL(1),'Value'));
                    AWGplotcheck(AWG,ctX);
                end
            else
                msgbox('Requires AWG module.');
            end
        end
        
        %Window resizing update
        function window_resize_fun(obj,hobj,~)
            screen_width = get(0,'ScreenSize');
            fig_width = get(hobj(1),'Position');
            tab_width = get(obj.hTABLE,'Position');

            %Table resize (as cannot be in normalized unit)
            col_width = screen_width(3)*fig_width(3)*tab_width(3)/(length(obj.data_types)+0.2);
            set(obj.hTABLE, 'ColumnWidth', {col_width*1.1 col_width*0.8 col_width*0.9 col_width ...
                                       col_width*1.8 col_width*0.8 col_width col_width*0.8 col_width*0.8});
        end
    end
    
    %SUBTABLES
    methods (Access = public)
        %Add a new subtable to the list
        function addsubtable(obj,~,~)
            %Open dialog to input a new table name
            table_name = inputdlg({'Table name:'});

            if(~isempty(table_name))
                %Check if name already exists
                if(isempty(find(strcmpi(table_name, obj.tables) == 1,1)))
                    new_idx = length(obj.tables)+1;

                    %Update tables library
                    obj.tables(new_idx) = lower(table_name); %Subtables in lower case to
                                                             %separate from MAIN

                    %Update data
                    obj.data{new_idx} = [];

                    %Update table list in GUI
                    set(obj.hSUBTABLE,'String',obj.tables,'Value',new_idx);

                    %Update shape list in GUI
                    col_str = get(obj.hTABLE, 'ColumnFormat');
                    col_str{obj.tabcol({'SHAP'})}(end+1) = lower(table_name);
                    set(obj.hTABLE, 'ColumnFormat', col_str);

                    %Create a dummy pulse for new table
                    obj.add_pulse_to_data(new_idx);

                    %Replace table GUI
                    obj.send_data_to_table(new_idx);  
                else
                    msgbox('Table name already exists');
                    return;
                end
            end
        end

        %Remove a subtable from the list, delete table data
        function deletesubtable(obj,~,~)
            table_idx = get(obj.hSUBTABLE,'Value');

            %Check first of all that table to delete is not main
            if(table_idx == 1)
                msgbox('Cannot delete "MAIN" table');
                return;
            end

            table_name = obj.tables{table_idx};

            %Confirm subtable delete
            answer = questdlg({['Are you sure you want to delete table "' table_name '" ?'] ...
                               '(Table data will be deleted)'},'Deleting table',...
                               'Yes','No','No');
            if(strcmp(answer,'Yes'))
                remain_idx = setdiff(1:length(obj.tables),table_idx);

                %Delete table
                obj.tables = obj.tables(remain_idx);
                set(obj.hSUBTABLE,'String',obj.tables,'Value',1);

                %Remove from shape list in GUI
                col_str = get(obj.hTABLE, 'ColumnFormat');
                col_str{obj.tabcol({'SHAP'})} = col_str{obj.tabcol({'SHAP'})}(...
                    strcmp(table_name,col_str{obj.tabcol({'SHAP'})})~=1);
                set(obj.hTABLE, 'ColumnFormat', col_str);
                for ctRow = 1:size(obj.params,1)
                    if(strcmp(table_name,obj.params{ctRow,obj.tabcol({'SHAP'})}))
                        obj.params{ctRow,obj.tabcol({'SHAP'})} = 'Square';
                    end
                end

                %Delete all table pulse
                while(~isempty(obj.data{table_idx}))
                    obj.delete_pulse_from_data([table_idx length(obj.data{table_idx})]);
                end

                %Go back to PULSE table by default
                obj.send_data_to_table(1);

                %Update plot due to deleted pulse
                obj.plot_update();
            end
        end

        %Update table when a subtable is selected
        function subtableSelected(obj,~,~)
            %Update table
            table_idx = get(obj.hSUBTABLE,'Value');
            obj.send_data_to_table(table_idx);
        end    
    end
    
    %Save/load functions
    methods (Access = public)
        %Save sequence to matlab file
        function savePG(obj,~,~)
            %Create/Open output file
            [filename, pathname] = uiputfile('*.mat','Save as',...
                                   [obj.MAIN.root_path 'Library' filesep 'Sequence library']);

            if(filename ~= 0)
                seq.data = obj.data;
                seq.library = obj.library;
                seq.params = obj.params;
                seq.version = date;

                %Save matlab files for loading
                save([pathname filename(1:end-3) 'mat'],'seq');
            end
        end

        %Load sequence from matlab file
        function loadPG(obj,~,~)
            [filename, pathname] = uigetfile('*.mat','Open',...
                                   [obj.MAIN.root_path 'Library' filesep 'Sequence library']);
            if(filename ~= 0)
                %Load matlab file
                file = load([pathname filename]);

                %Load params,data and library
                obj.library = file.seq.library;
                obj.data = file.seq.data;
                obj.load_new_params(file.seq.params);
                clear file;

                %WHAT ABOUT PC? Right now we'll get variables but nothing loaded in
                %PC

                %Update library, table and plot
                obj.update_all_UI(1);
            end
        end

        %Load for main
        function load_for_main(obj,new_PG)
            if(~isempty(new_PG))
                %Load tables name
                obj.tables = new_PG.tables;
                
                %Load table data
                obj.data = new_PG.data;
                
                %In some old files due to bugs, some pulse may remain but
                %not actually used and called by data. Need to increase
                %data size otherwise file cannot be loaded.
                par_len = size(new_PG.params,1);
                data_len = numel(cell2mat(obj.data));
                if(data_len < par_len)
                    obj.data = [obj.data setdiff(1:par_len,cell2mat(obj.data))];
                    obj.tables = [obj.tables {'*-*ERR*-*'}];
                end
                
                %Load new params         
                new_params = new_PG.params;
                obj.load_new_params(new_params);

                %Load new library
                new_library = new_PG.library;
                obj.library = new_library;
            end

            %Update plot/UI/table
            obj.update_all_UI();
        end
    end
    
    %Parameter check
    methods (Access = private)
        function flag = FREQ_check(obj,value)
            flag = 1;
        end
        function flag = PHAS_check(obj,value)
            flag = 1; 
        end
        function flag = AMPL_check(obj,value)
            flag = 1;
            max_AMP = 1;
            
            if(any(value < -max_AMP | value > max_AMP))
                flag = 0;
                obj.msgbox(['Amplitude must be a |value| < ' num2str(max_AMP) '.'])
            end
        end
        function flag = DURA_check(obj,value)
            flag = 1;
            
            if(any(value < 0))
                flag = 0;
                obj.msgbox('Duration cannot be < 0.')
            end
        end
        function flag = STAR_check(obj,value)
            flag = 1;
            
            if(any(value < 0))
                flag = 0;
                obj.msgbox('Start must be a value > 0.');
            end            
        end
        function flag = PERI_check(obj,value)
            flag = 1;
            
            %HERE SHOULD CHECK PERIOD < DURATION FOR EACH X OR Y VALUE  
            %IF NBPE > 1
            if(0)
                flag = 0;
                obj.msgbox('Period must be an integer > duration.');
            end
        end
        function flag = NBPE_check(obj,value)
            flag = 1;
            
            %HERE SHOULD CHECK PERIOD < DURATION FOR EACH X OR Y VALUE                
            if(any(all(round(value)~=value) | value < 1))
                flag = 0;
                obj.msgbox('Period number must be an integer > 0.'); 
            end
        end      
    end
    
    %Script methods
    methods (Access = public)
        function script.reset_table(obj)
        end
        
        function script.load_table(obj,new_table)
            
            %Update UI
            obj.send_data_to_table(1);
        end
    end
end


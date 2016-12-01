classdef DAGClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% DAGClass is a GARII Module %%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% Data Analysis GUI %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = private)
    end
    
    %GUI parameters
    properties (Access = public)
        %Plot
        hPLOT %Handle to plots
        hPLOTaxis %Handle to plot axis
        hPlotCtrl %Plot controls
        
        %Files
        hFileList %Handle to loaded file list UI
        fileList = {}; %File list (MAINs)
        
        hCurFile %handle to current file selection UI
        
        %Current parameters
        curFile = 0; %index to current file
        signal_list
        Xaxis_list
        Yaxis_list
        
        %Plots
        hPlotList
        plot_list = {0 0 0} %{[x y signal]}
        plot_list_lbl = {'' '' '' '' ''}%{x_lbl y_lbl signal_lbl module number}
        
        %Fitting
        hFIT        
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = DAGClass()
            %Module name
            obj.name = 'Data Analysis';
        end
    end
    
    %GUI methods
    methods (Access = public)
        %Update plot
        function plotUpdate(obj)
            colors = jet(size(obj.plot_list,1));
            UserData = get(obj.hPLOTaxis,'UserData');
            cla(obj.hPLOTaxis);   

            obj.hPLOT = [];
            for ctPlot = [size(obj.plot_list,1) 1:size(obj.plot_list,1)-1]
                Xaxis = obj.plot_list{ctPlot,1};
                Yaxis = obj.plot_list{ctPlot,2};
                signal = obj.plot_list{ctPlot,3};
                if(UserData{1})
                    signal = signal/max(abs(signal));
                end

                Xaxis_lbl = obj.plot_list_lbl{ctPlot,1};
                Yaxis_lbl = obj.plot_list_lbl{ctPlot,2};
                signal_lbl = obj.plot_list_lbl{ctPlot,3};

                %Plot
                if(~isempty(signal))
                    %1D,X
                    if(~isempty(Xaxis) && isempty(Yaxis))
                        obj.hPLOT(ctPlot) = plot(obj.hPLOTaxis,Xaxis,signal,'color',colors(ctPlot,:));
                        set(get(obj.hPLOTaxis,'Xlabel'),'String',Xaxis_lbl,...
                            'FontUnits','Normalized','FontSize',0.07);
                        set(get(obj.hPLOTaxis,'Ylabel'),'String',signal_lbl,...
                            'FontUnits','Normalized','FontSize',0.07);

                    %1D,Y
                    elseif(~isempty(Yaxis) && isempty(Xaxis))
                        obj.hPLOT(ctPlot) = plot(obj.hPLOTaxis,Yaxis,signal,'color',colors(ctPlot,:));
                        set(get(obj.hPLOTaxis,'Xlabel'),'String',Yaxis_lbl,...
                            'FontUnits','Normalized','FontSize',0.07);

                    %2D    
                    elseif(~isempty(Xaxis) && ~isempty(Yaxis))
                        obj.hPLOT(ctPlot) = imagesc(Xaxis,Yaxis,signal.','Parent',obj.hPLOTaxis);
                        set(get(obj.hPLOTaxis,'Xlabel'),'String',Xaxis_lbl,...
                            'FontUnits','Normalized','FontSize',0.07);
                        set(get(obj.hPLOTaxis,'Ylabel'),'String',Yaxis_lbl,...
                            'FontUnits','Normalized','FontSize',0.07);
                        set(obj.hPLOTaxis,'Ydir','Normal');
                    end
                end
                hold on
            end
            hold off
            axis(obj.hPLOTaxis,'tight');
            legend(obj.hPLOTaxis,['-'; obj.plot_list_lbl(1:end-1,5)],...
                'Location','NorthEastOutside' );

            %Plot remove UserData
            set(obj.hPLOTaxis,'UserData',UserData)
        end

        %SAVE/LOAD functions
        function addfile(obj,~,~)
            %Open output file
            [filename, pathname] = uigetfile('*.mat','Open',[obj.MAIN.root_path 'Data'],...
                                             'MultiSelect', 'on');    
            if(~iscell(filename))
                filename = {filename};
            end

            if(filename{1} ~= 0)
                for ctFile = 1:length(filename)
                    %Load matlab file
                    file = load([pathname filename{ctFile}]);
                    if(isfield(file,'MAIN'))
                        obj.fileList{end+1} = file.MAIN;

                        %Update GUI list
                        cur_str_list = get(obj.hFileList,'String');
                        last_idx = length(cur_str_list)+1;
                        cur_str_list{last_idx} = [int2str(last_idx) ': ' filename{ctFile}];
                        set(obj.hFileList,'String',cur_str_list,'Value',1);
                        set(obj.hCurFile,'String',cur_str_list,'Value',1);

                        %Update plot list
                        if(length(obj.fileList) == 1)
                            obj.fileselect(obj.hCurFile,[]);
                        end
                    end
                end
            end
        end

        function deletefile(obj,~,~)
            %Find files to remove
            selected_files = get(obj.hFileList,'Value');
            cur_str_list = get(obj.hFileList,'String');

            remain_files = setdiff(1:length(cur_str_list),selected_files);

            %Remove in GUI
            cur_str_list = cur_str_list(remain_files);
            if(isempty(cur_str_list))
                set(obj.hFileList,'String','');
                set(obj.hCurFile,'String',{''},'Value',1);
                set(obj.hPlotCtrl(1),'String',{''});
                set(obj.hPlotCtrl(2),'String',{''});
                set(obj.hPlotCtrl(3),'String',{''});
            else
                set(obj.hFileList,'String',cur_str_list,'Value',1);
                set(obj.hCurFile,'String',cur_str_list,'Value',1);
                plotselect(obj.hCurFile,[]);
            end

            %Remove in DAG class
            obj.fileList = obj.fileList(remain_files);
        end

        function saveplot(obj,~,~)
            %Create/Open output file
            [filename, pathname] = uiputfile('*.fig','Save as',[obj.MAIN.root_path 'Data']);
            if(filename ~= 0)
                hgsave(obj.hPLOTaxis,[pathname filename]);
            end
        end

        function fileselect(obj,~,~)
            %Get current index
            cur_str = get(obj.hCurFile,'String');
            if(~strcmp(cur_str{1},''))
                obj.curFile = get(obj.hCurFile,'Value');
            end

            %Update plot controls
            cur_main = obj.fileList{obj.curFile};

            %Signal, X and Y
            signal_list_str = {}; obj.signal_list = [];
            Xaxis_list_str = {}; obj.Xaxis_list = [];
            Yaxis_list_str = {}; obj.Yaxis_list = [];
            for ctMOD = 1:length(cur_main.mods)
                ID = cur_main.mods{ctMOD}.ID;

                measures = cur_main.mods{ctMOD}.measures;
                for ctMSRE = 1:numel(measures)
                    if(isa(measures{ctMSRE},'MeasureClass'))
                        if(measures{ctMSRE}.state)
                            signal_list_str{end+1} = [ID ' - ' measures{ctMSRE}.label]; %#ok<AGROW>
                            obj.signal_list(end+1,:) = [ctMOD ctMSRE];
                            if(cur_main.transient)
                                Xaxis_list_str{end+1} = ...
                                    [ID ' - ' measures{ctMSRE}.transient_axis.label]; %#ok<AGROW>
                                obj.Xaxis_list(end+1,:) = [ctMOD ctMSRE];
                            end
                        end
                    end
                end

                params = cur_main.mods{ctMOD}.params;
                for ctPAR = 1:numel(params)
                    if(isa(params{ctPAR},'ParameterClass'))
                        if(params{ctPAR}.param{1} == 2 && ~cur_main.transient)
                            Xaxis_list_str{end+1} = [ID ' - ' params{ctPAR}.label]; %#ok<AGROW>
                            obj.Xaxis_list(end+1,:) = [ctMOD ctPAR];
                        elseif(params{ctPAR}.param{1} == 3)
                            Yaxis_list_str{end+1} = [ID ' - ' params{ctPAR}.label]; %#ok<AGROW>
                            obj.Yaxis_list(end+1,:) = [ctMOD ctPAR];
                        end
                    end
                end
            end
            if(isempty(signal_list_str))
                signal_list_str = {''};
            end
            if(isempty(Xaxis_list_str))
                Xaxis_list_str = {''};
            end
            if(isempty(Yaxis_list_str))
                Yaxis_list_str = {''};
            end    

            %Update UI
            set(obj.hPlotCtrl(1),'String',signal_list_str,'Value',1);
            set(obj.hPlotCtrl(2),'String',Xaxis_list_str,'Value',1);
            set(obj.hPlotCtrl(3),'String',Yaxis_list_str,'Value',1);

            %Update plot
            obj.fileplotUpdate([],[]);
        end

        function fileplotUpdate(obj,~,~)
            %Retrieve plot parameters
            cur_main = obj.fileList{obj.curFile};

            signal_idx = get(obj.hPlotCtrl(1),'Value');
            Xaxis_idx = get(obj.hPlotCtrl(2),'Value');
            Yaxis_idx = get(obj.hPlotCtrl(3),'Value');

            %Signal
            signal = []; signal_lbl = '';
            if(signal_idx <= length(obj.signal_list))
                signal = cur_main.mods{obj.signal_list(signal_idx,1)} ...
                                 .measures{obj.signal_list(signal_idx,2)}.data;
                signal_lbl = cur_main.mods{obj.signal_list(signal_idx,1)} ...
                                 .measures{obj.signal_list(signal_idx,2)}.label;
            end

            %Xaxis
            Xaxis = []; Xaxis_lbl = '';
            if(Xaxis_idx <= length(obj.Xaxis_list))
                if(cur_main.transient)
                    Xaxis = cur_main.mods{obj.Xaxis_list(Xaxis_idx,1)} ...
                                    .measures{obj.Xaxis_list(Xaxis_idx,2)} ...
                                    .transient_axis.vals;
                    Xaxis_lbl = cur_main.mods{obj.signal_list(signal_idx,1)} ...
                                 .measures{obj.signal_list(signal_idx,2)} ...
                                 .transient_axis.label;
                else
                    Xaxis = cur_main.mods{obj.Xaxis_list(Xaxis_idx,1)} ...
                                    .params{obj.Xaxis_list(Xaxis_idx,2)}.vals;
                    Xaxis_lbl = cur_main.mods{obj.Xaxis_list(Xaxis_idx,1)} ...
                                    .params{obj.Xaxis_list(Xaxis_idx,2)}.label;                
                end
            end
            if(isempty(Xaxis) && cur_main.XPTS > 1)
                Xaxis = 1:cur_main.XPTS;
                Xaxis_lbl = 'Points';
            end

            %Yaxis
            Yaxis = []; Yaxis_lbl = '';
            if(Yaxis_idx <= length(obj.Yaxis_list))
                Yaxis = cur_main.mods{obj.Yaxis_list(Yaxis_idx,1)} ...
                                .measures{obj.Yaxis_list(Yaxis_idx,2)}.vals;
                Yaxis_lbl = cur_main.mods{obj.Yaxis_list(Yaxis_idx,1)} ...
                                .measures{obj.Yaxis_list(Yaxis_idx,2)}.label;
            end
            if(isempty(Yaxis) && cur_main.YPTS > 1)
                Yaxis = 1:cur_main.YPTS;
                Yaxis_lbl = 'Points';
            end

            obj.plot_list(end,:) = {Xaxis Yaxis signal};
            obj.plot_list_lbl(end,:) = {Xaxis_lbl Yaxis_lbl signal_lbl ...
                         cur_main.mods{obj.signal_list(signal_idx,1)}.ID ...
                         int2str(obj.curFile)};

            obj.plotUpdate();
        end

        function addplot(obj,~,~)
            %Add plot to list
            new_plot_str = [obj.plot_list_lbl{end,5} ': ' ...
                                        obj.plot_list_lbl{end,4} ' - ' ...
                                        obj.plot_list_lbl{end,3} ' - ' ...
                                        obj.plot_list_lbl{end,1} ' - ' ...
                                        obj.plot_list_lbl{end,2}];
            plot_str = get(obj.hPlotList,'String');
            if(length(plot_str) == 1 && strcmp(plot_str{1},''))
                plot_str{1} = new_plot_str;
            else
                plot_str{end+1} = new_plot_str;
            end
            set(obj.hPlotList,'String',plot_str);

            %Prepare next plot
            obj.plot_list(end+1,:) = obj.plot_list(end,:);
            obj.plot_list_lbl(end+1,:) = obj.plot_list_lbl(end,:);

            obj.plotUpdate();
        end

        %PLOT CONTROLS
        function removeplot(obj,~,~)
            idx = get(obj.hPlotList,'Value');

            %Remove plot from list
            plot_str = get(obj.hPlotList,'String');
            if(length(plot_str) > 1)
                set(obj.hPlotList,'String',plot_str([1:idx-1 idx+1:end]),'Value',1);
            else
                set(obj.hPlotList,'String',{''},'Value',1);
            end

            if(~isempty(plot_str) && ~any(strcmp(plot_str,'')))
                obj.plot_list = obj.plot_list([1:idx-1 idx+1:end],:);
                obj.plot_list_lbl = obj.plot_list_lbl([1:idx-1 idx+1:end],:);
            end

            obj.plotUpdate();
        end

        function plotselect(obj,~,~)
        end

        function normalizeplots(obj,hobj,~)
             UserData = get(obj.hPLOTaxis,'UserData');
             UserData{1} = get(hobj,'Value');
             set(obj.hPLOTaxis,'UserData',UserData);
             obj.plotUpdate();
        end

        %FITTING
        function fitting(obj,~,~)
            %Get Matlab string
            fun_text = get(obj.hFIT(1),'String');
            var_text = get(obj.hFIT(2),'String');

            %Get data
            X = get(obj.hPLOT(1),'XData');
            signal = get(obj.hPLOT(1),'YData');

            try
                fitFun = fit(X(:), signal(:), eval(fun_text), 'StartPoint', eval(var_text));
            catch
                fitFun = [];
            end
            if(~isempty(fitFun))
                hold on
                obj.hPLOT(2) = plot(X,fitFun(X),'r');
                hold off

                %Plot fitting values
                vars = fieldnames(fitFun);
                result_text = '';
                for ct = 1:length(vars)
                    result_text = [result_text vars{ct} ' = ' ...
                                   num2str(eval(['fitFun.' vars{ct}]),3) ', ']; %#ok<AGROW>
                end
                set(obj.hFIT(3),'String',result_text);
            end
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
    end
    
    %Internal functions
    methods (Access = private)
    end
    
    %Parameter check (value = [min max])
    methods (Access = private)
    end
end


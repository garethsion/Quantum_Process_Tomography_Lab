classdef LogClass < handle
    %LOGCLASS contains functions for to create a log window/display
    %messages
    properties
        %Window properties
        handle %window handle
        name %window name
        
        %Text
        hLOG %text handle
        
        %Cancel
        cancel_button %Add or not the cancellation button
        cancel_flag %Cancellation flag to be used by other functions
        
        %Others
        debug_level = 0
        warnings %Number of warnings collected
    end
    
    methods
        function obj = LogClass(win_name,canc_but)
            obj.name = win_name;
            obj.cancel_flag = 0;
            obj.warnings = 0;
            obj.cancel_button = canc_but; %Add a cancel button
        end
        
        function open(obj)
            %Create log window for the compilation
            fig_width = 0.3;
            fig_height = 0.125;
            close(findobj(0,'Name',obj.name));
            obj.handle = figure('Name',obj.name,'NumberTitle','off',...
                      'Visible','on','Units','Normalized','MenuBar','None',...
                      'Position', [0.5-fig_width/2,0.5-fig_height/2,fig_width,fig_height]);

            obj.hLOG = uicontrol('Style','Listbox','Visible','on',...
                  'Units','Normalized','FontUnits','Normalized','Value',[],...
                  'Enable','inactive','SelectionHighlight','off','Max',100,...
                  'BackgroundColor',get(obj.handle,'Color'),'HorizontalAlignment','Left',...
                  'Position',[0.05 0.2 0.9 0.72],'FontSize',0.15);

             function cancel(~,~)
                obj.cancel_flag = 1;
             end
            if(obj.cancel_button)
                uicontrol('Style','push','String','Cancel','Units','normalized',...
                         'FontUnits','Normalized','Position',[0.4 0.05 0.2 0.1],...
                         'Callback',@cancel);
            end

            drawnow;
        end
        
        function update(obj,text,old, varargin)
            %Log update, old = 0: new line, old = 1: replace previous text
            % varargin = integer [0 5], showing importance of message. 
            % 0 is highest importance 1 and subsequent are of lower importance
            
            if ~(isempty(varargin)) % if there is an importance parameter
                if varargin{1} > obj.debug_level % and if the importance is 
                                                 % lower than the debug_level
                    return
                end
            end
            
            if(isempty(obj.hLOG) || ~ishghandle(obj.hLOG))
                obj.open;
            end
            
            s = get(obj.hLOG,'String');
            if(old && ~isempty(s))
                s{end} = text;
            else
                s{end+1} = text;
            end
            set(obj.hLOG,'String',s,'ListboxTop',length(s),'Value',length(s));     
            
            figure(obj.handle)
            drawnow;
        end
        
        function close(obj)
            %Close object
            if(~isempty(obj.handle) && ishghandle(obj.handle))
                delete(obj.handle);
                drawnow;
            end
        end
    end
end


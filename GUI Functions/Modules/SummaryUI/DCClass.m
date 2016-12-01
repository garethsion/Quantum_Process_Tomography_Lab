classdef DCClass < ModuleClass
    %PulseGUIClass holds all the parameters for the pulseGUI.
    
    %GUI parameters
    properties (Access = public)
        %Table
        hTABLE %Table handle
        
        %Data = pulse table parameters
        data_types = {'DEV' 'CHAN' 'VOLT' 'MAXV' 'MINV' 'SWRAV' 'COMPA'};
        data = cell(1); %table data: {ctTable} = [param_row]
        
    end
    
    %GUI methods
    methods (Access = public)
        function obj = DCClass()
            obj.name = 'DC Creator';
        end
        
        %% EXPERIMENT FUNCTIONS
        function ok_flag = experiment_setup(obj) %Compile
            if(~any(strcmp(obj.MAIN.mods_name,'AWG')))
                ok_flag = 0;
                return;
            end
            
            %Duplicate table and create concatenated data from many tables
            PG2 = obj.copyObj();
            PG2.params = obj.concatenate_params();
            
            %Launch compiler
            EXP = PGcompiler(PG2);
            
            if(~isempty(EXP)) %WHAT ABOUT WARNINGS FROM COMPILE??? ok_flag = ??
                obj.MAIN.EXP = EXP;
                ok_flag = -1; %Continue but do not add PG to instruments
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
        
        %% VALUES CONVERSION FUNCTIONS
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
                values(ctCol) = obj.MAIN.get_values(row_params{ctCol}.param,ctX,ctY,ctPC);
            end
        end 
        
        %% TABLE MODIFICATION FUNCTIONS
        %Add pulse (row) to data
        function add_pulse_to_data(obj,cursorPos)
            tb = cursorPos(1);
            old_data = obj.data{tb};
            
            %Only table given, add to the end 
            if(length(cursorPos) == 1)
                obj.params(end+1,:) = {...
                    'Square' ...
                    'MW' ...
                    ParameterClass(obj,'FREQ','Frequency (MHz)',{1 0 0 1},@obj.FREQ_check,[]) ...
                    ParameterClass(obj,'PHAS','Phase (Deg)',{1 0 0 1},@obj.PHAS_check,[])};
                
                new_data = [old_data size(obj.params,1)];
                
            else %Add after cursor position
                row = cursorPos(2);
                
                new_idx = size(obj.params,1)+1;
                for ct = 1:size(obj.params,2)
                    if(isa(obj.params{old_data(row),ct},'ParameterClass'))
                        obj.params{new_idx,ct} = obj.params{old_data(row),ct}.copy();
                    else
                        obj.params{new_idx,ct} = obj.params{old_data(row),ct};
                    end
                end
                
                new_data = [old_data(1:row) new_idx old_data(row+2:end)];
            end
            
            obj.data{tb} = new_data;
        end
        
        %Delete pulse (row) from data
        function delete_pulse_from_data(obj,cursorPos)
            tb = cursorPos(1);
            row = cursorPos(2);
            
            old_data = obj.data{tb};
            obj.data{tb} = old_data([1:row-1 row+1:end]);
            
            remain_idx = setdiff(1:size(obj.params,1),old_data(row));
            obj.params = obj.params(remain_idx,:);
        end
        
        %% CONCATENATION FUNCTIONS
        %This function concatenate all tables.
        %NOT GOOD SHOULD CALL ITSELF FOR MULTI LEVEL NESTED TABLES 
        %Output is params{row,col} TO DO
        function data = concatenate_params(obj)
            data = obj.params;
            
%             data = {};
%             
%             for ctRow = 1:size(obj.data{1},1)
%                 shape_name = obj.get_cursor_data([1 ctRow],'SHAP');
%                 table_idx = find(strcmp(shape_name,obj.tables) == 1);
%                 
%                 if(~isempty(table_idx))
%                     start = obj.data{1}{ctRow,obj.tabcol({'STAR'})};
%                     subtable = obj.data{table_idx};
%                     
%                     %Modify start value of subtable
%                     for ctRowSub = 1:size(subtable,1)
%                         sub_start = subtable{ctRowSub,obj.tabcol({'STAR'})};
%                         
%                         subtable{ctRowSub,obj.tabcol({'STAR'})}{2} = ...
%                             start{2} + sub_start{2}; %Start val
%                         if(start{1} ~= 1 && sub_start{1} ~= 1)
%                             subtable{ctRowSub,obj.tabcol({'STAR'})}{3} = ...
%                                 start{3} + sub_start{3}; %Step val
%                         elseif(start{1} ~= 1)
%                             subtable{ctRowSub,obj.tabcol({'STAR'})}([1 3 4]) = ...
%                                                 start([1 3 4]);
%                         end
%                     end
%                     
%                     data = [data; subtable]; %#ok<AGROW>
%                 else
%                     data = [data; obj.data{1}(ctRow,:)]; %#ok<AGROW>
%                 end
%             end
        end
        
        %% ARBITRARY WAVEFORM FUNCTIONS
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
        
        %% OTHERS
        %Copy object, used for compile (Does not copy what is in handle obj)
        function newObj = copyObj(obj)
            newObj = PGClass();
            
            p = properties(obj);
            for i = 1:length(p)
                newObj.(p{i}) = obj.(p{i});
            end
        end
       
    end
   
    %Parameter check (value = [min max])
    methods (Access = private)
        function flag = FREQ_check(obj,value)
            flag = 1;
            
            if(value < 0)
                flag = 0;
                obj.msgbox('Frequency must be a value > 0.');
            end
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
            
%             if(value(1) == value(2) && value(1) == 0)
%                 flag = 0;
%                 obj.msgbox('Amplitude cannot be 0 when no sweep.')
%             end
        end
        function flag = DURA_check(obj,value)
            flag = 1;
            
%             if(value(1) == value(2) && value(1) == 0)
%                 flag = 0;
%                 obj.msgbox('Duration cannot be <= 0 when no sweep.')
%             end
            
            if(value < 0)
                flag = 0;
                obj.msgbox('Duration cannot be < 0.')
            end
        end
        function flag = STAR_check(obj,value)
            flag = 1;
            
            if(value < 0)
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
end


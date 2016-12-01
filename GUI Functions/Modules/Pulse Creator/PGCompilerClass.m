classdef PGCompilerClass < handle
    %ExperimentClass holds all the parameters for an actual experiment
    
    %Main properties
    properties
        XPTS
        YPTS
        PCPTS
        
        %% Pulses       
        %AWG settings (see class)
        gridDisc
        gridMin
        
        %Markers
        %4 outputs
        markers = []; %Matrix (ouput #, start, duration, period, period_nb)
        mar_idx = []; %This matrix assign X,Y,PC to a row in markers
        
        %Pulses
        RAST %Sampling frequency (MHz)
        channels = {'Acquisition' 'MW' 'RF'};
        shapes; %PulseClass
        sequences = []; %Matrix (shape idx,start,duration,period,period_nb)
                        %!!!in RAST unit!!!
        seq_idx = []; %This matrix assign X,Y,PC to a row in sequences
    end
    
    %Marker/Channel properties
    properties
        %Channel properties = marker value,        
        %defense timings (pre/post in s),
        %marker timings (pre/post in s)
        %duty cycle
        Acq = ChannelClass(1,[0.3e-6 2e-7],[2e-7 2e-7],1);
        MW = ChannelClass(2,[1e-7 2e-7],[300e-9 300e-9],0.1);
        RF = ChannelClass(3,[1e-7 1e-7],[1e-7 1e-7],0.02);
        User = ChannelClass(4,[0 0],[0 0],1);
    end
    
    methods
        function obj = PGCompilerClass(XPTS,YPTS,PCPTS)
            obj.XPTS = XPTS;
            obj.YPTS = YPTS;
            obj.PCPTS = PCPTS;
        end
        
        %Set RAST and define marker positions
        function set_RAST(obj,RAST)
            obj.RAST = RAST;
            obj.Acq.RAST = RAST;
            obj.MW.RAST = RAST;
            obj.RF.RAST = RAST;
            obj.User.RAST = RAST;
        end
        
        function chan = get_chan(obj,channel_name)
            switch(channel_name)
                case 'Acquisition'
                    chan = obj.Acq;
                case 'MW'
                    chan = obj.MW;
                case 'RF'
                    chan = obj.RF;
                case 'User'
                    chan = obj.User;
                otherwise
                    chan = [];
            end
        end
        
        function idx = PTS2idx(obj,pos)
            idx = (pos(:,1)-1)*obj.YPTS*obj.PCPTS + ... %X
                     (pos(:,2)-1)*obj.PCPTS + ... %Y
                      pos(:,3); %PC
        end
        
        %Add pulse to sequence (shape idx,start,duration,period,period_nb)
        function add_pulse2seq(obj,pos,data)
            obj.sequences = [obj.sequences; data];
            if(size(pos,2) == 3) %[X,Y,PC]
                obj.seq_idx = [obj.seq_idx; obj.PTS2idx(pos)];
            else %numel([X,Y,PC])
                obj.seq_idx = [obj.seq_idx; pos];
            end
        end

        %Clean shape registry
        function clean_shapes(obj,cLOG)
            %% Remove pulse shape that appears more than once
            cLOG.update('Comparing shapes',0);
            
            shape_list = 1:length(obj.shapes);
            replace_list = [];
            ct1 = 1;
            while(ct1 < length(shape_list))
                ct2 = ct1 + 1;
                
                while(ct2 <= length(shape_list))
                    pa = obj.shapes{shape_list(ct1)};
                    pb = obj.shapes{shape_list(ct2)};
                    
                    %Compare pulses: if same reduce shape_list, add to
                    %replace_list [new old]
                    if(isequal(pa.shape,pb.shape) && ...
                       isequal(pa.markers,pb.markers))
                    
                        replace_list(end+1,:) = shape_list([ct1 ct2]);
                        shape_list = shape_list([1:ct2-1 ct2+1:length(shape_list)]);
                    end
                    
                    ct2 = ct2 + 1;
                end
                ct1 = ct1 + 1;
            end
            
            if(~isempty(replace_list))
                cLOG.update('Removing doublets',1);
                %Modify replace_list
                if(size(replace_list,1) > 1)
                    for ct = 1:size(replace_list,1)
                        temp = replace_list(ct+1:end,:);
                        replace_list(temp(:) == replace_list(ct,2)) = replace_list(ct,1); 
                    end
                end
                [~,unique_idx] = unique(replace_list(:,2)); %avoid replacing twice
                replace_list = replace_list(unique_idx,:); 

                %Update sequence (no need to update shapes as they won't be
                %called anymore after replacing within sequence, and uncalled
                %shapes are removed later)
                for ct = 1:size(replace_list,1)
                    obj.sequences(obj.sequences(:,1) == replace_list(ct,2)) = ...
                        replace_list(ct,1);
                end           
            end
                
            %Remove uncalled shapes
            obj.remove_uncalled_shapes();            
        end
        
        %Remove uncalled shapes
        function remove_uncalled_shapes(obj)
            %Find called shapes
            called_idx = unique(obj.sequences(:,1));
            
            %Reorganize shapes properly (1:N)
            obj.shapes = obj.shapes(called_idx);
            
            %Update sequences' shapes
            conv_idx = zeros(max(called_idx),1);
            conv_idx(called_idx) = 1:length(called_idx);
            obj.sequences(:,1) = conv_idx(obj.sequences(:,1));
        end
        
        %Sort pulses in sequences
        function sort_sequences(obj)
            %Sort sequences
            [~,sort_idx] = sort(obj.seq_idx);
            obj.seq_idx = obj.seq_idx(sort_idx);
            obj.sequences = obj.sequences(sort_idx,:);
            
            %Sort within sequences
            for ctSeq = 1:obj.XPTS*obj.YPTS*obj.PCPTS
                seqIdx = find(obj.seq_idx == ctSeq);
                [~,sort_idx] = sort(obj.sequences(seqIdx,2)); %starts
                obj.sequences(seqIdx,:) = obj.sequences(seqIdx(sort_idx),:);
            end            
        end
    end    
end


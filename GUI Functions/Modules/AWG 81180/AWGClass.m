classdef AWGClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% AWGClass is a Module for the experiment GUI %%%%%%%%
    %%%%%%%% Arbitrary waveform generator 81180A %%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Internal parameters
    properties (Access = public)
        %Sampling rate
        max_RAST = 4200; %MHz
        min_RAST =   10; %MHz
        
        %Amplitude DAC range
        amp_range = 2^12-1; %12 bits = 4095
        
        %Segment
        max_segment_nb = 32000; %max nb of seg that can be defined                                   
        max_segment_size = 16e6; %per segment or overall????
        
        %Sequence (values redefined later if version B)
        min_segPerSeq_nb = 3; %min nb of seg per seq
        max_segPerSeq_nb = 32768; %max nb of seg per seq
        max_sequence_loop = 1048575; %max nb of loops for each seg
        
        %Advance sequence
        min_seqPerAdvSeq_nb = 3; %min nb of seq per adv seq
        max_seqPerAdvSeq_nb = 1000; %min nb of seq per adv seq
        max_adv_sequence_loop = 1048575; %max nb of loops for each seq (SPP)
        
        %Memory discretisation
        %Normally gridDisc should be 32, but in order to avoid splitting blank 
        %pulses into too many pulses, its better to use gridMin. The Main of period
        %will remain at 32. DO BETTER THAN THAT???? (would require lots of
        %changes in compile)
        %320 for 81180A and 384 for 81180B
        gridDisc = 320;
        gridMin = 320;
    end
    
    %GUI parameters
    properties (Access = public)
        %Data
        data_shapes %[I,Q]
        data_markers %[LNA,TWT,RF,OTHER1]
        
        data_segm_load %{load #}(shape #)
        data_sequ_load %{load #}(seq #, seg #, loop #)
        cur_load %Current load #
        
        axis_idx %axis seq = [X,Y,PC]
        
        %Parameters
        RAST = 1000; %MHz
    end
    
    %Main methods
    methods (Access = public)
        %CONNECTION FUNCTIONS
        function obj = AWGClass()
            AWGversion = 'B';
            switch(AWGversion)
                case 'A'
                    %Module name
                    obj.name = 'AWG 81180A';
                    
                    %Instrument properties
                    obj.INST_brand = 'agilent';
                    obj.INST = {{'Agilent Technologies,81180A,IL50280120,1.64', 'visa', 'USB0::0x0957::0x5B18::IL50280120::0::INSTR'}};
                    
                case 'B'
                    %Module name
                    obj.name = 'AWG 81180B';
                    
                    %Instrument properties
                    obj.INST_brand = 'agilent';
                    obj.INST = {{'Agilent Technologies,81180B,IL53C00110,3.10', 'visa', 'USB0::0x0957::0xA918::IL53C00110::INSTR'},...
                                {'Agilent Technologies,81180B,IL53C00110,3.10', 'visa', 'GPIB0::6::INSTR'}};
                    
                    %Sequence
                    obj.min_segPerSeq_nb = 3; %min nb of seg per seq
                    obj.max_segPerSeq_nb = 49152; %max nb of seg per seq
                    obj.max_sequence_loop = 16777216; %max nb of loops for each seg
                    
                    %Memory
                    obj.gridDisc = 384;
                    obj.gridMin = 384;
            end
            
            %Trigger modes
            obj.settings{1} = SettingClass(obj,'trigmode1','Trigger mode 1','Internal',[],[],{'Internal' 'External'});
            
            obj.settings{2} = SettingClass(obj,'trigmode2.1','Trigger mode 2','Single',[],[],{'Continuous' 'Single' 'AdvSeq'});
            obj.settings{3} = SettingClass(obj,'trigmode2.2','Trigger mode 2','Triggered',[],[],{'Triggered' 'Gated'});
        end
        
        %Connect
        function connect(obj)
            obj.create_device();
                              
            if(~isempty(obj.dev))
                obj.reset();
            end
        end
        
        %Disconnect
        function disconnect(obj)
            obj.all_output(0);
            obj.dev.close();
            obj.dev = [];
        end
        
        %Reset to some defaut parameter
        function reset(obj)
            obj.dev.xwrite('*RST'); pause(0.5);
            obj.configure_instrument();
            obj.clear_sequences();
            obj.dev.check();
        end
        
        %EXPERIMENT FUNCTIONS
        %Setup the experiment
        function ok_flag = experiment_setup(obj)
            if(isempty(obj.parent_mod)) %PG
                ok_flag = 0;
                return;
            end
            
            %Compile
            ok_flag = 0;
            success = obj.compile();
            if(~isempty(obj.dev) && success) 
                obj.all_output(0);
                
                %Setup options
                obj.set_RAST();
                
                %Load data
                if(length(obj.data_segm_load) ~= 1)
                    answer = questdlg({['This experiment requires ' int2str(length(obj.data_sequ_load)) ...
                                                       ' loading of the AWG.'] ...
                                                      'It might be time consuming (Tip: set average to 1).' ...
                                                      'Do you want to continue?'}, ...
                                                      'AWG multi-loading','Yes', 'No', 'Yes');
                    if(~strcmp(answer,'Yes'))
                        ok_flag = 0;
                        return;
                    end
                end
                obj.cur_load = 1;
                obj.load_data(1);
                
                %Set trigger config (after load)
                obj.set_trigger_mode();
                
                if(~obj.dev.check())
                    return;
                end
                
                %Load first sequence
                obj.change_sequence(1);
                
                ok_flag = 1;
            end
        end
        
        %During experiment
        %pos = [X Y PC] index value, type = which pos is changed
        function ok_flag = experiment_next(obj,type,pos)
            %Use a try-catch sequence to easily stop experiment 
            %if there is some trouble
            ok_flag = 0;
            try
                pts = max(obj.axis_idx,[],1);
                
                %Check if there is a need to change sequence
                if(~((any(type == 1) && pts(1) ~= 1) || ...
                     (any(type == 2) && pts(2) ~= 1) || ...
                     (any(type == 3) && pts(3) ~= 1)))
                    ok_flag = 1;
                    return;
                end
                
                %Sequence position
                seq = find(obj.axis_idx(:,1) == min(pts(1),pos(1)) & ...
                           obj.axis_idx(:,2) == min(pts(2),pos(2)) & ...
                           obj.axis_idx(:,3) == min(pts(3),pos(3)),1);
                
                %Load new sequence
                obj.change_sequence(seq);
                
                ok_flag = 1;
            catch ME
                report = getReport(ME);
                disp(report);
            end
        end
        
        %Trigger every shot
        function experiment_trigger(obj)
            %Internal,Single
            if(strcmp(obj.get_setting('trigmode1').val,'Internal') && ...
               strcmp(obj.get_setting('trigmode2.1').val,'Single'))
                obj.dev.write('*TRG');
                obj.dev.wait_till_complete(); %Seems to be necessary or 
                                              %trigger can be missed
            end
        end
        
        %End of experiment
        function ok_flag = experiment_stop(obj)
            if(~isempty(obj.dev))
                obj.all_output(0);
                obj.dev.check;
                
                obj.data_shapes = [];
                obj.data_markers = [];
                obj.data_segm_load = {};
                obj.data_sequ_load = {};
                
                ok_flag = 1;
            else
                
                ok_flag = 0;
            end
        end
    end
    
    %GUI methods
    methods (Access = public)
        function trigger_mode_selected(obj,~,~)
            trigmode1 = obj.get_setting('trigmode1');
            trigmode21 = obj.get_setting('trigmode2.1');
            trigmode22 = obj.get_setting('trigmode2.2');
            
            switch(trigmode1.val)
                case 'Internal'
                    trigmode21.set_state_and_UIvisibility(1);
                    trigmode22.set_state_and_UIvisibility(0);
                    
                case 'External'
                    trigmode21.set_state_and_UIvisibility(0);
                    trigmode22.set_state_and_UIvisibility(1);
            end                                      
        end
    end
    
    %Wrapper for internal functions
    methods (Access = public)
        function configure_instrument(obj)
            %Channel 1 and channel 2 are nearly completely separate
            %so most settings must be sent to both separately.
            
            obj.dev.xwrite(':FUNC:MODE USER'); %Mode arb. fun., seems to be the 
                                              %best mode to set settings
                                     
            for ct = 1:2
                %Channel
                obj.dev.write([':INST:SEL ' int2str(ct)]);
                
                %Timings/clocks                
                obj.dev.write(':INST:COUP:STAT 1'); %Common clock for ch1 ch2
                obj.dev.write(':INST:COUP:OFFS 0'); %No phase offset between ch1 ch2
                obj.dev.write(':INST:COUP:SKEW 0'); %No time offset between ch1 ch2
                obj.dev.write(':FREQ:RAST 1000000000'); %Sampling frequency
                obj.dev.xwrite(':TRAC:SEL:TIM COH'); %Segments are one after another
                obj.dev.xwrite(':SEQ:SEL:TIM COH'); %Sequences are one after another
                
                %DC coupling (amplitude+offset control, high amplitude, slow rise time)
                %DAC coupling (amplitude+offset control, low amplitude, fast rise time)
                %AC coupling (power control only)
                couplingSettings = 'DAC';
                switch(couplingSettings)
                    case 'AC'
                        %DC mode settings
                        obj.dev.write(':OUTP:COUPLING AC'); 
                        obj.dev.write(':POWER MAX'); %Power
                
                    case 'DC'
                        %DC mode settings
                        obj.dev.write(':OUTP:COUPLING DC'); 
                        obj.dev.write(':VOLT MAX'); %Voltage amplitude
                        obj.dev.xwrite(':VOLT:OFFS 0') %offset
                        
                    case 'DAC'
                        %DAC mode settings
                        obj.dev.xwrite(':OUTP:COUPLING DAC'); 
                        obj.dev.xwrite(':VOLT:OFFS 0') %offset
                        obj.dev.xwrite(':VOLT:DAC 500e-3'); %Voltage amplitude
                end
                
                %Markers
                obj.dev.write(':MARK1:WIDT 0'); %Non-Arb.Wave markers to 0, otherwise can clash with sent data
                obj.dev.write(':MARK2:WIDT 0');
                obj.dev.write(':MARK1:VOLT:HIGH 1.25'); %Marker High amplitude
                obj.dev.write(':MARK2:VOLT:HIGH 1.25');
                obj.dev.write(':MARK1:VOLT:LOW 0'); %Marker Low amplitude
                obj.dev.xwrite(':MARK2:VOLT:LOW 0');

                %Sync pulse (setup for 10us here)
                sync_width = ceil(10*obj.RAST/32)*32;
                obj.dev.write(':OUTP:SYNC:SOUR 1');
                obj.dev.write(':OUTP:SYNC:FUNC PULSE');
                obj.dev.xwrite([':OUTP:SYNC:WIDTH ' int2str(sync_width)]);
            end
        end
        
        function clear_sequences(obj)
            obj.dev.write(':INST:SEL 1');
            obj.dev.write(':ASEQ:DEL'); 
            obj.dev.write(':SEQ:DELETE:ALL');
            obj.dev.write(':TRACE:DELETE:ALL');
            
            obj.dev.write(':INST:SEL 2');
            obj.dev.write(':ASEQ:DEL'); 
            obj.dev.write(':SEQ:DELETE:ALL');
            obj.dev.write(':TRACE:DELETE:ALL');
            
            obj.dev.check();
        end
        
        %Set on/off outputs
        function all_output(obj,state)
            %Make sure markers appear always before the actual pulse so
            %that switches will be in the right place
            obj.sync_output(state);
            if(state)
                obj.marker_output(1);
                obj.wave_output(1);
            else
                obj.wave_output(0);
                obj.marker_output(0);
            end
        end
        function wave_output(obj,state)
            if(state)
                obj.dev.write(':INST:SEL 1; :OUTP 1; :INST:SEL 2; :OUTP 1;');
            else
                obj.dev.write(':INST:SEL 1; :OUTP 0; :INST:SEL 2; :OUTP 0;');
            end
        end
        function marker_output(obj,state)
            if(state)
                obj.dev.write([':INST:SEL 1; :MARK1 1; :MARK2 1;' ...
                               ':INST:SEL 2; :MARK1 1; :MARK2 1;']);
            else
                obj.dev.write([':INST:SEL 1; :MARK1 0; :MARK2 0;' ...
                               ':INST:SEL 2; :MARK1 0; :MARK2 0;']);
            end
        end
        function sync_output(obj,state)
            if(state)
                obj.dev.write(':OUTP:SYNC 1');
            else
                obj.dev.write(':OUTP:SYNC 0');
            end
        end
        
        %Set sampling frequency
        function set_RAST(obj)
            obj.dev.xwrite(':INST:SEL CH1'); %Channel 1
            obj.dev.xwrite(sprintf(':FREQ:RAST %d',obj.RAST*1e6)); 
            
            obj.dev.xwrite(':INST:SEL CH2'); %Channel 2
            obj.dev.xwrite(sprintf(':FREQ:RAST %d',obj.RAST*1e6)); 
        end
        
        %Trigger mode: type1: int/ext, type2: cont/gated/...
        function set_trigger_mode(obj)
            for ch = 1:2
                %Select channel
                obj.dev.write(sprintf(':INST:SEL %d', ch));
                
                switch(obj.get_setting('trigmode1').val)                    
                    %%%%%%%%%%%%%%%%%%%%
                    case 'Internal'
                        switch(obj.get_setting('trigmode2.1').val)
                            %%%%%%%%%
                            case 'Continuous'
                                %Continuous mode
                                obj.dev.write(':INIT:CONT 1');
                                obj.dev.write(':INIT:CONT:ENAB ARM');
                                obj.dev.write(':INIT:CONT:ENAB:SOUR BUS');
                                obj.dev.write(':TRIG:MODE OVERRIDE');

                                %INIT GATE could be useful to make sure there
                                %is no waveform output outside of sequence

                                %Sequence (re)starts continuously
                                obj.dev.write(':SOURCE:SEQUENCE:ADVANCE AUTO');
                                obj.dev.write(':SOURCE:ASEQUENCE:ADVANCE STEP');

                                %Sequence change is controlled by computer
                                obj.dev.write(':SEQUENCE:SELECT:SOURCE BUS');
                                obj.dev.write(':SEQUENCE:SELECT:TIMING IMM');
                                %TIMING MUST BE IMMEDIATE OR OUTPUT GETS
                                %SCREWED DURING SEQUENCE CHANGE

    %                         case 'Timing' (maybe good if no need for blank to SRT)
    %                             obj.dev.write(':INIT:CONT 0');
    %                             
    %                             obj.dev.write(':TRIG:SOURCE:ADVANCE TIM');
    %                             obj.dev.write(':TRIG:TIM:MODE TIME');
    %                             obj.dev.write(sprintf(':TRIG:TIM:TIME %d', obj.SRT)); %in s

                            case 'Single'
                                %Trigger mode from computer
                                obj.dev.write(':INIT:CONT 0');
                                obj.dev.write(':INIT:CONT:ENAB:SOUR BUS');
                                obj.dev.write(':TRIG:MODE NORMAL');
                                obj.dev.write(':TRIGGER:SOURCE:ADVANCE BUS');

                                %Sequence starts on trigger
                                obj.dev.write(':SOURCE:SEQUENCE:ADVANCE ONCE');
                                obj.dev.write(':SOURCE:ASEQUENCE:ADVANCE ONCE');

                                %Sequence change is controlled by computer
                                obj.dev.write(':SEQUENCE:SELECT:SOURCE BUS');
                                obj.dev.write(':SEQUENCE:SELECT:TIMING IMM');
                                %TIMING MUST BE IMMEDIATE OR OUTPUT GETS
                                %SCREWED DURING SEQUENCE CHANGE

                            %%%%%%%%%
                            otherwise
                                error('Trigger mode: no such type');
                        end
                        
                    %%%%%%%%%%%%%%%%%%%%
                    case 'External'
                        %Trigger mode from trigger input
                        obj.dev.write(':INIT:CONT 0');
                        obj.dev.write(':TRIG:MODE NORMAL');
                        obj.dev.write(':TRIG:SOUR:ADV EXT');                        
                        obj.dev.write(':TRIG:SLOP NEG'); % Tigger Slope Negative for OPO Laser                         
                        obj.dev.write(':TRIG:LEV -1.8'); % Tigger Level -1.8V                        

                        %Sequence starts on trigger
                        obj.dev.write(':SOURCE:SEQUENCE:ADVANCE ONCE');
                        obj.dev.write(':SOURCE:ASEQUENCE:ADVANCE STEP');
                    
                        switch(obj.get_setting('trigmode2.2').val)
                            %%%%%%%%%
                            case 'Triggered'

                            case 'Gated' %NOT WORKING

                            %%%%%%%%%
                            otherwise
                                error('Trigger mode: no such type');
                        end
                    
                    %%%%%%%%%%%%%%%%%%%% 
                    otherwise
                        error('Trigger mode: no such type');
                end
               
                %Sequence mode
                obj.dev.xwrite(':FUNC:MODE SEQ');
            end
        end

        %SEQUENCE COMPILE AND LOADING
        %Find loading sequence (how to load shape,X,Y,PC)
        %Shapes: shapes + blanks
        %Segment loading: {load #}(seg #, shape #)
        %Sequence loading: {load #}(seq #, seg #, loop #)
        %Triggers: protection pulses, channel pulses, etc...
        %Loading must be done at the beginning of the the first seq of each load 
        function success = compile(obj)
            awgLOG = LogClass('AWG compiler/check',0);      
            success = 0;
            
            EXP = obj.parent_mod.EXP;
            obj.parent_mod.EXP = []; %clear EXP here, takes too much memory
            if(isempty(EXP))
                return;
            end
            
            obj.RAST = EXP.RAST;
            SRTrast = floor(obj.MAIN.SRT*(obj.RAST*1e6)/EXP.gridDisc)*EXP.gridDisc;
            
            %MODIFY HERE
            obj.axis_idx = allcomb(1:EXP.XPTS,1:EXP.YPTS,1:EXP.PCPTS);
            perm_idx = EXP.PTS2idx(obj.axis_idx);
            
            %% Create memory table (seq #, shape #, dura, loop #) 
            Blkmult = EXP.gridMin;
            mem_table = [];   
            for ctSeq = 1:length(perm_idx)
                cur_seq = EXP.sequences(EXP.seq_idx == perm_idx(ctSeq),:);
                
                %Vector delimiting each pulses/blanks in a sequence
                seq_times = [0; ...
                             cur_seq(:,2); ... %starts
                             cur_seq(:,2) + cur_seq(:,3) + (cur_seq(:,5)-1).*cur_seq(:,4); ...
                             SRTrast+1];
                if(seq_times(end-1) > seq_times(end))
                    awgLOG.update('ERROR: The sequence is longer than the SRT',0);
                    last_seq = EXP.sequences(EXP.seq_idx == perm_idx(end),:);
                    max_time = last_seq(end,2) + last_seq(end,3) + ...
                               (last_seq(end,5)-1).*last_seq(end,4);
                    awgLOG.update(['SRT suggested: ' ...
                        num2str(max_time/(obj.RAST*1e6),3) ' s'],0);
                    return;
                end
                seq_times = sort(seq_times);
                
                %Pulses
                pulses_mem = [ctSeq*ones(size(cur_seq,1),1) cur_seq(:,[1 3 5])];
                
                %Blanks
                blanks_dura = seq_times(2:2:end) - seq_times(1:2:end-1);
                
                blanks_loop_nb = blanks_dura/Blkmult/obj.max_sequence_loop;
                %at this point, blank_dura and blank_loop_nb are just
                %variable to make things easier later
                
                blanks_mem = [ctSeq*ones(size(blanks_dura,1),1) ...
                              zeros(size(blanks_dura,1),1) ... %0 for blank
                              blanks_dura blanks_loop_nb];
                
                %Put together
                cur_mem = [blanks_mem; pulses_mem];
                idx = zeros(2,size(blanks_mem,1));
                idx(1,:) = 1:size(blanks_mem,1);
                idx(2,1:size(pulses_mem,1)) = size(blanks_mem,1) + ...
                                              (1:size(pulses_mem,1));
                idx = idx(:);
                cur_mem = cur_mem(idx(idx~=0),:);
                cur_mem = cur_mem(cur_mem(:,3)~=0,:);
                
                %The AWG has a minimum of 3 segments/sequence
                while(size(cur_mem,1) < obj.min_segPerSeq_nb)
                    blanks_dura(end+1) = Blkmult;
                    blanks_loop_nb(end+1) = blanks_dura(end)/Blkmult/obj.max_sequence_loop;
                    cur_mem(end+1,:) = [ctSeq 0 blanks_dura(end) blanks_loop_nb(end)];
                end
                
                %Add cur_table to mem_table
                mem_table = [mem_table; cur_mem];          
            end
            clear cur_seq;
            
            %% Construct blanks properly
            %Find unique blanks durations
            blanks_idx = find(mem_table(:,2) == 0);
            blanks_loop = mem_table(blanks_idx,4);
            
            int_blanks_loop = floor(blanks_loop);
            int_idx = find(blanks_loop == int_blanks_loop);
            non_int_idx = setdiff((1:size(blanks_loop,1)).',int_idx);
            zero_idx = find(int_blanks_loop == 0);
            non_zero_idx = setdiff((1:size(int_blanks_loop)).',zero_idx);
            
            [blanks_shapes,~,old_idx] = unique([Blkmult; EXP.gridMin*int_blanks_loop(non_zero_idx)]);
            old_idx = old_idx(2:end);
            
            %% Create shapes table
            shapes = cell(length(EXP.shapes)+length(blanks_shapes),1);
            markers = cell(length(EXP.shapes)+length(blanks_shapes),1);
             
            %Add pulses
            k = 0;
            for ct = 1:length(EXP.shapes)
                k = k + 1;
                shapes{k} = EXP.shapes{ct}.shape;
                markers{k} = EXP.shapes{ct}.markers;
            end              
            
            %Add blanks
            for ct = 1:length(blanks_shapes)
                k = k + 1;
                shapes{k} = zeros(blanks_shapes(ct),2);
                markers{k} = false(blanks_shapes(ct),4);
            end
            
            %Update blanks in mem_table
            mem_table(blanks_idx(zero_idx),2) = length(EXP.shapes) + 1;
            mem_table(blanks_idx(non_zero_idx),2) = length(EXP.shapes) + old_idx;
            
            mem_table(blanks_idx(zero_idx),4) = mem_table(blanks_idx(zero_idx),3)/Blkmult;
            mem_table(blanks_idx(int_idx),4) = obj.max_sequence_loop;
            
            %Any non integer dura/max loop becomes 2 pulses: one full loop
            %+ 1 correction
            long_blanks_idx = find(int_blanks_loop(non_int_idx) ~= 0);
            
            for ct = 1:length(long_blanks_idx)
                cur_idx = non_int_idx(long_blanks_idx(ct));
                %+ (ct-1) as mem_table now increases in size during loop
                mem_cur_idx = blanks_idx(cur_idx) + (ct-1);
                
                round_dura = Blkmult*int_blanks_loop(cur_idx)*obj.max_sequence_loop;
                remain_dura = mem_table(mem_cur_idx,3)-round_dura;
                mem_table(mem_cur_idx,[3 4]) = [round_dura round_dura/(Blkmult*int_blanks_loop(cur_idx))];                
                
                cor_table = [mem_table(mem_cur_idx,1) length(EXP.shapes)+1 ...
                             remain_dura remain_dura/Blkmult];
                
                mem_table = [mem_table(1:mem_cur_idx,:); cor_table; ...
                             mem_table(mem_cur_idx+1:end,:)];
            end
            
            %Until now, blanks duration was loop included. Divide by loop.
            blanks_idx = find(mem_table(:,2) > length(EXP.shapes));
            mem_table(blanks_idx,3) = mem_table(blanks_idx,3)./...
                                      mem_table(blanks_idx,4);
            
            mem_table = uint64(mem_table);
            
            %For markers, make sure that LNA,TWT and RF channel are never
            %together. Priority = LNA then TWT then RF
            for ctMark = 1:length(markers)
                markers{ctMark}(:,2) = (markers{ctMark}(:,2) & ...
                                       ~markers{ctMark}(:,1));
                markers{ctMark}(:,3) = (markers{ctMark}(:,3) & ...
                                       ~markers{ctMark}(:,1) & ...
                                       ~markers{ctMark}(:,2));
            end
            
            %% MARKER MODIFICATION DUE TO 24 PTS LAG (TO SOLVE!!!)
            markers = obj.modif_markers_for_AWG(markers,mem_table);
            
            %% LAST CHECKS            
            %Max memory
            seq_idx = unique(mem_table(:,1));
            max_seg_mem = 0;
            max_seg_nb = 0;
            segperseq = [];
            for ct = 1:length(seq_idx)
                idx = find(mem_table(:,1) == seq_idx(ct));
                
                max_seg_mem = max(max_seg_mem, sum(mem_table(idx,3)));
                max_seg_nb = max(max_seg_nb, length(unique(mem_table(idx,2))));
                segperseq(end+1) = length(idx); %#ok<AGROW>
            end
            
            if(max_seg_mem > obj.max_segment_size)
                awgLOG.update('ERROR: Compiled experiment uses too much memory.',0);
                return;
            end
            
            if(max_seg_nb > obj.max_segment_nb)
                awgLOG.update('ERROR: Compiled experiment uses too many segments.',0);
                return;
            end
            
            if(max(segperseq) > obj.max_segPerSeq_nb)
                awgLOG.update('ERROR: Compiled sequence uses too many segments.',0);
                return;
            elseif(min(segperseq) < obj.min_segPerSeq_nb)
                awgLOG.update('ERROR: Compiled sequence uses too few segments.',0);
                return;
            end
            
            if(strcmp(obj.get_setting('trigmode1').val,'Internal') && ...
               strcmp(obj.get_setting('trigmode2.1').val,'AdvSeq'))
                if(length(seq_idx) > obj.max_seqPerAdvSeq_nb)
                    awgLOG.update('ERROR: Compiled adv sequence uses too many sequences.',0);
                    return;
                elseif(length(seq_idx) < obj.min_seqPerAdvSeq_nb)
                    awgLOG.update('ERROR: Compiled adv sequence uses too few sequences.',0);
                    return;
                end
            else
                if(length(seq_idx) > obj.max_seqPerAdvSeq_nb)
                    awgLOG.update('ERROR: Compiled experiment uses too many sequences.',0);
                    return;
                end
            end
            
            %Max loop number
            if(any(mem_table(:,4) > obj.max_sequence_loop))
                awgLOG.update('ERROR: Compiled sequence uses too many loops.',0);
                return;
            end
            
            %Max SPP
            if(obj.MAIN.SPP > obj.max_adv_sequence_loop)
                awgLOG.update('ERROR: Compiled sequence uses too many SPP.',0);
                return;
            end

            %% Create segment and sequence loading table
            %segment loading: {load #}(shape #)
            %sequence loading: {load #}(seq #, seg #, loop #)
            
            %Loading tables
            segm_load = {};
            sequ_load = {};
            cur_segm = []; %(dummy, seg#, shape#)
            cur_sequ = []; %(seq #, seg# loop #)
            load_idx = 1;
            cur_mem = [];
            for ct = 1:size(mem_table,1)
                %For each pulse/blank, find if shape already loaded
                if(~isempty(cur_segm))
                    segm_nb = cur_segm(mem_table(ct,2) == cur_segm(:,3),2);
                else
                    segm_nb = [];
                end
                
                %Not loaded yet, so add to cur_segm
                if(isempty(segm_nb))
                    cur_mem = [cur_mem mem_table(ct,3)];
                    cur_segm(end+1,:) = [1 0 mem_table(ct,2)];
                    
                    segm_nb = max(cur_segm(:,2)) + 1;
                    cur_segm(end,2) = segm_nb;
                else
                    cur_segm(end+1,:) = [0 0 0]; %just to count the nb of shape
                end                
                cur_sequ(end+1,:) = [mem_table(ct,1) segm_nb mem_table(ct,4)];
                     
                %If memory is full, create new loading
                %CHECK IF IT IS == OR >
                if(sum(cur_mem) > obj.max_segment_size || ...
                   size(cur_segm,1) == obj.max_segment_nb || ...
                   size(cur_sequ,1) == obj.max_segPerSeq_nb || ...
                   (cur_sequ(end,1)-cur_sequ(1,1)+1) == obj.max_seqPerAdvSeq_nb)
               
                    %Only load until the last completed sequence 
                    if(cur_sequ(end,1) ~= mem_table(ct,1))
                        max_idx = size(cur_sequ,1);
                    else
                        max_idx = find(cur_sequ(2:end,1)-cur_sequ(1:end-1,1) == 1,1,'last');
                    end
                    
                    segm_load{load_idx} = cur_segm(1:max_idx,:);
                    sequ_load{load_idx} = cur_sequ(1:max_idx,:);
               
                    %Create next loading sequence
                    load_idx = load_idx + 1;
                    cur_mem = [cur_mem(max_idx+1:end-1) cur_mem(end)];
                    cur_segm = [cur_segm(max_idx+1:end-1,:); cur_segm(end,:)];
                    cur_sequ = [cur_sequ(max_idx+1:end-1,:); cur_sequ(end,:)];
                end
            end
            segm_load{load_idx} = cur_segm;
            sequ_load{load_idx} = cur_sequ;
            
            %Delete all flagged segments (-> shape #) & sort all
            for ct = 1:length(segm_load)
                segm_load{ct} = segm_load{ct}(segm_load{ct}(:,1) == 1,[2 3]);
                
                [old_seg_idx,sort_idx] = sort(segm_load{ct}(:,1));
                segm_load{ct} = segm_load{ct}(sort_idx,2);
                for ct2 = 1:length(old_seg_idx)
                    sequ_load{ct}(sequ_load{ct}(:,2) == old_seg_idx(ct2),2) = ct2;
                end
            end
            
            %% Other information
            %-The compilation used to try to find permanent shapes to avoid
            % sending the same data over and over, but sending bulk data is
            % much faster so this was removed (2014/08/05).
            
            %% Save data
            obj.data_shapes = shapes;
            obj.data_segm_load = segm_load;
            obj.data_sequ_load = sequ_load;
            obj.data_markers = markers;
            
            success = 1;
            awgLOG.close;
        end
        
        %MARKER MODIFICATION DUE TO 24 PTS LAG (TO SOLVE PROPERLY!!!)
        function new_markers = modif_markers_for_AWG(~,markers,mem_table)
            %Reminder mem_table = (seq #, shape #, dura, loop #)
            %         markers = {shape #}(time, marker type)
            
            new_markers = cell(size(markers));
            
            %Copy and reorganize markers
            for ctMk = 1:length(markers)
                %First, copy old markers, but reorganize for the AWG:
                %   - First 24 points are actually the last 24 points of
                %     the previous marker in the sequence
                %   - Then the normal markers is added, though its last 24
                %     points will be unused and removed at the end of this
                %     function.
                new_markers{ctMk} = [zeros(24,4); markers{ctMk}];
            end
            
            %Swap end of markers
            for ctMk = 1:length(new_markers)
                %Find if last 24 points are non-blank, then send to next
                %marker in sequence, otherwise don't care
                if(any(any(new_markers{ctMk}((end+1-24):end,:))))
                    %To send to next marker it must respect the following
                    %conditions: 1) the next marker is non-periodic
                    %            2) the next marker always follows the
                    %               current marker, even if it is used in more
                    %               than one sequence
                    
                    %First, find current marker position
                    cur_idx = find(mem_table(:,2) == ctMk);
                    
                    %If current marker is periodic, then following marker
                    %can be the current marker, i.e. copy last 24 points to
                    %first 24 points
                    if(all(mem_table(cur_idx,4) > 1))
                        new_markers{ctMk}(1:24,:) = new_markers{ctMk}((end+1-24):end,:);
                    end
                    
                    %Find following marker (only if in same sequence)
                    prev_marker = [];
                    if(cur_idx < size(mem_table,1))
                        cur_idx = cur_idx(mem_table(cur_idx,1) == mem_table(cur_idx+1,1));
                        next_marker = unique(mem_table(cur_idx+1,2));

                        %Look up all the previous markers before the next
                        %marker, to check again that we will not be placing
                        %the marker at wrong places
                        if(length(next_marker) == 1)
                            next_idx = find(mem_table(:,2) == next_marker);
                            if(all(next_idx > 1 & mem_table(next_idx,4) == 1)) %Check non-periodicity condition here
                                next_idx = next_idx(mem_table(next_idx,1) == mem_table(next_idx-1,1));
                                prev_marker = unique(mem_table(next_idx-1,2));
                            end
                        end
                    end
                    
                    %Now all conditions are respected
                    %Last 24 points of current marker can be send to first
                    %24 points of next marker
                    if(length(prev_marker) == 1 && prev_marker == ctMk)
                        new_markers{next_marker}(1:24,:) = new_markers{ctMk}((end+1-24):end,:); 
                    end
                end
            end
            
            %Remove last 24 points from markers
            for ctMk = 1:length(new_markers)
                new_markers{ctMk} = new_markers{ctMk}(1:(end-24),:);
            end
        end
        
        %Load data
        function load_data(obj,current_load_idx)
            awgLOG = LogClass('Loading data to AWG...',0);
                      
            %Current loading
            segm_load = obj.data_segm_load{current_load_idx};
            sequ_load = obj.data_sequ_load{current_load_idx};
            
            %Arb wave mode, allow much faster loading (especially for seq)
            obj.dev.write(':FUNC:MODE USER');
            
            %Delete all unused segments, sequences and adv sequences
            awgLOG.update('Deleting old segments and sequences',0)
            obj.clear_sequences(); %!!!!Clear segment not really required as
                                   %batch load of segment auto do it.
            
            %Load shapes and segments
            for ctChan = 1:2
                %Select channel
                obj.dev.write(sprintf(':INST:SEL CH%d',ctChan)); 
                
                %Segments
                awgLOG.update(['Loading segments in channel ' int2str(ctChan)],0);
                obj.load_segments(obj.data_shapes(segm_load),...
                                  obj.data_markers(segm_load),ctChan);
                
                %Sequences and advance sequences
                awgLOG.update(['Loading sequences in channel ' int2str(ctChan)],0)
                obj.load_sequences(sequ_load(:,1),sequ_load(:,2),sequ_load(:,3),awgLOG);
            end            
            
            %Close window
            awgLOG.close;
        end
        
        %Send shape data
        function load_segments(obj,shapes,markers,ctChan)
            %Concatenate all shapes to form a single waveform
            databinblock = [];
            segmLen = zeros(length(shapes),1);
            
            %Beginning of each segment (but first) must be 32 dummy points
            for ctSh = 1:length(shapes)
                %Create waveform binary_block ((2xbytes)xpoints)
                new_block = obj.create_binary_segment(shapes{ctSh}(:,ctChan),...
                                         markers{ctSh}(:,2*ctChan-1 + (0:1)));
                                     
                databinblock = [databinblock; new_block]; %#ok<AGROW>
                            
                segmLen(ctSh) = size(shapes{ctSh},1);
            end
            databinblock = databinblock(33:end); %Remove first dummy shapes

            %Write waveform (binary)
            obj.dev.binblockchunkwrite(':TRACE',16,databinblock,1e5);
            
            %Create segment definition binary block
            segmbinblock = uint32(segmLen);
            
            %Define segments from waveform
            obj.dev.binblockchunkwrite(':SEGM',32,segmbinblock,1e5);

            %Check for error and completion
            obj.dev.check();
        end

        %Assign sequence and advance sequence
        function load_sequences(obj,seq,seg,loop,awgLOG)
            %Loading
            unique_seq = unique(seq,'stable'); %Do not sort (e.g. stoch)
            
            %Sequence
            t0 = tic;
            awgLOG.update(['Sequence: 0/' int2str(length(unique_seq))],0)
            for ctSeq = 1:length(unique_seq)
                t = toc(t0);
                if(t > 5)
                    awgLOG.update(['Sequence: ' int2str(ctSeq) '/' ...
                                   int2str(length(unique_seq))],1)
                    t0 = tic;
                end
                    
                %Select new sequence
                obj.dev.write(sprintf(':SEQ:SEL %d',unique_seq(ctSeq)));
                
                %Write sequence with segments
                seq_idx = find(seq == unique_seq(ctSeq));
                binblock = obj.create_binary_sequence(seg(seq_idx),loop(seq_idx));
                obj.dev.binblockchunkwrite(':SEQ:DATA',32,binblock,1e5);
            end
            awgLOG.update(['Sequence: ' int2str(length(unique_seq)) '/' ...
                           int2str(length(unique_seq))],1)
            
            %Write advance sequence with sequences
            if(strcmp(obj.get_setting('trigmode1').val,'Internal') && ...
               strcmp(obj.get_setting('trigmode2.1').val,'AdvSeq'))
                binblock = obj.create_binary_sequence(unique_seq,...
                    obj.MAIN.SPP*ones(length(unique_seq),1));
                obj.dev.binblockchunkwrite(':ASEQ:DATA',32,binblock,1e5);            
            end
            
            %Check for error and completion
            obj.dev.check();
        end
        
        %Change sequence number
        function change_sequence(obj,seq)
            %Signal and marker outputs ON and OFF during sequence
            %switch. Necessary to prevent spurious outputs.
            intcontflag = strcmp(obj.get_setting('trigmode1').val,'Internal') && ...
                                  strcmp(obj.get_setting('trigmode2.1').val,'Continuous');

            obj.all_output(0);
            if(intcontflag) %Internal,Continuous
                obj.dev.write(':ABORT'); %Abort after output(0), can output weird stuff otherwise
            end

            %Load new data if necessary
            if(~any(seq == obj.data_sequ_load{obj.cur_load}(:,1)))
                obj.cur_load = obj.cur_load + 1;
                obj.load_data(obj.cur_load);
            end

            %Update sequence
            obj.dev.write(sprintf(':INST:SEL 1; :SEQ:SEL %d; :INST:SEL 2; :SEQ:SEL %d;',seq,seq));

            %Now can turn on AWG
            obj.all_output(1);
            if(intcontflag)
                obj.dev.write(':ENABLE');
            end

            %Wait necessary, otherwise instrument can lag with sweep
            %This does not check for errors though (slow and output weird)
            obj.dev.wait_till_complete();
        end
    end
    
    %Internal functions
    methods (Access = private)
        %Binary data block for segment
        function binblock = create_binary_segment(obj,shape,markers)
            binblock = shape;
            
            %Amplitude conversion -1<amp<1 => 0<amp<amp_range
            binblock = max(0,min(obj.amp_range,round((1+binblock)/2*obj.amp_range)));
            
            %Conversion to uint16
            binblock = uint16(binblock);   
            
            %Set stop bit and other requirements
            binblock = bitset(binblock,15,0);
            binblock(end-31:end) = bitset(binblock(end-31:end),15);
            binblock = bitset(binblock,16,0);
            
            %Set Markers (they are defined 4-by-4 points from index 24
            mark_idx = [];
            for ct = 1:(length(binblock)/32)
                mark_idx = [mark_idx (32*(ct-1) + (25:32))]; %#ok<AGROW>
            end
            
            %Markers are defined every 4 points (see also function
            %modif_markers_for_AWG)
            markers = markers(1:4:end,:);
            
            %Add markers to data block
            binblock = bitset(binblock,13,0);
            binblock = bitset(binblock,14,0);
            binblock(mark_idx) = bitset(binblock(mark_idx),13,markers(:,1));
            binblock(mark_idx) = bitset(binblock(mark_idx),14,markers(:,2));
            
            %Add dummy shapes (32 pts between each segment)
            binblock = [binblock(1)*ones(32,1,'uint16'); binblock];
        end

        %Binary date block for sequence
        function binblock = create_binary_sequence(~,seg,loop)
            binblock = zeros(2,length(seg),'uint32');
            
            %Loops
            binblock(1,:) = uint32(loop);
            
            %Segment number
            binblock(2,:) = uint32(uint16(seg));
            
            %To single vector
            binblock = binblock(:);           
        end
    end 
end



%This function reorganizes an experiment into a new experiment where
%pulses are grouped together as new pulses when they overlap/share
%period value
%Output: pulse shape, [X,Y,PC], start times, periodicity
function EXP = PGcompiler(PG)
global cLOG;

%Create log window for the compilation
cLOG = LogClass('Pulse GUI compiler',1);      
cLOG.open;
cLOG.update('****************************** Pulse GUI compiler ******************************',0);        

%Create EXP
Xflag = 0; Yflag = 0; PCflag = 0;
for ct = 1:numel(PG.params)
    cur_par = PG.params{ct};
    if(isa(cur_par,'ParameterClass'))
        switch(cur_par.param{1}) %Sweep X or Y
            case 2
                Xflag = 1;
            case 3
                Yflag = 1;
        end
        if(ischar(cur_par.param{2}) || ischar(cur_par.param{3})) %Check PC
            PCflag = 1;
        end
    end                
end
EXP = PGCompilerClass(max(1,Xflag*PG.MAIN.XPTS),...
                      max(1,Yflag*PG.MAIN.YPTS),...
                      max(1,PCflag*PG.MAIN.PCPTS));
EXP.gridDisc =  PG.child_mods{1}.gridDisc;
EXP.gridMin =  PG.child_mods{1}.gridMin;

EXPPTS = EXP.XPTS*EXP.YPTS*EXP.PCPTS;

%Find optimal RAST value
cLOG.update('- Compute optimal sampling frequency',0);
RAST = max(4200,find_optimal_RAST(PG));

if(isempty(RAST))
    EXP = [];
    return;
else
    EXP.set_RAST(RAST);
end

%Acquisition present
if(~any(strcmp(PG.params(:,PG.tabcol({'CHAN'})),'Acquisition')))
    cLOG.update('ERROR: NO ACQUISITION PULSE',0);
    EXP = [];
    return;
end

%Do separation for each phase cycling (TO DO: AVOID DUPLICATE FOR NO PC ROWS)
if(EXP.PCPTS <= 1)
    PCvalues = 1;
    cLOG.update('- No phase cycling found',0);
else
    PCvalues = 1:EXP.PCPTS;
    cLOG.update(['- ' int2str(EXP.PCPTS) ' phase cycle(s) found'],0);
end

%% Create all shapes and start defining sequence
rndVal_flag = 0;
cLOG.update('- Create pulse shapes',0);
chan_idx = PG.tabcol({'CHAN'});
shap_idx = PG.tabcol({'SHAP'});
par_idx = PG.tabcol({'FREQ' 'PHAS' 'AMPL' 'STAR' 'DURA' 'PERI' 'NBPE'});
for ctPC = PCvalues %For each phase cycling DO NOT PUT HERE!!!
    for ct = 1:size(PG.params,1) %For each pulse
        cur_data = PG.params(ct,:);

        shape_data = PG.library(PG.find_pulse_in_library(cur_data{shap_idx}),:);
        channel = cur_data{chan_idx};
        
        %We need to change shapes every time a parameter is sweped.
        %In particular, this is even the case for that start time as we
        %have to take into account both the problem of phase continuity and
        %the AWG restrictions of its 32 pts "grid".
        %Only sweeping the number of period does not result in more shape
        %creation.
        %WARNING: reordering of col here (see par_idx)!
        params = cur_data(par_idx);        
                                 
        %Find if any of the parameters are sweped
        %For NBPE, shape change from too few points to many points but
        %that's only 2xshapes DO SOMETHING BETTER HERE
        sweep_types = zeros(length(params),1);
        for ctType = 1:length(params)
            sweep_types(ctType) = params{ctType}.param{1};
        end       
            
        if(~isempty(find(sweep_types == 2 | sweep_types == 3,1))) %X & Y
            for ctX = 1:EXP.XPTS
            for ctY = 1:EXP.YPTS    
                %Create shape
                vals = PG.row_to_values(params,ctX,ctY,ctPC);
                if(isempty(vals))
                    EXP = [];
                    cLOG.close;
                    clear cLOG;
                    return;
                end
                [shape,time_vals,rndVal_flag] = make_shape(EXP,shape_data,...
                                                           vals,channel,rndVal_flag);
                last_idx = length(EXP.shapes)+1;
                EXP.shapes{last_idx} = shape;
                
                %Create sequence
                EXP.add_pulse2seq([ctX ctY ctPC],[last_idx time_vals]);
            end
            end
        elseif(~isempty(find(sweep_types == 2,1))) %Just X
            for ctX = 1:EXP.XPTS
                %Create shape
                vals = PG.row_to_values(params,ctX,1,ctPC);
                if(isempty(vals))
                    EXP = [];
                    cLOG.close;
                    clear cLOG;
                    return;
                end
                [shape,time_vals,rndVal_flag] = make_shape(EXP,shape_data,...
                                                           vals,channel,rndVal_flag);
                last_idx = length(EXP.shapes)+1;
                EXP.shapes{last_idx} = shape;
                
                %Create sequence
                EXP.add_pulse2seq(allcomb(ctX,1:EXP.YPTS,ctPC),...
                                                   [last_idx*ones(EXP.YPTS,1) time_vals(ones(EXP.YPTS,1),:)]);
            end
        elseif(~isempty(find(sweep_types == 3,1))) %Just Y   
            for ctY = 1:EXP.YPTS
                %Create shape
                vals = PG.row_to_values(params,1,ctY,ctPC);
                if(isempty(vals))
                    EXP = [];
                    cLOG.close;
                    clear cLOG;
                    return;
                end
                [shape,time_vals,rndVal_flag] = make_shape(EXP,shape_data,...
                                                           vals,channel,rndVal_flag);
                last_idx = length(EXP.shapes)+1;
                EXP.shapes{last_idx} = shape;
                
                %Create sequence
                EXP.add_pulse2seq(allcomb(1:EXP.XPTS,ctY,ctPC),...
                                                   [last_idx*ones(EXP.XPTS,1) time_vals(ones(EXP.XPTS,1),:)]);
            end
        else %no sweep
            vals = PG.row_to_values(params,1,1,ctPC);
            if(isempty(vals))
                EXP = [];
                cLOG.close;
                clear cLOG;
                return;
            end
            [shape,time_vals,rndVal_flag] = make_shape(EXP,shape_data,...
                                                       vals,channel,rndVal_flag);
            last_idx = length(EXP.shapes)+1;
            EXP.shapes{last_idx} = shape;
            
            %Create sequence
            EXP.add_pulse2seq(allcomb(1:EXP.XPTS,1:EXP.YPTS,ctPC),...
                                               [last_idx*ones(EXP.XPTS*EXP.YPTS,1) time_vals(ones(EXP.XPTS*EXP.YPTS,1),:)]);
        end
    end
end
if(rndVal_flag > 0)
    cLOG.update(['WARNING: ' int2str(rndVal_flag) ' TIMING(S) WERE ROUNDED'],0);
end

%% Find all overlapping pulses
comb_list = {};

%Shape channel temporary register
channels = cell(max(EXP.sequences(:,1)),1);
for ct = 1:length(channels)
    channels{ct} = EXP.shapes{ct}.channel;
end

%START LOOP
cLOG.update('- Combine overlapping pulses',0);
cLOG.update(['Sequence: 0/' int2str(EXPPTS)],0);
t0 = cputime;
for ctSeq = 1:EXPPTS %Loop through all X,Y,PC    
    t = cputime;
    if(t-t0 > 3)
        cLOG.update(['Sequence: ' int2str(ctSeq) '/' int2str(EXPPTS)],1);
        t0 = t;
    end
    
    %This loop can be very long: allow cancel
    if(cLOG.cancel_flag)
        EXP = [];
        cLOG.close;
        clear cLOG;
        return;
    end
    
    %Find idx of sequence pulses
    seq_idx = find(EXP.seq_idx == ctSeq);
    
    %Loop through each pulse combination
    ct1 = 1; ct2 = 2;
    while(length(seq_idx) > 1 && ct1 < length(seq_idx))
        cur_data = EXP.sequences(seq_idx,:); %shape,start,duration,period,period_nb       

        %Pulse starts and ends
        starts1 = cur_data(ct1,2) + (0:cur_data(ct1,5)-1).'*cur_data(ct1,4);
        ends1 = starts1 + cur_data(ct1,3)-1;

        starts2 = cur_data(ct2,2) + (0:cur_data(ct2,5)-1).'*cur_data(ct2,4);
        ends2 = starts2 + cur_data(ct2,3)-1;
        
        %Find overlapping pulses
        channel1 = channels{cur_data(ct1,1)};
        channel2 = channels{cur_data(ct2,1)};
        preDef1 = EXP.get_chan(channel1).preDefense;
        postDef1 = EXP.get_chan(channel1).postDefense;
        preDef2 = EXP.get_chan(channel2).preDefense;
        postDef2 = EXP.get_chan(channel2).postDefense;
       
        ovlap_idx = [];
        
        for ctA = 1:length(starts1)
            new_idx = find(1 == (((ends1(ctA)+postDef1) >= (starts2-preDef2) & ...
                                  (starts1(ctA)-preDef1) <= (ends2+postDef2))));
            ovlap_idx = [ovlap_idx; [repmat(ctA,length(new_idx),1) new_idx(:)]]; %#ok<AGROW>
        end
        
       %Check that overlapping pulses are not from different channels
       if(~isempty(ovlap_idx) && ~strcmp(channel1,channel2))
            cLOG.update('ERROR: PULSES FROM DIFFERENT CHANNELS CANNOT OVERLAP.',0);
            cLOG.update('THERE MAY BE SOME MINIMUM SEPARATION BETWEEN CHANNELS.',0);
            EXP = [];
            return;
        end
        
        %Previous overlap calculations only took into account proper pulse
        %overlap to check for errors, however non-overlap but within period
        %is also a problem, pulse must be splitted (or combined NOT DONE, ALL SPLITTED FOR NOW ).
        ovlap2_idx = [];
        if(cur_data(ct1,5) == 1)
            per1 = 0;
        else
            per1 = cur_data(ct1,4);
        end
        if(cur_data(ct2,5) == 1)
            per2 = 0;
        else
            per2 = cur_data(ct2,4);
        end
        for ctA = 1:length(starts1)
            new_idx = find(1 == (starts1(ctA) + per1 - 1 >= starts2 & ...
                                                starts1(ctA) <= starts2 + per2 - 1));
            ovlap2_idx = [ovlap2_idx; [repmat(ctA,length(new_idx),1) new_idx(:)]]; %#ok<AGROW>
        end
        
        %Remove any overlap from ovlap2
        if(~isempty(ovlap_idx) && ~isempty(ovlap2_idx))
            taken_idx = [];
            for ctOv = 1:size(ovlap_idx,1)
                taken_idx = [taken_idx; ...
                                      find(ovlap2_idx(:,1) == ovlap_idx(ctOv,1) | ...
                                              ovlap2_idx(:,2) == ovlap_idx(ctOv,2))]; %#ok<AGROW>
            end
            remain_idx = setdiff(1:size(ovlap2_idx,1),taken_idx);
            ovlap2_idx = ovlap2_idx(remain_idx,:);
        end
        
       %%%%%%%%%%%
       %Main calculations
        if(~isempty(ovlap_idx) || ~isempty(ovlap2_idx))
            %%%%%%%%%%%
            %SPLITTING
            
            %New pulses from splitted non overlapping pulses
            %Pulse 1
            non_ovlap_idx1 = setdiff(1:length(starts1),ovlap_idx(:,1));
            if(~isempty(non_ovlap_idx1))
                non_ovlap_lims = [non_ovlap_idx1(1)-1 ...
                                                 non_ovlap_idx1(non_ovlap_idx1(2:end)-non_ovlap_idx1(1:end-1)~=1) ...
                                                 non_ovlap_idx1(end)];
            else
                non_ovlap_lims = [];
            end
            if(~isempty(ovlap2_idx))
                ovlap2_lims = [ovlap2_idx(:,1).'-1 ...
                                          ovlap2_idx(:,1).'];
            else
                ovlap2_lims = [];
            end
            lim = [0 non_ovlap_lims ovlap2_lims length(starts1)];
            lim = unique(lim);
            for ctL = 1:length(lim)-1
                grp_idx = lim(ctL)+1:lim(ctL+1);

                if(~isempty(grp_idx) && (any(grp_idx(1) == [non_ovlap_idx1  ovlap2_idx(:,1).'])))
                    %Add pulse
                    new_data = cur_data(ct1,:);
                    new_data(2) = starts1(grp_idx(1));
                    new_data(5) = length(grp_idx);
                    EXP.add_pulse2seq(ctSeq,new_data);
                end
            end

            %Pulse 2
            non_ovlap_idx2 = setdiff(1:length(starts2),ovlap_idx(:,2));
            if(~isempty(non_ovlap_idx2))
                non_ovlap_lims = [non_ovlap_idx2(1)-1 ...
                                                 non_ovlap_idx2(non_ovlap_idx2(2:end)-non_ovlap_idx2(1:end-1)~=1) ...
                                                 non_ovlap_idx2(end)];
            else
                non_ovlap_lims = [];
            end
            if(~isempty(ovlap2_idx))
                ovlap2_lims = [ovlap2_idx(:,2).'-1 ...
                                          ovlap2_idx(:,2).'];
            else
                ovlap2_lims = [];
            end
            lim = [0 non_ovlap_lims ovlap2_lims length(starts2)];
            lim = unique(lim);
            for ctL = 1:length(lim)-1
                grp_idx = lim(ctL)+1:lim(ctL+1);

                 if(~isempty(grp_idx) && (any(grp_idx(1) == [non_ovlap_idx2  ovlap2_idx(:,2).'])))
                    %Add pulse
                    new_data = cur_data(ct2,:);
                    new_data(2) = starts2(grp_idx(1));
                    new_data(5) = length(grp_idx);
                    EXP.add_pulse2seq(ctSeq,new_data);
                end
            end
            
            %%%%%%%%%%
            %COMBINGING overlapping pulses
        
            %Find idx of more than 2 overlapping pulses
            comb_ovlap_idx = (1:size(ovlap_idx,1)).';
            for ctA = 1:size(ovlap_idx,1)-1
                ctB = ctA+1:size(ovlap_idx,1);
                idx = find(ovlap_idx(ctA,1) == ovlap_idx(ctB,1) | ...                
                           ovlap_idx(ctA,2) == ovlap_idx(ctB,2));

                if(~isempty(idx))
                    comb_ovlap_idx(ctB(idx)) = comb_ovlap_idx(ctA);
                end
            end
            
            if(~isempty(comb_ovlap_idx))
                %Group new shapes together when result from same overlap
                %First, defines shape combination
                [CO_idx,~,old_CO_idx] = unique(comb_ovlap_idx,'stable');
                comb_def = cell(length(CO_idx),2);
                Lcd = 0;
                for ctCO = 1:length(CO_idx)
                    idx = ovlap_idx(old_CO_idx == ctCO,:);
                    min_start = min([starts1(idx(:,1)); starts2(idx(:,2))]);
                    shape_starts = [starts1(idx(:,1)); starts2(idx(:,2))] - min_start;
                    shape_idx = [idx(:,1); idx(:,2)];
                    comb_def(ctCO,:) = {shape_idx.' shape_starts.'};
                    Lcd = max(Lcd,size(comb_def{ctCO},1));
                end

                %Find same overlap
                comb_def_mat = nan*zeros(length(CO_idx),2*Lcd);
                for ctCO = 1:length(CO_idx)
                    comb_def_mat(ctCO,1:2*length(comb_def{ctCO})) = ...
                        [comb_def{ctCO,1} comb_def{ctCO,2}];
                end
                [~,NS_idx,old_idx] = unique(comb_def_mat,'rows','stable');

                %New shapes
                for ctNS = 1:length(NS_idx)
                    cur_idx = ovlap_idx(old_CO_idx == NS_idx(ctNS),:);

                    %Combine shapes
                    comb_list(end+1,:) = {[cur_data(ct1,1) cur_data(ct2,1)] ...
                                          [starts1(cur_idx(:,1)) starts2(cur_idx(:,2))]}; %#ok<AGROW>
                    channels{end+1} = channel1;  %#ok<AGROW>

                    %Add pulse
                    grp_ovlap_idx = cell2mat(comb_def(old_idx == NS_idx(ctNS),1));

                    %Find nb of period and create new sequence for each group
                    %of periodic pulse
                    grp_idx = grp_ovlap_idx(1,:);
                    for ctP = 1:size(grp_ovlap_idx,1)
                        if(size(grp_ovlap_idx,1) > 1 && ctP < size(grp_ovlap_idx,1) &&...
                           all((grp_ovlap_idx(ctP+1,:)-grp_ovlap_idx(ctP,:)) == 1))
                            grp_idx(end+1,:) = grp_ovlap_idx(ctP+1,:);  %#ok<AGROW>
                        else
                            if(~isempty(grp_idx))
                                %Add pulse
                                new_data = cur_data(ct1,:);
                                if(size(grp_ovlap_idx,1) > 1 && ... %Should not happen
                                        cur_data(ct1,4) ~= cur_data(ct2,4))
                                    cLOG.update('ERROR',0);
                                    EXP = [];
                                    return;
                                elseif(size(grp_ovlap_idx,1) == 1)
                                    new_data(4) = 0;
                                end

                                new_data(1) = length(EXP.shapes)+size(comb_list,1);%last_idx;

                                s1 = starts1(grp_idx(1,1:size(grp_idx,2)/2));
                                s2 = starts2(grp_idx(1,size(grp_idx,2)/2+1:end));
                                new_data(2) = min([s1(:); s2(:)]);

                                s0 = min(cur_data([ct1 ct2],2));
                                d1 = cur_data(ct1,2) - s0 + cur_data(ct1,3) + cur_data(ct1,4)*(size(s1,1)-1);
                                d2 = cur_data(ct2,2) - s0 + cur_data(ct2,3) + cur_data(ct1,4)*(size(s2,1)-1);
                                new_data(3) = max([d1 d2]);

                                new_data(5) = size(grp_idx,1);
                                EXP.add_pulse2seq(ctSeq,new_data);
                            end

                            %Restart a group
                            if(ctP+1 <= size(grp_ovlap_idx,1))
                                grp_idx = grp_ovlap_idx(ctP+1,:);
                            end
                        end
                    end
                end
            end

            %Remove old pulses
            squeezed_idx = setdiff(1:length(EXP.seq_idx),seq_idx([ct1 ct2]));
            EXP.sequences = EXP.sequences(squeezed_idx,:);
            EXP.seq_idx = EXP.seq_idx(squeezed_idx,:);
            
            %Reinitialize pulse idx as the sequence was modified
            %NOT EFFICIENT
            ct1 = max(1,ct1-1);
            ct2 = ct1;
        end
        
        %Find idx of sequence pulses (must be checked everytime as sequence
        %length can be modified in while loop)
        seq_idx = find(EXP.seq_idx == ctSeq);
        
        %Update indices
        ct2 = ct2 + 1;
        if(ct2 > length(seq_idx))
            ct1 = ct1 + 1;
            ct2 = ct1 + 1;
        end
    end
end
cLOG.update(['Sequence: ' int2str(EXPPTS) '/' int2str(EXPPTS)],1);
                     
%% Combine shapes using comb_list(shape1,start1,end1,shape2,start2,end2)
cLOG.update('- Combine shapes',1);
if(~isempty(comb_list))
    %Rewrite comb_list cell to matrix
    Lcl = 0;
    for ctCL = 1:size(comb_list,1)
        Lcl = max(Lcl,size(comb_list{ctCL,2},1));
    end
    comb_list_mat = nan*zeros(size(comb_list,1),2+2*Lcl);
    for ctCL = 1:size(comb_list,1)
        %Sort list as [pulse a, pulse b] = [pulse b, pulse a]
        [~,sort_idx] = sort([comb_list{ctCL,1}(1) comb_list{ctCL,1}(2)]);
        
        %Remove min_start from pulses and sort them by position
        p1 = comb_list{ctCL,1}(sort_idx(1));
        list1 = comb_list{ctCL,2}(:,sort_idx(1));
        p2 = comb_list{ctCL,1}(sort_idx(2));
        list2 = comb_list{ctCL,2}(:,sort_idx(2));
        
        min_start = min([list1(:);list2(:)]);
        list1 = list1 - min_start;
        list2 = list2 - min_start;
%         
        [list1,sort_idx] = sort(list1);
        list2 = list2(sort_idx);
        
        %Add to matrix
        comb_list_mat(ctCL,1:2+2*size(comb_list{ctCL,2},1)) = [p1;list1;p2;list2].';
    end
    
    %Delete duplicates
    Ls = length(EXP.shapes);
        
    comb_list = comb_list_mat;
    comb_idx = 1:size(comb_list,1);
    ct1 = 1;
    while(ct1 < size(comb_list,1))
        Lcc = length(find(isnan(comb_list(ct1,:))==0))/2;
        ct2 = ct1;
        while(ct2 > ct1 && ct2 < size(comb_list,1))
            ct2 = ct2+1;
            if(comb_list(ct1,:) == comb_list(ct2,:))
                comb_idx(ct2) = ct1;
                comb_idx(ct2+1:end) = comb_idx(ct2+1:end) - 1;
                comb_list(comb_list(:,1) == Ls + ct2,1) = Ls + ct1;
                comb_list(comb_list(:,1+Lcc) == Ls + ct2,1+Lcc) = Ls + ct1;
                comb_list = [comb_list(1:ct2-1,:); comb_list(ct2+1:end,:)];
                ct2 = ct2-1;
            end
        end
        ct1 = ct1+1;
    end

    if(any(comb_list(comb_idx,:) ~= comb_list_mat))
        error('(@ shape combine duplicate removal) Compiler bug!'); %check
    end
    
    %Replace in sequence false shape idx (idx to comb_list) by real idx
    false_idx = find(EXP.sequences(:,1) > Ls);
    EXP.sequences(false_idx,1) = Ls + comb_idx(EXP.sequences(false_idx,1) - Ls);

    %Combine shapes
    for ct1 = 1:size(comb_list,1)
        Lcc = length(find(isnan(comb_list(ct1,:))==0))/2;
        cur_comb = [comb_list(ct1,1:Lcc);comb_list(ct1,Lcc+1:2*Lcc)];
        
        last_idx = length(EXP.shapes) + 1;
        [EXP.shapes{last_idx},~] = combine_shapes(...
                EXP.shapes{cur_comb(1,1)},cur_comb(1,2),...
                EXP.shapes{cur_comb(2,1)},cur_comb(2,2));
        start_val = min(cur_comb(1,2),cur_comb(2,2));
        
        %Loop through multiple shape combination (occuring due to period)
        for ct2 = 3:Lcc
            new_idx = find(cur_comb(:,ct2) ~= cur_comb(:,ct2-1));  
            
            [EXP.shapes{last_idx},~] = combine_shapes(...
                EXP.shapes{last_idx},start_val,...
                EXP.shapes{cur_comb(new_idx,1)},cur_comb(new_idx,ct2));
            
            start_val = min(start_val,cur_comb(new_idx,ct2));
        end

        %within list, some shapes number are already combined shapes
        %=> must refresh list while looping.
        cur_idx = Ls + find(ct1 == comb_idx);
        for ct2 = 1:length(cur_idx)
            comb_list(comb_list(:,1) == cur_idx(ct2),1) = Ls + ct1;
            comb_list(comb_list(:,2) == cur_idx(ct2),2) = Ls + ct1;
        end
    end
end
EXP.remove_uncalled_shapes();

%% Modifications for AWG (in particular Nx32 pts grid, N>=gridMin)
%This also modify the shapes to be longer in order to accept markers
cLOG.update('- Modify shapes for AWG, create Markers',0);

%Shift all pulses to allow markers gate
EXP.sequences(:,2) = EXP.sequences(:,2) + ....
    max([EXP.Acq.preMarker,EXP.MW.preMarker,EXP.RF.preMarker,EXP.User.preMarker]);

%Convert shape_rep to period because there is no difference for the AWG
%And during shape creation, shape_rep and period could not be on together
cLOG.update('Make single loop type',0);
for ctSh = 1:length(EXP.shapes)
    new_period_nb = EXP.shapes{ctSh}.shape_rep;
    if(new_period_nb > 1)
        EXP.shapes{ctSh}.shape_rep = 1;
        new_period = size(EXP.shapes{ctSh}.shape,1);
        
        %Update duration, period(=duration), period_nb 
        idx = find(EXP.sequences(:,1) == ctSh);
        EXP.sequences(idx,[3 4]) = new_period;
        EXP.sequences(idx,5) = new_period_nb;
    end
end

%1) Clip pulses to Npts grid, increase length to gridMin+NxgridDisc (to ensure 
%that there is enough space for blank pulses) with zeros to start 
%combining too short pulses, separate periodic pulse into three pre-main-post 
%pulses in order to be able to combine with nearby pulses if necessary
%For main, make sure it is a multiple of gridDisc that will be repeated
%Also insert blank in periodic shapes.
cLOG.update(['Clip to ' int2str(EXP.gridDisc) '-'...
                        int2str(EXP.gridMin) ' points grid'],1);
Lshape = length(EXP.shapes); %define beforehand as is changed in loop
for ctSh = 1:Lshape
    cur_shape = EXP.shapes{ctSh}.shape;
    
    %Prepare timings for markers
    cur_channel = EXP.shapes{ctSh}.channel;
    markerPre = EXP.get_chan(cur_channel).preMarker;
    markerPost = EXP.get_chan(cur_channel).postMarker;
    
    %Find all shape param from sequence = [dura,period,period_nb]
    seq_idx = find(EXP.sequences(:,1) == ctSh);
        
    %All pulses sharing same shape should have similar parameter. 
    %Because some periodic pulses may be splitted into non-periodic pulses, 
    %they may share the same shape but with different starts. So we have to 
    %loop over each starts
%     if(size(unique(EXP.sequences(seq_idx,3:5),'rows'),1) > 1)
%         error('Shape parameters from seq should all be the same.');
%     end
    [starts,uni_st_idx] = unique(EXP.sequences(seq_idx,2));
    
    shape_params = EXP.sequences(seq_idx(uni_st_idx),2:5);
    for ctStart = 1:length(starts)
        shape_param = shape_params(ctStart,:);
        real_idx = seq_idx(EXP.sequences(seq_idx,2) == starts(ctStart));
        
        %New start after clipping
        new_start = floor((shape_param(1)-markerPre)/EXP.gridDisc)*EXP.gridDisc;
        
        if(~isempty(shape_param) && ~isempty(seq_idx));
            %Non periodic pulse
            if(shape_param(4) == 1)
                %We ensure also that marker will be with its shape.
                start_delay = shape_param(1)-new_start;
                new_duration = max(EXP.gridMin,ceil((shape_param(2)+start_delay...
                                                +markerPost)/EXP.gridDisc)*EXP.gridDisc);

                new_shape = zeros(new_duration,2);            
                new_shape(start_delay+(1:size(cur_shape,1)),:) = cur_shape;
                
                %Update shape and sequence
                if(ctStart == 1)
                    EXP.shapes{ctSh}.shape = new_shape;
                else
                    new_idx = length(EXP.shapes)+1;
                    EXP.shapes{new_idx} = ShapeClass(new_shape,1,cur_channel,0);
                    EXP.sequences(real_idx,1) = new_idx;
                end

                %Update sequence
                EXP.sequences(real_idx,2) = new_start;
                EXP.sequences(real_idx,3) = new_duration;

            else %Periodic pulses
                %REMINDER: period is not necessarily integer if it comes from 
                %shape_rep. Pulse must be splitted into 3 pulses for:
                %1)3) Pre and Post-pulse because there might be some blank
                %from clipping 32 that cannot be repeated.
                %2) Main repeated pulse
                new_per = lcm(shape_param(3),32);
                new_per = ceil(EXP.gridMin/new_per)*new_per;
                %The new period is a multiple of 32 and minimum gridMin in
                %length. Because of the pre-post shapes, this pulse is the
                %only one which does not have to be attached to the
                %gridDisc
                
                new_per_nb = shape_param(4)*shape_param(3)/new_per; 
    
                %Check if it's worth keeping periodicity (Memory space vs size)       
                if(new_per_nb <= 6) %Don't keep periodicity                
                    %Create new non-periodic shape (complicated due to non-integer 
                    %and to avoid too much blank at the end)
                    per_shape = zeros(shape_param(3),2);
                    per_shape(1:size(cur_shape,1),:) = cur_shape;

                    int_per_nb = floor(shape_param(4));
                    dec_per_nb = shape_param(4) - int_per_nb;
                    temp_duration = round(shape_param(3)*(int_per_nb-1)...
                                                              + (1+dec_per_nb)*shape_param(2));
                    temp_shape = concPerShape(per_shape,ceil(shape_param(4)));
                    temp_shape = temp_shape(1:temp_duration,:);

                    %Final pulse duration after clipping
                    start_delay = shape_param(1)-new_start;
                    new_duration = max(EXP.gridMin,ceil((size(temp_shape,1)+...
                        start_delay+markerPost)/EXP.gridDisc)*EXP.gridDisc);

                    new_shape = zeros(new_duration,2);
                    new_shape(start_delay+(1:size(temp_shape,1)),:) = temp_shape;

                    %Update shape and sequence
                    if(ctStart == 1)
                        EXP.shapes{ctSh}.shape = new_shape;
                    else
                        new_idx = length(EXP.shapes)+1;
                        EXP.shapes{new_idx} = ShapeClass(new_shape,1,cur_channel,0);
                        EXP.sequences(real_idx,1) = new_idx;
                    end

                    %Update sequence
                    new_data = [new_start new_duration 0 1];
                    EXP.sequences(real_idx,2:5) = new_data(ones(length(real_idx),1),:);

                else %Keep periodicity
                     %From AWG, if too many loop expected
                    if(new_per_nb > 1048575)
                        new_per = new_per*ceil(new_per_nb/1048575);
                    end

                    %Make a shape that contains all the necessary information
                    %but do not make full shape because if too many period that
                    %could take too much memory
                    per_shape = zeros(shape_param(3),2);
                    per_shape(1:size(cur_shape,1),:) = cur_shape;

                    rep_nb = ceil((2*EXP.gridMin+new_per)/shape_param(3));
                    temp_shape = concPerShape(per_shape,rep_nb);

                    %1)Pre shape (2*gridMin necessary in case there is a pulse close
                    %before)
                    pre_delay = shape_param(1)-new_start;
                    pre_duration = max(2*EXP.gridMin,ceil(pre_delay/EXP.gridDisc)*EXP.gridDisc);
                    pre_shape = zeros(pre_duration,2);
                    pre_shape(pre_delay+1:end,:) = temp_shape(1:pre_duration-pre_delay,:);

                    %2)Main shape: is modified by pre shape
                    %For pulse to be repeated, the period must be Nx32
                    main_delay = pre_duration-pre_delay;

                    tot_len = shape_param(3)*(shape_param(4)-1) + shape_param(2);
                    main_per_nb = floor((tot_len-main_delay)/new_per)-1;
                    
                    main_shape = temp_shape(main_delay+(1:new_per),:);

                    %3)Post shape
                    post_delay = main_delay + new_per*main_per_nb;
                    temp_shape = concPerShape(main_shape,(tot_len-post_delay)/size(main_shape,1));
                    post_duration = max(2*EXP.gridMin,ceil((size(temp_shape,1) + markerPost) ...
                                                        /EXP.gridDisc)*EXP.gridDisc);
                    post_duration = ceil((size(pre_shape,1) + new_per*main_per_nb + post_duration)...
                                                      /EXP.gridDisc)*EXP.gridDisc - size(pre_shape,1) - new_per*main_per_nb;
                    post_shape = zeros(post_duration,2);
                    post_shape(1:size(temp_shape,1),:) = temp_shape;

                    %Update shape and sequence
                    new_idx = length(EXP.shapes);
                    if(ctStart == 1)
                        EXP.shapes{ctSh}.shape = main_shape;
                    else
                        new_idx = new_idx + 1;
                        EXP.shapes{new_idx} = ShapeClass(main_shape,1,cur_channel,0);
                        EXP.sequences(real_idx,1) = new_idx;
                    end

                    %Update shapes
                    EXP.shapes{new_idx+1} = ShapeClass(pre_shape,1,cur_channel,0);
                    EXP.shapes{new_idx+2} = ShapeClass(post_shape,1,cur_channel,0);

                    %Update sequence
                    %Main
                    EXP.sequences(real_idx,2) = new_start+size(pre_shape,1);
                    EXP.sequences(real_idx,[3 4]) = new_per;
                    EXP.sequences(real_idx,5) = main_per_nb;                    

                    %Pre
                    pre_data = [new_idx+1 new_start size(pre_shape,1) 0 1];
                    EXP.add_pulse2seq(EXP.seq_idx(real_idx),pre_data(ones(length(real_idx),1),:));

                    %Post
                    post_data = [new_idx+2 ...
                                           new_start+size(pre_shape,1)+new_per*main_per_nb ...
                                           size(post_shape,1) 0 1];
                    EXP.add_pulse2seq(EXP.seq_idx(real_idx),post_data(ones(length(real_idx),1),:));  
                end 
            end  
        end
    end
end

%Create markers. This has to be done before combining pulses because
%afterward channels might be mixed.
%This is not done in previous loop because it might get complicated for
%periodic shapes.
cLOG.update('Create markers',1);
for ctSh = 1:length(EXP.shapes)
    shape = EXP.shapes{ctSh}.shape;
    shape_dura = size(shape,1);
    
    cur_shape = false(shape_dura,1);
    cur_shape((shape(:,1) ~= 0) | (shape(:,2) ~= 0)) = true; %something in I/Q
    
    %Prepare timings for markers
    cur_channel = EXP.shapes{ctSh}.channel;
    markerPre = EXP.get_chan(cur_channel).preMarker;
    markerPost = EXP.get_chan(cur_channel).postMarker;
    markerChan = EXP.get_chan(cur_channel).index;

    %Because blanks in pulse can be long, we can't put marker for the whole
    %shape length. We have to insert it around each non-zero values.
    if(markerChan ~= 0)
        %Find rising and lowering edge of shape
        edges = find(cur_shape(2:end) - cur_shape(1:end-1) ~= 0);

        rising_edges = edges(~cur_shape(edges))+1;
        lowering_edges = edges(cur_shape(edges));
        
        if(isempty(rising_edges) || ...
         (~isempty(lowering_edges) && rising_edges(1) > lowering_edges(1)))
            rising_edges = [1; rising_edges];
        end
        if(isempty(lowering_edges) || ...
         (~isempty(rising_edges) && rising_edges(end) > lowering_edges(end)))
            lowering_edges = [lowering_edges; shape_dura];
        end
        
        %Create markers
        new_markers = false(shape_dura,4);
        for ct = 1:length(rising_edges)
            %Marker resolution is 4 sample clock cycle
            mark_min = 1+max(0,floor((rising_edges(ct)-markerPre-1)/4)*4);
            mark_max = ceil(min(shape_dura,lowering_edges(ct)+markerPost)/4)*4;
                    
            %Add marker
            new_markers(mark_min:mark_max,markerChan) = true; 
        end       
        
        EXP.shapes{ctSh}.markers = new_markers;
    else
        EXP.shapes{ctSh}.markers = false(shape_dura,4);
    end
end

%Combine pulses now that they're longer from NxgridDisc requirement
%USE COMB LIST LIKE BEFORE, PROBABLY MAKE IT A FUNCTION
cLOG.update('Combine pulses',1);
for ctSeq = 1:EXPPTS
    %Find idx of sequence pulses
    seq_idx = find(EXP.seq_idx == ctSeq);
    
    %Find non-periodic pulses only because periodic ones have already been
    %splitted into 3 shapes. There is no reason anymore that periodic shape
    %should have any kind of overlap with another shape.
    seq_idx = seq_idx(EXP.sequences(seq_idx,5) == 1);
    cur_data = EXP.sequences(seq_idx,:);
    
    %Pulse starts and ends 
    starts = cur_data(:,2);
    ends = starts + cur_data(:,3)-1;
    
    %Find overlap
    ovlap_idx = [];
    for ctA = 1:size(cur_data,1)
        new_idx = find(1 == (ends(ctA) >= starts & starts(ctA) <= ends));
        ovlap_idx = [ovlap_idx; [ctA*ones(length(new_idx),1) new_idx(:)]]; %#ok<AGROW>
    end
    
    if(~isempty(ovlap_idx)) %remove pulse overlap with itself
        ovlap_idx = ovlap_idx(ovlap_idx(:,1) ~= ovlap_idx(:,2),:);
    end
    
    if(~isempty(ovlap_idx))
        ovlap_idx = unique(sort(ovlap_idx,2),'rows');

        %Find idx of more than 2 overlapping pulses
        comb_ovlap_idx = (1:size(ovlap_idx,1)).';
        for ctA = 1:size(ovlap_idx,1)-1
            ctB = ctA+1:size(ovlap_idx,1);
            idx = find(ovlap_idx(ctA,1) == ovlap_idx(ctB,1) | ...
                       ovlap_idx(ctA,1) == ovlap_idx(ctB,2) | ...
                       ovlap_idx(ctA,2) == ovlap_idx(ctB,1) | ...
                       ovlap_idx(ctA,2) == ovlap_idx(ctB,2));

            if(~isempty(idx))
                comb_ovlap_idx(ctB(idx)) = comb_ovlap_idx(ctA);
            end
        end

        %Combine
        grp_idx = unique(comb_ovlap_idx);
        idx_to_clean = [];
        for ctG = 1:length(grp_idx) %For each overlapping groups
            %Get indices of pulses in group
            cur_ovlap = ovlap_idx(comb_ovlap_idx == grp_idx(ctG),:);
            cur_ovlap = unique(cur_ovlap(:)); 
            
            %Create a new shape
            new_shape = EXP.shapes{cur_data(cur_ovlap(1),1)};
            new_start = starts(cur_ovlap(1));

            first_shape_idx = new_start + find(any(new_shape.shape,2) == 1,1,'first');
            last_shape_idx = new_start + find(any(new_shape.shape,2) == 1,1,'last');
            first_shape_nb = cur_ovlap(1); 
            last_shape_nb = cur_ovlap(1); 
            
            for ctS = 2:length(cur_ovlap)
                ctSS = cur_ovlap(ctS);
                cur_shape = EXP.shapes{cur_data(ctSS,1)};
                [new_shape,new_start] = combine_shapes(new_shape,new_start,...
                                                                                           cur_shape,starts(ctSS));
                                                                                  
                first_shape_idx2 = starts(ctSS) + find(any(cur_shape.shape,2) == 1,1,'first');
                last_shape_idx2 = starts(ctSS) + find(any(cur_shape.shape,2) == 1,1,'last');
                if(first_shape_idx2  < first_shape_idx)
                    first_shape_nb = ctSS;
                    first_shape_idx = first_shape_idx2;
                end
                if(last_shape_idx2  > last_shape_idx)
                    last_shape_nb = ctSS;
                    last_shape_idx = last_shape_idx2;
                end
            end
            
            %Must truncate combined shape if zeros are due to marker only
            %When combining can cause problem when one of the pulse is a
            %post or pre periodic shape
            new_min_pos = starts(first_shape_nb)-new_start+1;
            new_max_pos =  ends(last_shape_nb)-new_start+1;
            
            new_shape.shape = new_shape.shape(new_min_pos:new_max_pos,:);
            new_shape.markers = new_shape.markers(new_min_pos:new_max_pos,:);
            new_start = starts(first_shape_nb);
            
            %Update EXP
            new_idx = length(EXP.shapes)+1;
            EXP.shapes{new_idx} = new_shape;
            EXP.sequences(seq_idx(cur_ovlap(1)),[1 2 3]) = ...
                [new_idx new_start size(new_shape.shape,1)];

            %Indices to clean
            idx_to_clean = [idx_to_clean; cur_ovlap(2:end)]; %#ok<AGROW>
        end
        
        %Remove old pulses
        squeezed_idx = setdiff(1:length(EXP.seq_idx),seq_idx(idx_to_clean));
        EXP.sequences = EXP.sequences(squeezed_idx,:);
        EXP.seq_idx = EXP.seq_idx(squeezed_idx,:);
    end    
end
EXP.remove_uncalled_shapes();

%Check TWT duty cycle
SRTrast = floor(PG.MAIN.SRT*(RAST*1e6));
for ctSeq = 1:EXPPTS
    %Find idx of sequence pulses
    seq_idx = find(EXP.seq_idx == ctSeq);
    
    %Get total time on during sequence
    total_TWT_time = 0;
    total_RF_time = 0;
    for ct = 1:length(seq_idx)
        marker = EXP.shapes{EXP.sequences(seq_idx(ct),1)}.markers(:,2);
        total_TWT_time = total_TWT_time + length(find(marker~=0));
        
        marker = EXP.shapes{EXP.sequences(seq_idx(ct),1)}.markers(:,3);
        total_RF_time = total_RF_time + length(find(marker~=0));
    end
    if(total_TWT_time > SRTrast*EXP.MW.dutyCycle)
        cLOG.update('ERROR: TWT DUTY CYCLE IS NOT RESPECTED',0);
        EXP = [];
        return;
    end
    if(total_RF_time > SRTrast*EXP.RF.dutyCycle)
        cLOG.update('ERROR: RF DUTY CYCLE IS NOT RESPECTED',0);
        EXP = [];
        return;
    end
end

%% Clean up
%Clean up shape (remove when appears twice)
cLOG.update('- Clean up sequences',1);
EXP.clean_shapes(cLOG);

%Sort pulses in sequence
EXP.sort_sequences();

%% Close window
cLOG.update('',1);
cLOG.update('*********************************** Summary ***********************************',0);
cLOG.update(['Sampling frequency = ' num2str(RAST,4) ' MHz'],0);

cLOG.update([int2str(EXPPTS) ' sequence(s), ' ...
            int2str(length(EXP.shapes)) ' shape(s) created'],0);

est_time = PG.MAIN.SPP*PG.MAIN.SRT*PG.MAIN.AVG*EXPPTS/60;
if(est_time < 1)
    cLOG.update('Estimated experiment time: < 1 mn',0);
elseif(est_time/60 < 1)
    cLOG.update(['Estimated experiment time: ' int2str(est_time) ' mn(s)'],0);
else
    hours = floor(est_time/60);
    cLOG.update(['Estimated experiment time: ' int2str(hours) ' hr(s) '...
                                int2str(est_time - 60*hours) ' mn(s)'],0);
end

cLOG.update(['COMPILE SUCCESSFUL: ' int2str(cLOG.warnings) ' WARNING(S)'],0);

if(cLOG.warnings == 0)
    cLOG.close;
    clear cLOG;
end
end       

%Function that find optimal sampling frequency RAST IN MHZ
function RAST = find_optimal_RAST(PG)
    global cLOG;
    AWG = PG.child_mods{1};
    
    maxRAST = AWG.max_RAST;
    
    LMS_conv_error = 0.2;
    
    %Find all RAST for each pulse
    RASTs = [];
    
    for ct = 1:size(PG.params,1);
        %Normal square pulse
        if(strcmpi(PG.params{ct,PG.tabcol({'SHAP'})},'Square'))
            %Check maximum frequency first
            [min_freq,max_freq] = PG.params{ct,PG.tabcol({'FREQ'})}.get_sweep_min_max();
            max_freq = max(abs(min_freq),abs(max_freq));
            
            %Create RAST: highest frequency to define oscillation OR proper
            %pulse shape if small duration
            
            %Oscillation frequency (16*max_freq + round to single digit value 
            %otherwise LCM might be weird)   
            if(max_freq ~= 0)
                temp_freq = 16*max_freq;
                if(temp_freq > 1)
                    k = 1;
                    while(temp_freq/10^k > 1)
                        k = k + 1;
                    end
                    max_freq = ceil(temp_freq/10^(k-1))*10^(k-1);
                elseif(temp_freq < 1)
                    k = 1;
                    while(temp_freq*10^k < 1)
                        k = k + 1;
                    end
                    max_freq = ceil(temp_freq*10^k)/10^k;
                end
            end
                
            RASTs(end+1) = max_freq;
            
            %Duration
            [min_dura,~] = PG.params{ct,PG.tabcol({'DURA'})}.get_sweep_min_max();
            if(PG.params{ct,PG.tabcol({'DURA'})}.param{1} ~= 1) %dura val or step
                min_dura = min(min_dura,PG.params{ct,PG.tabcol({'DURA'})}.param{3});
            end
            
            if(min_dura ~= 0)
                RASTs(end+1) = 1/(min_dura*1e-3); %ns->us = mhz-1
            end
              
        else %Look up library (Library unit is ns/GHz!)
            arb_pulse_idx = PG.find_pulse_in_library(PG.params{ct,PG.tabcol({'SHAP'})});
            if(~isempty(arb_pulse_idx))
                text = PG.library{arb_pulse_idx,2}; %pulse values
                if(~ischar(text)) %mat file with values
                    dt = text(2,1) - text(1,1);
                    if(dt ~= 0)
                        RASTs(end+1) = 1/(dt*1e-3); %ns -> MHz
                    end
                else %loaded script or input arb GUI writing
                    [~,Tend] = PG.params{ct,PG.tabcol({'DURA'})}.get_sweep_min_max();
                    %Digitize function (convert first in GHz then back MHz)
                    RASTs(end+1) = 1e3*digitization(text,LMS_conv_error,maxRAST*1e-3,Tend);
                end       
            end
        end
        
        %Check also start time and period (NO GOOD FOR LOG!)
        star_data = PG.params{ct,PG.tabcol({'STAR'})}.param; %ns!
        [min_star,~] = PG.params{ct,PG.tabcol({'STAR'})}.get_sweep_min_max();
        if(min_star ~= 0)
            RASTs(end+1) = 1/(min_star*1e-3);
        end
        if(star_data{1} ~= 1 && star_data{3} ~= 0 && star_data{4} == 1) %for sweep
            RASTs(end+1) = 1/(star_data{3}*1e-3);
        end
        
        dura_data = PG.params{ct,PG.tabcol({'DURA'})}.param; %
        if(dura_data{1} ~= 1 && dura_data{3} ~= 0 && dura_data{4} == 1) %for sweep
            RASTs(end+1) = 1/(dura_data{3}*1e-3);
        end
        
        peri_data = PG.params{ct,PG.tabcol({'PERI'})}.param;
        [min_peri,~] = PG.params{ct,PG.tabcol({'PERI'})}.get_sweep_min_max();
        if(min_peri ~= 0)
            RASTs(end+1) = 1/(min_peri*1e-3);
        end
        if(peri_data{1} ~= 1 && peri_data{3} ~= 0 && peri_data{4} == 1) %for sweep
            RASTs(end+1) = 1/(peri_data{3}*1e-3);
        end
    end
    
    %Find optimal RAST out of all RASTs
    RASTs = RASTs(RASTs~=0);
    if(isempty(RASTs))
        cLOG.update('ERROR: CANNOT FIND SAMP. FREQ.',0);
        RAST = [];
        return;
    end
    
    %Optimal = least common multiple
    RASTs = abs(RASTs);
%     RAST = RASTs(1);
%     for ct = 2:length(RASTs)
%         RAST = LCMrat(RAST,RASTs(ct));
%     end    
    RAST = max(RASTs(:));
    
    discMult = 10;
    RAST = max(discMult*RAST,AWG.min_RAST);
    
    %Check RAST
    if(RAST > maxRAST)
        RAST = maxRAST;
        cLOG.update('WARNING: SAMP. FREQ. CLIPPED, MIGHT NOT BE OPTIMAL',0);
        cLOG.warnings = cLOG.warnings + 1;
    end
end

%Function to create shape from pulse parameters
%varargin = value or string for arb fun
function [shapeOut,time_vals,rndVal_flag] = make_shape(EXP,shape_data,...
                                                       params,channel,rndVal_flag)
    global cLOG;    
    
    %Conversion to SI unit then RAST unit
    RAST = EXP.RAST*1e6; %MHZ -> Hz
    
    %Put Warning if some values will be rounded
    %Some value will be rounded (1e9/1e9 is just to make sure the check is
    %not screwed by some numerical errors
    if(any(round(params([4 5 6])*1e-9*RAST) ~= round(params([4 5 6])*RAST)*1e-9))
       rndVal_flag = rndVal_flag + 1;
%        cLOG.warnings = cLOG.warnings + 1; %Rounded timings are pretty
%        common and not very problematic, no need to keep the compiler
%        window open because of it.
    end  
    
    %Convert to RAST
    frequency = params(1)*1e6/RAST; %MHZ -> Hz
    phase = pi/180*params(2); %Deg
    amplitude = params(3); %A.U.
    start = round(params(4)*1e-9*RAST); %ns -> s
    duration = round(params(5)*1e-9*RAST); %ns -> s
    period = round(params(6)*1e-9*RAST); %ns -> s 
    period_nb = params(7);
    
    if(isempty(shape_data)) %Square pulse    
        if(frequency ~= 0)
            shape_rep = duration*frequency; %May not be integer
            RndFreq = 1/round(1/frequency); %1/freq must be integer for period
            if(shape_rep <= 5 || RndFreq ~= frequency) %memory size or non-integer
                phi = 2*pi*frequency*(start+(0:duration-1).');
                shape = amplitude*[cos(phi+phase) sin(phi+phase)];
                shape_rep = 1;
            else                
                phi = 2*pi*(start+(0:frequency:1-frequency).');
                shape = amplitude*[cos(phi+phase) sin(phi+phase)];
                
                %Recalculate shape_rep
                shape_rep = duration/size(shape,1);
            end
        else %square pulse
            shape = amplitude*[cos(phase) sin(phase)];
            shape_rep = duration;
        end

    elseif(ischar(shape_data{2})) %String function        
        pulse_fun = @(t) eval(shape_data{2});
        time = start+(0:duration-1).';
        
        if(~isempty(time))
            pulse = pulse_fun(time/(RAST*1e-9)); %fun not in RAST unit, back to ns
        
            %Modulation
            if(~(frequency == 0 && phase == 0))
                phi = 2*pi*frequency*time;
                if(size(pulse,2) == 1)
                    IQ = hilbert(pulse);
                    pulse = [real(IQ) imag(IQ)];
                end
                pulse = [pulse(:,1).*cos(phi+phase) - pulse(:,2).*sin(phi+phase) ...
                         pulse(:,2).*cos(phi+phase) + pulse(:,1).*sin(phi+phase)];
            end

            if(size(pulse,2) == 1)
                IQ = hilbert(pulse);
                shape = [real(IQ) imag(IQ)];
            else
                shape = [pulse(:,1) pulse(:,2)];
            end
            shape = amplitude*shape/max(abs(shape(:)));
            shape_rep = 1;
        else
            shape =  zeros(0,2);
            shape_rep = 1;
        end

    else %Value (vector) pulse
        %Interpolate value to RAST
        shape_data{2}(:,1) = shape_data{2}(:,1)*1e-9; %ns -> s
        dt = shape_data{2}(2,1) - shape_data{2}(1,1);
        if(RAST ~= 1/dt) %data not necessarily in RAST unit
            time = (round(shape_data{2}(1,1)*RAST):round(shape_data{2}(end,1)*RAST)).'/RAST;
            pulse = interp1(shape_data{2}(:,1),shape_data{2}(:,2:end),time,'pchip');
            
            cLOG.update(['WARNING: ' shape_data{1} ' WAS INTERPOLATED'],0);
            cLOG.warnings = cLOG.warnings + 1;
        else
            pulse = shape_data{2}(:,2:end);
        end
        duration = size(pulse,1);
        
        %Modulation
        if(~(frequency == 0 && phase == 0))
            phi = 2*pi*frequency*(start+(0:duration-1).');
            if(size(pulse,2) == 1)
                IQ = hilbert(pulse);
                pulse = [real(IQ) imag(IQ)];
            end
            pulse = [pulse(:,1).*cos(phi+phase) - pulse(:,2).*sin(phi+phase) ...
                          pulse(:,2).*cos(phi+phase) + pulse(:,1).*sin(phi+phase)];
        end
        
        if(size(pulse,2) == 1)
            IQ = hilbert(pulse);
            shape = [real(IQ) imag(IQ)];
        else
            shape = [pulse(:,1) pulse(:,2)];
        end
        shape = amplitude*shape/max(abs(shape(:)));
        shape_rep = 1;
    end
    
    %We cant have both period and shape_rep together (loop within loop)
    if(shape_rep > 1 && period_nb > 1)
        %Remove shape rep -> full shape
        shape = concPerShape(shape,shape_rep);
        shape_rep = 1;
    end
    
    %There's no point in keeping shape_rep or periodicity if the total
    %length is too short compared to a few times gridMin (AWG).
    %I chose 5xgridMin here otherwise pulse get splitted in 3xgridMin. It is a
    %compromise between memory and number of segment
    tot_length = duration + (period_nb-1)*period;
    if(tot_length < 5*EXP.gridMin)
        %Remove shape rep
        if(shape_rep > 1)
            shape = concPerShape(shape,shape_rep);
            shape_rep = 1;
        end
        
        %Remove periodicity
        if(period_nb > 1)
            new_shape = zeros(tot_length,2);
            for ct = 1:period_nb
                new_shape((ct-1)*period + (1:size(shape,1)),:) = shape;
            end
            shape = new_shape;
            period = 0;
            period_nb = 1;
            duration = tot_length;
        end
    end
    
    %Create pulse
    shapeOut = ShapeClass(shape,shape_rep,channel,0);
    
    %Output modified timings
    time_vals(1) = start;
    time_vals(2) = duration;
    time_vals(3) = period; 
    time_vals(4) = period_nb;
end
        
%Function to combine 2 shapes for one specific start value of each pulse
function [shapeOut,startOut] = combine_shapes(shape1,start1,shape2,start2)
    global cLOG;
    max_AMP = 1; %Should be taken from PGClass!

    %Channel
    if(~strcmp(shape1.channel,shape2.channel))
        channel = [shape1.channel '-' shape2.channel];
    else
        channel = shape1.channel;
    end
    
    %Can't keep anymore periodic shape
    new_shape1 = concPerShape(shape1.shape,shape1.shape_rep);
    new_shape2 = concPerShape(shape2.shape,shape2.shape_rep);
    
    if(numel(shape1.markers) ~= 1)
        new_marker1 = concPerShape(shape1.markers,shape1.shape_rep);
    else
        new_marker1 = shape1.markers;
    end   
    if(numel(shape2.markers) ~= 1)
        new_marker2 = concPerShape(shape2.markers,shape2.shape_rep);
    else
        new_marker2 = shape2.markers;
    end    

    %Summing pulses
    startOut = min(start1,start2);
    start1 = start1 - startOut;
    start2 = start2 - startOut;

    L1 = size(new_shape1,1);
    L2 = size(new_shape2,1);

    shapeOut = zeros(max(start1+L1,start2+L2),2);
    shapeOut(start1+(1:L1),:) = new_shape1;
    shapeOut(start2+(1:L2),:) = shapeOut(start2+(1:L2),:) + new_shape2;
    if(max(abs(shapeOut(:))) > 1)
        cLOG.update(['WARNING: one combined amplitude was found '...
                    'to be > 1 and was clipped.'],0);
        shapeOut = max(-max_AMP,min(max_AMP,shapeOut));
        cLOG.warnings = cLOG.warnings + 1;
    end
    
    %Summing markers
    markers = zeros(size(shapeOut,1),4);
    markers(start1+(1:L1),:) = new_marker1; 
    markers(start2+(1:L2),:) = markers(start2+(1:L2),:) | new_marker2;
    
    %Return a ShapeClass (NO NEED JUST MAKE A STRUCTURE)
    shapeOut = ShapeClass(shapeOut,1,channel,markers);
end

%Fast shape concatenation when needing to include shaperep
function shape = concPerShape(shape,shapeRep)
    L = size(shape,1);
    duration = round(shapeRep*L);
    idx = 0:(duration-1);
    idx = idx - fix(idx/L)*L+1;
    shape = shape(idx,:);
    
%     %Slow version
%     duration = round(shapeRep*size(shape,1));
%     shape = repmat(shape.',[1 1 ceil(shapeRep)]);
%     shape = shape(:,:).';
%     shape = shape(1:duration,:);
end
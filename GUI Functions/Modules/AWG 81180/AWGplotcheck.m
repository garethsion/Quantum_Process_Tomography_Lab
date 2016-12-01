function AWGplotcheck(AWG,ctPlot)
%Call this function to check what the pulses that are sent look like
%ctPlot corresponds to a specific X,Y,Z
%Input: a number for which x,y,z or 'all' to get a video of all x,y,z

if(strcmp(ctPlot,'all'))
    for ctL = 1:length(AWG.data_segm_load)
        segm = AWG.data_segm_load{ctL};
        sequ = AWG.data_sequ_load{ctL};

        unique_seq = unique(sequ(:,1));
        for ctP = 1:length(unique_seq)
            cur_sequ = sequ(sequ(:,1) == unique_seq(ctP),:);
            if(~isempty(sequ))
                data2plot(AWG,cur_sequ,segm);
            end
        end
    end
    
    figure(10);
    close(gcf);    
else
    load_idx = 1; %just look at first load

    segm = AWG.data_segm_load{load_idx};
    sequ = AWG.data_sequ_load{load_idx};

    sequ = sequ(sequ(:,1) == ctPlot,:);
    if(~isempty(sequ))
        data2plot(AWG,sequ,segm);
    end
end

end

function data2plot(AWG,sequ,segm)
%     pause(0.5);
    figure(10)
    clf(10)
    
    yShape = [];
    yMarkers = [];

    for ct = 1:size(sequ,1)
        cur_idx = segm(sequ(ct,2));
        shape = AWG.data_shapes{cur_idx};
        markers = AWG.data_markers{cur_idx};
        
        if(size(shape,1)*sequ(ct,3) > 1e9)
            error('Sequence is too long. Will take too much memory/time to plot.');
        end
        
        if(sequ(ct,3) > 1)
            new_shape = repmat(shape.',1,1,sequ(ct,3));
            new_shape = new_shape(:,:).';
            
            new_markers = repmat(markers.',1,1,sequ(ct,3));
            new_markers = new_markers(:,:).';
        else
            new_shape = shape;
            new_markers = markers;
        end
        
        if(size(yShape,1) > 1e9)
            error('Sequence is too long. Will take too much memory/time to plot.');
        end
        
        yShape = [yShape; new_shape];
        yMarkers = [yMarkers; new_markers];
    end
    yMarkers = [yMarkers(25:end,:); zeros(24,4)]; %marker are all shifted
    
    time = 1/AWG.RAST*(0:size(yShape,1)-1);
    plot(time,[yShape yMarkers]);
    xlabel('Time (\mus)');
    legend('I','Q','Acq','TWT','RF','User','Location','Best');
    axis tight
end


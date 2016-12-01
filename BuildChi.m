function BuildChi = BuildChi(file)
    %load(file{1})
    load(file)
    % Convert Data
    [Xaxis,Yaxis,signal] = ConvertData(MAIN);

    dataI = full_data.data{1};
    dataQ = full_data.data{2};
    xdata = Xaxis{1,3};

    % Uncomment this is you want to view the averaged scope data
    Scope_Plotter(xdata, dataI, dataQ);

    % Acquire Average IQ Data
    Mean_IData = mean(dataI,4);
    Mean_QData = -mean(dataQ,4);

    % Remove sngleton dimensions by squeezing data into a column matrix
    Squeezed_IData = squeeze(Mean_IData);
    Squeezed_QData = squeeze(Mean_QData);

    % Determine integration block start and stop times through physical 
    % inspection of the acquired waveform
    Start_X1 = 1.556*10^-6;
    End_X1 = 4.107*10^-5;
    Start_X2 = 1.0004*10^-4;
    End_X2 = 1.199*10^-4;

    % Segment the xdata into individual chunks 
    [value, Start_index1] = min(abs(xdata-Start_X1));
    [value, End_index1] = min(abs(xdata-End_X1));
    
    [value, Start_index2] = min(abs(xdata-Start_X2));
    [value, End_index2] = min(abs(xdata-End_X2));

    % Seperate I and Q data and respective blocks
    First_ISegment = Squeezed_IData(Start_index1:End_index1,:);
    First_QSegment = Squeezed_QData(Start_index1:End_index1,:);
    Second_ISegment = Squeezed_IData(Start_index2:End_index2,:);
    Second_QSegment = Squeezed_QData(Start_index2:End_index2,:);

    % Remove the baseline by translating the axis to the origin
    First_ISegment = First_ISegment - First_ISegment(1);
    First_QSegment = First_QSegment - First_QSegment(1);
    Second_ISegment = Second_ISegment - Second_ISegment(1);
    Second_QSegment = Second_QSegment - Second_QSegment(1);
    
    % The X, Y and Z data are stored in the IQ data. X is stored in the I data 
    % of the first segment, Y is in the Q data in the first segment, and Z is
    % in the Q data of the second segment
    X_Data = First_ISegment;
    Y_Data = First_QSegment;
    Z_Data = Second_QSegment;
    
    % Acquire Density Matrices. This pulls out the data in a particular phase
    % Cycle - ZPlus_Pure = col_1, ZPlus_Process = col_2, ZMinus_Pure = col_3, 
    % ZMinus_Process = col_4, X_Pure = col_5, X_Process = col_6, 
    % Y_Pure = col_7, Y_Process = col_8
    rho0 = Density(X_Data(:,1), Y_Data(:,1), Z_Data(:,1),...
        X_Data(:,2), Y_Data(:,2), Z_Data(:,2));

    rho1 = Density(X_Data(:,3), Y_Data(:,3), Z_Data(:,3),...
        X_Data(:,4), Y_Data(:,4), Z_Data(:,4));

    rhoX = Density(X_Data(:,5), Y_Data(:,5), Z_Data(:,5),...
        X_Data(:,6), Y_Data(:,6), Z_Data(:,6));
    
    rhoY = Density(X_Data(:,7), Y_Data(:,7), Z_Data(:,7),...
        X_Data(:,8), Y_Data(:,8), Z_Data(:,8));

    % Generate an error message warning if the density matrices are not
    % composed correctly
    if (trace(rho0)~=1 || trace(rho1)~=1 || trace(rhoX)~=1 || trace(rhoY)~=1)
        msg = 'The trace of one of the density matrices does not equal unity';
        error(msg)
    end
    
    % Generate Process Matrix and plot data
    BuildChi = Chi(rho0, rho1, rhoX, rhoY);
    if (trace(Process_Matrix)~=1)
        msg = 'The trace of the process matrix does not equal unity';
        error(msg)
    end
end 
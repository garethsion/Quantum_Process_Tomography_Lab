%SiDonor simulator GUI module
function SiDsimGUI(SiDsim)
%% Module definition (template)

%Required function handles
% AWG.window_resize = @window_resize;
% AWG.metadataEdit = @metadataEdit;
% AWG.sweepControlsEdit = @sweepControlsEdit;

%% COMPUTE SIMULATION
[textPos,~] = ModuleUICPos(0.3,1);
SiDsim.hCompute = SiDsim.ModuleUIC('push','Simulate',textPos,...
            'Callback',@SiDsim.compute,'BackgroundColor','green');      

%% MAIN PARAMETERS
SiDsim.UI_add_subpanel('Main parameters',0.79,0.13);

%FIELD: DONOR TYPE
[textPos, inputPos] = ModuleUICPos(2,1);
SiDsim.ModuleUIC('text','Donor:',textPos);
SiDsim.hDonor = SiDsim.ModuleUIC('popup',SiDsim.donors,inputPos,'Value',1);
      
%FIELD: EXPERIMENT FREQUENCY
[textPos, inputPos] = ModuleUICPos(2,2);
SiDsim.ModuleUIC('text','Frequency (GHz):',textPos);
SiDsim.hFreq = SiDsim.ModuleUIC('edit','9.7',inputPos);
 
%Get frequency from VSG setting      
[~, inputPos] = ModuleUICPos(2,2.3);  
SiDsim.ModuleUIC('push','Get',inputPos,'callback',@SiDsim.get_freq_from_VSG);
      
%FIELD: MAGNETIC FIELD CALIBRATION
[textPos, inputPos] = ModuleUICPos(2,3.6);
SiDsim.ModuleUIC('text','Calibration:',textPos);
SiDsim.hCal = SiDsim.ModuleUIC('popup',{'None' 'X' 'EMX'},inputPos,'Value',1);     
      
%% SIMULATION TABLE RESULTS
SiDsim.UI_add_subpanel('Simulation',0.25,0.54);

%Main figure dimensions
borders = 0.02;
fig_dim = get(SiDsim.MAIN.hWIN,'Position');
fig_width = fig_dim(3);
    
%Table dimensions
tab_width = 0.7;
tab_height = 0.45;
tab_Y = 0.26;
SiDsim.hTABLE = uitable('Parent',SiDsim.hPanel,'Visible','on','Units','normalized','FontUnits','Normalized',...
            'Position',[0.5-tab_width/2,tab_Y+borders,tab_width,tab_height]);

set(SiDsim.hTABLE, 'ColumnName', {'Field (mT)', 'Transition', 'df/dB (ga_e)', 'df/dA'});
col_width = get(0,'ScreenSize');
col_width = col_width(3)*fig_width*tab_width/(4+0.2);
set(SiDsim.hTABLE, 'ColumnWidth', {col_width});
set(SiDsim.hTABLE, 'RowName', '');

set(SiDsim.hTABLE, 'ColumnEditable', [false false false false]);
set(SiDsim.hTABLE, 'ColumnFormat', {[] [] [] []});
set(SiDsim.hTABLE, 'Data', {'0' '0' '0' '0'});

% set(SiDsim.hTABLE, 'CellSelectionCallback', {@tableCellSelected}); %Cell selection update
  
%% DECAYS (T1...)
SiDsim.UI_add_subpanel('Decay times',0.005,0.24);

%FIELD: TEMPERATURE
[textPos, inputPos] = ModuleUICPos(14.3,1);
SiDsim.ModuleUIC('text','Temperature (K):',textPos);
SiDsim.hTemp = SiDsim.ModuleUIC('edit','0',inputPos,'Callback',@SiDsim.compute_T1);

%FIELD: T1
[textPos, inputPos] = ModuleUICPos(14.3,2);
SiDsim.ModuleUIC('text','T1 (s):',textPos);
SiDsim.hT1 = SiDsim.ModuleUIC('edit','9.7',inputPos,'enable','off');
 
end
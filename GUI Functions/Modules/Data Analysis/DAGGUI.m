%DAG GUI module
function DAGGUI(DAG)
%% Module definition

%% PLOT
hpp = DAG.UI_add_subpanel('Plot',[0.405 0.22 0.59 0.75]);

Xaxis = 0;
signal = 0;
DAG.hPLOT = plot(Xaxis,signal);
DAG.hPLOTaxis = gca;
set(DAG.hPLOTaxis,'Parent',hpp,'Units','normalized','FontUnits','Normalized',...
    'Position',[0.12 0.13 0.87 0.8],...
    'FontSize',0.06,'YTickLabel',[],'XTickLabel',[]);
set(DAG.hPLOTaxis,'UserData',{0}); %no normalization
    
%% FILE SAVE/LOAD
DAG.UI_add_subpanel('Save/Load',[0.005 0.62 0.395 0.35]);
     
%FIELD: Loaded files
DAG.hFileList = DAG.ModuleUIC('listbox','',[0.015 0.84 0.2 0.1],...
                'Min',1,'Max',3,'FontWeight','Bold','ForegroundColor','Blue');    
         
%FIELD: add files
DAG.ModuleUIC('push','+',[0.22 0.89 0.05 0.05],'Callback',@DAG.addfile);

%FIELD: remove files
DAG.ModuleUIC('push','-',[0.22 0.84 0.05 0.05],'Callback',@DAG.deletefile);
         
%FIELD: save plot
DAG.ModuleUIC('push','Save plot',[0.29 0.84 0.1 0.1],'Callback',@DAG.saveplot);        
    
%FIELD: choose current file to manipulate
DAG.hCurFile = DAG.ModuleUIC('popup',{''},[0.015 0.735 0.375 0.05],...
                'ForegroundColor','Blue','Callback',@DAG.fileselect);    

%FIELD: SIGNAL            
DAG.ModuleUIC('Text','Signal:',[0.015 0.68 0.09 0.05],'FontWeight','Bold');          
DAG.hPlotCtrl(1) = DAG.ModuleUIC('popup',{''},[0.015 0.64 0.09 0.05],...
    'Callback',@DAG.fileplotUpdate,'FontWeight','Bold','ForegroundColor','Blue');  

%FIELD: X AXIS            
DAG.ModuleUIC('Text','X axis:',[0.125 0.68 0.09 0.05],'FontWeight','Bold');          
DAG.hPlotCtrl(2) = DAG.ModuleUIC('popup',{''},[0.125 0.64 0.09 0.05],...
                'Callback',@DAG.fileplotUpdate,'FontWeight','Bold','ForegroundColor','Blue');    

%FIELD: Y AXIS
DAG.ModuleUIC('Text','Y axis:',[0.235 0.68 0.09 0.05],'FontWeight','Bold');          
DAG.hPlotCtrl(3) = DAG.ModuleUIC('popup',{''},[0.235 0.64 0.09 0.05],...
    'Callback',@DAG.fileplotUpdate,'FontWeight','Bold','ForegroundColor','Blue');

%FIELD: ADD PLOT
DAG.ModuleUIC('push','+',[0.34 0.64 0.05 0.05],...
                    'ForegroundColor','Blue','Callback',@DAG.addplot);

%% PLOT CONTROLS
DAG.UI_add_subpanel('Plot controls',[0.005 0.22 0.395 0.4]);

%FIELD: choose plot to manipulate
DAG.hPlotList = DAG.ModuleUIC('popup',{''},[0.015 0.53 0.31 0.05],...
                'ForegroundColor','Blue','Callback',@DAG.plotselect);    
    
%FIELD: remove plot
DAG.ModuleUIC('push','-',[0.34 0.53 0.05 0.05],'ForegroundColor','Blue','Callback',@DAG.removeplot);

%FIELD: normalize all
DAG.ModuleUIC('Text','Normalize all:',[0.01 0.46 0.08 0.05]);          
DAG.ModuleUIC('checkbox','',[0.09 0.47 0.05 0.05],'Callback',@DAG.normalizeplots);

%% FITTING
DAG.UI_add_subpanel('Fitting',[0.005 0.01 0.99 0.21]);

%FIT FUNCTION
DAG.hFIT(1) = DAG.ModuleUIC('edit','Fitting function',[0.1 0.14 0.8 0.05],...
    'Callback',@DAG.fitting);

%FIT VARIABLES
DAG.hFIT(2) = DAG.ModuleUIC('edit','Initial values',[0.1 0.08 0.8 0.05],...
    'Callback',@DAG.fitting); 

%RESULTS VARIABLES
DAG.hFIT(3) = DAG.ModuleUIC('edit','Result',[0.1 0.02 0.8 0.05],'Enable','off'); 

end

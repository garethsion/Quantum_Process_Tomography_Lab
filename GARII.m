%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% General ARbitrary Instrument Interface %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Written by Gary Wolfowicz, QSD group, 2013-2015
%
function GARII(varargin)
%% Add important paths
root_path = mfilename('fullpath');
root_path = root_path(1:end-5);
addpath([root_path '.']);
addpath(genpath([root_path 'GUI functions']));
addpath(genpath([root_path 'Library']));

%% Create MAIN (contain all data)
global MAIN; %All parameters/data
MAIN = MainClass();
MAIN.root_path = root_path;

%% Launch program
%Parameter window
ParamGUI(MAIN,varargin);

%Measurement window
MeasureGUI(MAIN);

end

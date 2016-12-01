function [densMat, errors] = RunExperiment(exp_number)
global MAIN;
errors = 'None';

%% Sequences
%Loading and saving folder/file path
load_folder = 'C:\Users\Gary Wolfowicz\Desktop\Simulations Bismuth\GIC\RemoteApp\';

switch(exp_number)
    case '-1'
        densMat = convertResultsToXml(zeros(2));
        return;
        
    case '-2'
        densMat = convertResultsToXml(ones(2)*(1+1i));
        return;
    
    %X rotation
    case '0' %X - Slider 1
        seq = [load_folder '1-X.mat'];
    case '1' %X - Slider 2
        seq = [load_folder '2-X.mat'];
    case '2' %X - Slider 3
        seq = [load_folder '3-X.mat'];
    case '3' %X - Slider 4
        seq = [load_folder '4-X.mat'];
    case '4' %X - Slider 5
        seq = [load_folder '5-X.mat'];
        
    %Y rotation
    case '5' %Y - Slider 1
        seq = [load_folder '1-Y.mat'];
    case '6' %Y - Slider 2
        seq = [load_folder '2-Y.mat'];
    case '7' %Y - Slider 3
        seq = [load_folder '3-Y.mat'];
    case '8' %Y - Slider 4
        seq = [load_folder '4-Y.mat'];
    case '9' %Y - Slider 5
        seq = [load_folder '5-Y.mat'];
        
    %Z rotation
    case '10' %Z - Slider 1
        seq = [load_folder '1-Z.mat'];
    case '11' %Z - Slider 2
        seq = [load_folder '2-Z.mat'];
    case '12' %Z - Slider 3
        seq = [load_folder '3-Z.mat'];
    case '13' %Z - Slider 4
        seq = [load_folder '4-Z.mat'];
    case '14' %Z - Slider 5
        seq = [load_folder '5-Z.mat'];
        
    %I rotation
    case '15' %I - Slider 1
        seq = [load_folder '1-I.mat'];
    case '16' %I - Slider 2
        seq = [load_folder '2-I.mat'];
    case '17' %I - Slider 3
        seq = [load_folder '3-I.mat'];
    case '18' %I - Slider 4
        seq = [load_folder '4-I.mat'];
    case '19' %I - Slider 5
        seq = [load_folder '5-I.mat'];
        
    otherwise
        densMat = convertResultsToXml(zeros(2));
        return;
end

%% Load experiments and run
baseidx = 380;
XYidx = 380:450; %2000pts on oscilloscope
Zidx = 900:970;

%Experiment
MAIN.loadAll([],[],seq); %Load experiment parameters
MAIN.SPP = 4;
[INST,MSRE] = MAIN.setup_all(); %Setup instruments to run experiment
if(isempty(INST) && isempty(MSRE))
    densMat = convertResultsToXml(zeros(2));
    return;
end
MAIN.run_experiment(INST,MSRE); %Run the experiment

%Data
Yreal = MAIN.get_mod('MSO').measures{1}.data;
Yimag = MAIN.get_mod('MSO').measures{2}.data;

%Integrate
Xobs = sum(Yreal(XYidx)-Yreal(baseidx));
Yobs = sum(Yimag(XYidx)-Yimag(baseidx));
Zobs = sum(Yreal(Zidx)-Yreal(baseidx));    

%% Treat data
densMat = QST([Xobs Yobs Zobs],[Xobs Yobs Zobs]);
densMat = densMat{1};
plotTomo(densMat)
densMat = convertResultsToXml(densMat);
end

function xml = convertResultsToXml(results)
    %xTemplate = '<output1>%.2f %+.2fi</output1><output2>%.2f %+.2fi</output2><output3>%.2f %+.2fi</output3><output4>%.2f %+.2fi</output4>';
    xTemplate = '<output1>%.2f + %.2fi</output1><output2>%.2f + %.2fi</output2><output3>%.2f + %.2fi</output3><output4>%.2f + %.2fi</output4>';
    xml = sprintf(xTemplate, real(results(1,1)), imag(results(1,1)), real(results(2,1)), imag(results(2,1)), real(results(1,2)), imag(results(1,2)), real(results(2,2)), imag(results(2,2)));
end
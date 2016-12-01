%Auto Pulse Sequencer GUI module
function APSGUI(APS)
%% Module definition


%% Send created table to PulseCreator
[textPos,~] = ModuleUICPos(0.3,1);
APS.ModuleUIC('push','Create/Send to table',textPos,'Callback',@APS.compute,...
                            'BackgroundColor','green');      

%% MAIN PARAMETERS
APS.UI_add_subpanel('Main parameters (echo measurement)',0.76,0.16);

%PI/2
%Shape
[textPos, inputPos] = ModuleUICPos(2,1);
APS.ModuleUIC('text','Pi/2 pulse shape:',textPos);
APS.ModuleUIC('popup',{'Square'},inputPos,'Value',1);

%Length
[textPos, inputPos] = ModuleUICPos(2,1.9);
APS.ModuleUIC('text','Pi/2 pulse length (ns):',textPos);
APS.ModuleUIC('edit',500,inputPos);

%Pi
%Shape
[textPos, inputPos] = ModuleUICPos(2,3);
APS.ModuleUIC('text','Pi pulse shape:',textPos);
APS.ModuleUIC('popup',{'Square'},inputPos,'Value',1);

%Length
[textPos, inputPos] = ModuleUICPos(2,3.9);
APS.ModuleUIC('text','Pi pulse length (ns):',textPos);
APS.ModuleUIC('edit',1000,inputPos);

%Interpulse duration
[textPos, inputPos] = ModuleUICPos(3,1.9);
APS.ModuleUIC('text','Interpulse duration (ns):',textPos);
APS.ModuleUIC('edit',20000,inputPos);

%Acquisition time
[textPos, inputPos] = ModuleUICPos(3,3);
APS.ModuleUIC('text','Acquisition time (ns):',textPos);
APS.ModuleUIC('edit',30000,inputPos);

%% SEQUENCE
APS.UI_add_subpanel(' ',0.40,0.36);

[textPos,~] = ModuleUICPos(4,1);
sequenceList = getSequenceList();
if(isempty(sequenceList))
    sequenceList = {''};
end
APS.ModuleUIC('popup',sequenceList,textPos,'Value',1,...
                            'ForegroundColor','Blue','FontWeight','Bold');
 
end

%Find sequences from library folder
%They need to start with the initials "APS"
function sequenceList = getSequenceList()
    files = dir(['.' filesep 'GUI functions' filesep 'Modules' ...
                          filesep 'Auto Pulse Sequencer' filesep 'Library']);
    files = files(3:end);
    
    sequenceList = {};
    for ct = 1:length(files)
        if(strcmp(files(ct).name(1:3),'APS'))
            [~,name,~] = fileparts(files(ct).name);
            sequenceList{end+1} = name(4:end); %#ok<AGROW>
        end
    end
end
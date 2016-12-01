function [Xaxis,Yaxis,signal] = ConvertData(MAIN)
%[Xaxis,Yaxis,signal] = ConvertData(MAIN)

signal = {};
Xaxis = {};
Yaxis = {};
for ctMOD = 1:length(MAIN.mods)
    if(isempty(MAIN.mods{ctMOD}.description))
        ID = MAIN.mods{ctMOD}.name;
    else
        ID = [MAIN.mods{ctMOD}.name '-' MAIN.mods{ctMOD}.description];
    end

    measures = MAIN.mods{ctMOD}.measures;
    for ctMSRE = 1:numel(measures)
        if(isa(measures{ctMSRE},'MeasureClass'))
            if(measures{ctMSRE}.state)
                try
                signal(end+1,:) = {ID ... %Module name
                                           measures{ctMSRE}.label ... %Channel label
                                           measures{ctMSRE}.data}; %#ok<AGROW> % Values
                 if(MAIN.transient)
                    Xaxis(end+1,:) = {ID ... %Module name
                                               measures{ctMSRE}.transient_axis.label ... %Channel label
                                               measures{ctMSRE}.transient_axis.vals}; %#ok<AGROW> % Values
                 end
                catch
                     continue
                end
            end
        end
    end

    params = MAIN.mods{ctMOD}.params;
    for ctPAR = 1:numel(params)
        if(isa(params{ctPAR},'ParameterClass'))
            if(params{ctPAR}.param{1} == 2 && MAIN.XPTS > 1)
                Xaxis(end+1,:) = {ID ... %Module name
                                           params{ctPAR}.label ... %Parameter name
                                           params{ctPAR}.vals}; %#ok<AGROW> %Values
            elseif(params{ctPAR}.param{1} == 3 && MAIN.YPTS > 1)
                Yaxis(end+1,:) = {ID ... %Module name
                                           params{ctPAR}.label ... %Parameter name
                                           params{ctPAR}.vals}; %#ok<AGROW> %Values
            end
        end
    end
end

if(MAIN.XPTS > 1 && isempty(Xaxis))
    Xaxis = {'' 'Point' (1:MAIN.XPTS).'};
end
if(MAIN.YPTS > 1 && isempty(Yaxis))
    Yaxis = {'' 'Point' (1:MAIN.YPTS).'};
end

end
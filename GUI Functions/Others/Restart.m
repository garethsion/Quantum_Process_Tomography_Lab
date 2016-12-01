function Restart(varargin)

%Load latest temporary file
if(~isempty(varargin))
    filename = varargin{1};
else
    filename = ['.' filesep 'Temp' filesep '010_temp.mat'];
end
temp = load(filename);

%Load modules
if(length(temp.MAIN.mods_name) == length(temp.MAIN.mods) && ...
    isempty(temp.MAIN.mods_ID))  %Older version loading

    mods = temp.MAIN.mods_name(~strcmp(temp.MAIN.mods_name,'PG'));%PG is loaded with AWG
else
    mods2load = {};
    for ct = 1:length(temp.MAIN.mods)
        if(isempty(temp.MAIN.mods{ct}.parent_mod))
            mods2load{end+1} = temp.MAIN.ID2name(temp.MAIN.mods_ID{ct}); %#ok<AGROW>
        end
    end
end

GARII(mods2load{:});

%Load file
global MAIN;
MAIN.loadAll([],[],filename);

end


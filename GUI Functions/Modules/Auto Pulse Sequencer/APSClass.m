classdef APSClass < ModuleClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%% APSClass is a GARII Module %%%%%%%%
    %%%%%%%%%%% Auto Pulse Sequencer %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    %Main methods
    methods (Access = public)
        function obj = APSClass()
            obj.name = 'Auto Pulse Sequencer';
        end
        
        %% EXPERIMENT FUNCTIONS (NOT USED FOR THIS MODULE)
        %Setup the experiment
        function ok_flag = experiment_setup(~,~)
            ok_flag = -1;
        end
        
        %During experiment
        function ok_flag = experiment_next(~)
            ok_flag = -1;
        end
        
        %End of experiment
        function ok_flag = experiment_stop(~)
            ok_flag = -1;
        end
        
    end
    
    %GUI methods
    methods (Access = public)
        %Do computation
        function compute(obj,~,~)
            if(isempty(obj.MAIN.get_mod('PG')))
                msgbox('Sequence creation requires Pulse Creator module.');
                return;
            end
        end
    end
end


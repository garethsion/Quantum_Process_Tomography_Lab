classdef KEI2400Class < KEIClass
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% KEI2400 is a GARII Module %%%%%%%%%%%%%%
    %%%%%%%%% Implementation of Keithley 2400  %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = public)
        
        function obj = KEI2400Class()
            obj = obj@KEIClass(); %Build superclass values
            % Change the name and ID to KEI2400
            obj.name = 'Keithley 2400';
            obj.INST = {{'KEITHLEY INSTRUMENTS INC.,MODEL 2400,1140635,C30   Mar 17 2006 09:29:29/A02  /K/J', 'visa', 'GPIB0::25::INSTR'}}; 
        end
    end
    
end


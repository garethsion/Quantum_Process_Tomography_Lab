classdef GPIBIOwrapper < handle
    
    properties
        devObj
        verbose = 0; %flag to give or not error msg during checks
    end
    
    methods
        function [obj] = GPIBIOwrapper(address,IDN)
            %Connect [board,address,?,timeout,end or indentify,end of string]
            obj.devObj = gpibio(0,address,0,13,1,0);
            obj.devObj.buffersize = 1e6;
            
            %Check IDN
            if(~strcmp(IDN,''))
                replyIDN = obj.ask('*IDN?');
                if(~strcmp(replyIDN,IDN))
                    obj.close();
                    error('Instrument name does not match IDN.');
                    return;
                end
            end
        end
        
        %Clear instrument
        function clear_device(obj)
            temp = obj.devObj;
            temp.ibclr;
            obj.devObj = temp;
        end
        
        %Close GPIBIO connection
        function close(obj)
            obj.clear_device;
            obj.devObj.close;
            delete(obj.devObj);
            obj.devObj = [];
        end
        
        %% Instrument communication
        %Send command without error check (faster)
        function write(obj,message)
            %Send all messages (do not wait between messages)
            if(iscell(message))
                for ct = 1:length(message)
                    obj.devObj.write(message{ct});
                end
            else
                obj.devObj.write(message);
            end             
        end
        
        %Send command with error check (better)
        function xwrite(obj,message)
            %Send all messages (do not wait between messages)
            obj.write(message);
            
            %Check and wait for completion
            obj.check(message);
        end
                
        %Query without error check (faster)
        function [reply] = ask(obj,message)
            %Send query
            reply = obj.devObj.ask(message);
            reply = reply(1:end-1);
        end
        
        %Query with error check (better)
        function [reply] = xask(obj,message)
            %Send query
            reply = obj.ask(message);
            
            %Check and wait for completion
            obj.check(message);
        end
        
        function ok_flag = check(obj,varargin)
            ok_flag = 1;
            if(isempty(varargin))
                varargin{1} = '';
            end
            
            % Read back the error queue on the instrument
            instrumentError = lower(obj.ask(':SYSTEM:ERR?'));
            while(isempty(strfind(instrumentError,'no error')))
                ok_flag = 0;
                disp(['Instrument Error (@' varargin{1} '): ' instrumentError]);
                try
                    instrumentError = lower(obj.ask(':SYSTEM:ERR?'));
                catch
                    obj.close();
                    disp('Error: forced close');
                    return;
                end
            end            
            
            %Wait till complete
            obj.wait_till_complete();
        end    
        
        function wait_till_complete(obj)
            %ADD A TIMEOUT!
            
            operationComplete = obj.ask('*OPC?');
            while ~operationComplete
                operationComplete = obj.ask('*OPC?');
            end
        end
        
    end
end

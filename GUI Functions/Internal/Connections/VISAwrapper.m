classdef VISAwrapper < handle
    %Wrapper class for VISA connection
    
    properties
        devObj
    end
    
    methods
        %Wrapper for VISA connection
        function [obj] = VISAwrapper(brand,address,IDN,tag)
            %Find if VISA connection is already open
            obj.devObj = instrfind('Tag', tag);
            
            %Connect
            if(isempty(obj.devObj))
                obj.devObj = visa(brand,address);
                obj.devObj.tag = tag;
            end
            
            %Set the buffer size
            obj.devObj.InputBufferSize = 1e6;
            obj.devObj.OutputBufferSize = 1e6;
            
            %Set the timeout value
            obj.devObj.Timeout = 60.0;
            
            %Set the Byte order
            obj.devObj.ByteOrder = 'littleEndian';
            
            %Open the connection
            try
                fopen(obj.devObj);
            catch
                delete(obj.devObj);
                obj.devObj = [];
                disp('Instrument connection could not be open.');
                return;
            end
            
            %Check IDN
            if(~strcmp(IDN,''))
                replyIDN = obj.ask('*IDN?');
                if(~strcmpi(deblank(replyIDN),IDN))
                    obj.close();
                    disp('Instrument name does not match IDN.');
                    return;
                end
            end
        end
        
        %Close VISA connection
        function close(obj,varargin)
            if(~(~isempty(varargin) && strcmpi(varargin{1},'no clear')))
                obj.clear_device();
            end
            fclose(obj.devObj);
            delete(obj.devObj);
            obj.devObj = [];
        end
        
        %Clear instrument
        function clear_device(obj)
            clrdevice(obj.devObj);
        end
        
        %% Instrument communication
        %Send command without error check (faster)
        function write(obj,message)
            %Send all messages (do not wait between messages)
            if(iscell(message))
                for ct = 1:length(message)
                    fprintf(obj.devObj, message{ct});
                end
            else
                fprintf(obj.devObj, message);
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
            reply = query(obj.devObj,message);
            reply = reply(1:end-1);
        end
        
        %Query with error check (better)
        function [reply] = xask(obj,message)
            %Send query
            reply = obj.ask(message);
            
            %Check and wait for completion
            obj.check(message);
        end
        
        %Error check + wait for completion
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
            operationComplete = obj.ask('*OPC?');
            while ~operationComplete
                pause(0.02);
                operationComplete = obj.ask('*OPC?');
            end
        end
        
        %Send the binary block to the instrument
        function binblockchunkwrite(obj,cmd,bit,block,chunk_size)
        % send the binary block to the instrument object f
        % use chunk_size blocks in the fwrite command
        % cmd: AWG command line
        % bit: 8,16,64 bits...
        % block: data
        % chunk_size: data is sent by chunk
        if(mod(bit,8) ~= 0)
            error('"bit" must be a multiple of 8');
        end
        

        % make a header of the binary block
            len = length(block);
            header = [cmd '#' int2str(length(int2str((bit/8)*len))) int2str((bit/8)*len)];
           
            %Write the header of binary block 
            try
                obj.devObj.EOImode = 'off'; %(???)
            catch
            end
            
            %Define chunk size
            chunk_size = round(chunk_size/(bit/8));
            if len < chunk_size
                chunk_size = len;
            end
            
            %Write a data of binary block
            fwrite(obj.devObj, header);

            for i = 1 : chunk_size : len
                if i+(chunk_size-1) < len
                    n = i+(chunk_size-1);
                else
                    n = len; % remainder of data 
                end

                chunk = block(i:n);
                fwrite(obj.devObj, chunk, ['uint' int2str(bit)]);
            end
            
            try
                obj.devObj.EOImode = 'on';
            catch
            end
        end
        
        %Binary block read from instrument
        %cmd: AWG command line
        %bit: 8,16,64 bits...
        function [rawdata] = blockread(obj,cmd,bit)
            bit = 2^nextpow2(bit); %Force bit to be power of 2 if it isn't
            
            obj.write(cmd);
            rawdata = binblockread(obj.devObj,['uint' int2str(bit)]);
            fread(obj.devObj,1); %Clear query (otherwise give error after check)
        end
    end
end

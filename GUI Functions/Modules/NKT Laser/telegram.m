classdef telegram < handle
    % Telegram Represents data to send to a Koheras Boostik Laser System in a way the laser understands it.
    %   Usage example:
    %       t = telegram(66, 10, hex2dec('34'), true, 1, true);
    %       % Here, we give us (the sender) the address 66 and try to
    %       % communicate with the module that listens to address 10
    %       % We want to write (4th argument = true) 1 to register 34h
    %       % This is the "use wavelength tuning?" register that accepts a
    %       % 8bit unsigned integer therefore we need to set the
    %       % "writeOneByte" flag.
    %       %
    %       % Now open the serial connection to your device
    %       s = serial('COM4', 'BaudRate', 115200);
    %       % and send the telegram
    %       response = t.send(s);
    %       % The response is until now the raw data returned from the
    %       % device that can be ACK, NACK, a datagram or most commonly
    %       % (and most sadly) nothing.
    
    
    properties
        % The address of us as the sender as decimal. The response to this telegram will have this address as destination. The value must be bigger than 64 (40h)
        source;
        % The address of the module the message is intended for. Addresses range from 1 to 48
        destination;
    end
    
    properties(GetAccess = 'public', SetAccess = 'private')
        % A telegram consits of [SOT message EOT] as hex values
        telegrm;
        % The message is [header payload, CRC16] with the header consisting of [destination source type] as hex values
        message;
        
        % The register you want to read or write to/from as decimal
        register;
        
        % Whether to write (true) or read(from the register). This is represented by the Type attribute in the header which is 04 for read and 05 for write
        write = false;
    end
    
    properties(Access = 'private')
        writeOneByte;
        value_msb = 0;
        value_lsb = 0;
    end
    
    properties(Constant)
        start_char = '0D';      %SOT
        terminator_char = '0A'; %EOT
        escape_char = '5E';
        
        escape_start = {'5E' '4D'};
        escape_terminator = {'5E' '4A'};
        escape_escape = {'5E' '9E'};
    end
    
    methods
        function obj = telegram(source, destination, register, write, value, writeOneByte)
            % Telegram Instantiate telegram
            %   Create telegram from $source to access $register at $destination.
            %   Write $value to the register if $write is true. Some registers
            %   expect only one byte, set $writeOneByte to true then.
            
            % only require value if we are writing to a register
            if nargin == 4
                write = false;
                obj.write  = write;
            elseif write == true && nargin < 5
                exception = MException('VerifyArguments:TooFewArguments', ...
                    'Must specify a value to write if write = true');
                throw(exception);
            elseif write == true && (nargin == 5 || nargin == 6)
                [obj.value_msb, obj.value_lsb] = split_bytes(value);
                obj.write  = true;
                if nargin == 6
                    % some registers only accept 8 bit integers and expect 
                    % a telegram with only one payload byte
                    obj.writeOneByte = writeOneByte;
                end
            end
            
            obj.source       = source;
            obj.destination  = destination;
            obj.register     = register;
        end
        
        function [result payload] = send(obj, s)
            % Send Send the telegram to the open serial connection s and read any response at that port
            %   Returns false when NACK has been received from the device
            %           -1 when there has been an CRC error
            %           -2 when the device was busy
            %           true when a write succeeded and ACK has been received
            %           payload as hex cell when reading
            obj.prepareForSending();
            %obj.telegrm
            % send data to serial
            fwrite(s, hex2dec(obj.telegrm));
            pause(0.05);

            % read response
            if s.BytesAvailable > 0
                response = dec2hex(fread(s, s.BytesAvailable),2);
                responseMessage = cellstr(response(2:end-1,:));
                responseMessage = telegram.unescapeMessage(responseMessage);
                
                result = false;
                payload = [];
                %TODO: CHECK CRC16!
                % are we the destination of the message and is it coming from our module?
                if isequal(responseMessage(1), cellstr(dec2hex(obj.source,2))) && isequal(responseMessage(2), cellstr(dec2hex(obj.destination,2)))
                    if isequal(responseMessage(3), cellstr('00'))
                        %error('Received NACK on accessing register %d', obj.register)
                        result = false;
                        payload = 0;
                    elseif isequal(responseMessage(3), cellstr('01'))
                        %error('Received CRC error on accessing register %d', obj.register)
                        result = -1;
                        payload = 0;
                    elseif isequal(responseMessage(3), cellstr('02'))
                        %error('Device was "busy" when accessing register %d', obj.register)
                        result = -2;
                        payload = 0;
                    elseif isequal(responseMessage(3), cellstr('03'))
                        result = true;
                        payload = 0;
                    elseif isequal(responseMessage(3), cellstr('08')) && obj.write == false
                        result = true;
                        %get payload
                        payload = cellstr(responseMessage(5:end-2));
                    end
                end
            else
            % the module did not send any reply, we have to trust that the
            % command succeeded
                payload = {};
                result = true;
            end
        end
        
        function telegram = getAsHexCell(obj)
            obj.prepareForSending();
            telegram = obj.telegrm;
        end
    end
    
    methods(Access = 'private') 
        function obj = prepareForSending(obj)
            % prepareForSending Compose telegram and store in obj.telegrm
            %   Combine header, register, type and payload to a message. 
            %   Calculate and add CRC16. Escape the data. 
            %   Append SOT and EOT chars. Write to obj.telegrm
            
            % prepare mesage 
            if obj.write == true
                if obj.writeOneByte == true
                    obj.message = {dec2hex(obj.destination, 2), dec2hex(obj.source, 2), '05', dec2hex(obj.register, 2), obj.value_lsb};
                else
                    obj.message = {dec2hex(obj.destination, 2), dec2hex(obj.source, 2), '05', dec2hex(obj.register, 2), obj.value_lsb, obj.value_msb};
                end
            else
                obj.message = {dec2hex(obj.destination, 2), dec2hex(obj.source, 2), '04', dec2hex(obj.register, 2)};
            end
            
            % append crc16
            crc = bin2hex(calculateCRC16(hex2bin(obj.message), 'CCITT'));
            obj.message = horzcat(obj.message, crc);
            
            % escape message
            obj.message = telegram.escapeMessage(obj.message);
            
            % prefix start char 0D
            obj.telegrm = horzcat({'0D'}, obj.message);       
            
            %append terminator char
            obj.telegrm{1, end+1} = '0A';
        end
    end
    
    methods(Static)
        function escaped_message = escapeMessage(message)
            % apply escape sequences on 1xN or Nx1 string cells; return 1xN string cell
            escaped_message = {};
            for i = 1:max(size(message))
                if strcmp(telegram.start_char, message(i))
                    escaped_message = horzcat(escaped_message, telegram.escape_start);
                elseif strcmp(telegram.terminator_char, message(i))
                    escaped_message = horzcat(escaped_message, telegram.escape_terminator);
                elseif strcmp(telegram.escape_char, message(i))
                    escaped_message = horzcat(escaped_message, telegram.escape_escape);
                else
                    escaped_message = horzcat(escaped_message, message(i));
                end
            end
        end
        
        function unescaped_message = unescapeMessage(message)
            % undo escape sequences on 1xN or Nx1 string cells; return 1xN string cell
            unescaped_message = {};
            skipNext = false;
            
            for i = 1:(max(size(message))-1)
                if skipNext == true
                    skipNext = false;
                    continue
                end
                if isequal(telegram.escape_start, message(i:i+1)) || isequal(telegram.escape_start', message(i:i+1))
                    unescaped_message = horzcat(unescaped_message, telegram.start_char);
                    skipNext = true;
                elseif isequal(telegram.escape_terminator, message(i:i+1)) || isequal(telegram.escape_terminator', message(i:i+1))
                    unescaped_message = horzcat(unescaped_message, telegram.terminator_char);
                    skipNext = true;
                elseif isequal(telegram.escape_escape, message(i:i+1)) || isequal(telegram.escape_escape', message(i:i+1))
                    unescaped_message = horzcat(unescaped_message, telegram.escape_char);
                    skipNext = true;
                else
                    unescaped_message = horzcat(unescaped_message, message(i));
                end
            end
            if skipNext == false
                unescaped_message = horzcat(unescaped_message, message{end});
            end
        end
    end
end


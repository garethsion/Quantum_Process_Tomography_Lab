function [ s ] = openSerial( port, baudRate )
%OPENSERIAL Open or reallocate connection to SERIAl port at $port
%   Looks for a serial connection with specified options in memory,
%   reattaches it to a serial object and opens the connection if neccesary
%   Opens new connections if no old ones are found.
    s = instrfind({'Port', 'BaudRate'}, {port, baudRate});
    if isempty(s)
        s = serial(port, 'BaudRate', baudRate);
        fopen(s);
    else 
        if size(s) > 1 
            err = MException('ResultChk:OutOfRange', ...
                'More than one serial connection found at the specified port');
            throw(err)
        end
        if ~strcmp(s.Status, 'open')
            fopen(s);
        end
    end
end


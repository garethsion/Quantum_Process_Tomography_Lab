function [ buffer ] = read(gpib)
%GPIB_READ Low Level reading of GPIB buffer
    %  gpib_buffer = gpib_read(gpib, cnt )
    % Takes descriptor ud from ibdev and count is the number of bytes of
    % buffer to read.
    % Returns buffer as a string.

    ibrd(gpib, gpib.buffersize);
    buffer = char(gpib.buffer.Value(1:gpib.ibcnt));  % convert bufptr to string
    gpib.buffer.Value(1:gpib.ibcnt) = ' '; % clear out buffer
end
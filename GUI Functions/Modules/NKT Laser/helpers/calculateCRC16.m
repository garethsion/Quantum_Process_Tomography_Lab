function [ crc ] = calculateCRC16( msg, poly )
%CALCULATECRC16 This calculates the CRC-16 checksum for a given polynom and
% binary message
%   Specify Polynom to use in binary form using the second function
%   argument or as one of the strings defined below. If you want to use hex
%   format, use horzcat([1], hex2bin({'0A','0B'}) or similar as argument.
%   Though: the returned crc is binary. msb is left.
    if strcmp(poly, 'IBM')
            poly = [ 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 ];
    elseif strcmp(poly, 'CCITT')
            poly = [ 1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1 ];
    elseif strcmp(poly, 'T10-DIF')
            poly = [ 1 1 0 0 0 1 0 1 1 1 0 1 1 0 1 1 1 ];
    elseif strcmp(poly, 'DNP')
            poly = [ 1 0 0 1 1 1 1 0 1 0 1 1 0 0 1 0 1 ];
    elseif strcmp(poly, 'ARINC')
            poly = [ 1 1 0 1 0 0 0 0 0 0 0 1 0 1 0 1 1 ];
    elseif strcmp(poly, 'DECT')
            poly = [ 1 0 0 0 0 0 1 0 1 1 0 0 0 1 0 0 1 ];
    else
        [~, N] = size(poly);
        if N ~= 17
            fprintf('Calculating CRC-%d. Specify a polynom of order 16 (mind zeroth and 16th order) if you want to generate a CRC-16 checksum\n', N-1)
        end
    end

    [~, N] = size(poly);
    mseg = [msg zeros(1,N-1)];   % left shift message by N bytes  
    [~, r] = deconv(mseg,poly);  % get remainder of the polynom division of msg/poly
    r = abs(r);
    for i = 1:length(r)
        a = r(i);
        if ( mod(a,2) == 0 )
           r(i) = 0;
        else
            r(i) = 1;
        end
    end

    crc = r(length(msg)+1:end);
    %frame = bitor(mseg,r)
end


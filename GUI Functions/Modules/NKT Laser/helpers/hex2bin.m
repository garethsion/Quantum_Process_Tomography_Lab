function [ binstream ] = hex2bin( hex )
%HEX2BIN converts a cell of hex strings to binary 
% Converts something like ({'0A', '0B'...}) to array of size (1,N*8) of
% zeros and ones
    bin = hex2dec(hex);  % cast to decimal
    bin = dec2bin(bin);  % ... to binary string
    bin = cast(bin, 'double') - cast('0', 'double'); % ... to in binary double (filter() needs double)
    bin = padarray(bin, [0, 8-size(bin,2) ], 0, 'pre'); % recover all the zeros we've lost
    %bin = reshape(bin, prod(size(bin)), 1)' % ... as 1xN array instead of
    %MxN (lets call this bitstream) )£*$)&D Produces crap lets do it by hand :/
    
    % ... as 1xN array instead of MxN (lets call this bitstream):
    binstream = zeros(1,prod(size(bin)));
    for i = 1:size(bin,1)
        for j = 1:8
            binstream(1,(i-1)*8+j) = bin(i,j);
        end
    end
    
end


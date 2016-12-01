function [ hex ] = bin2hex( bitstream )
%BIN2HEX converts binary values to hex
%   msb is hex{1} lsb is hex{end}
    [M, N] = size(bitstream);
    if M > 1 | mod(N,8) ~= 0
        err = MException('ResultChk:OutOfRange', ...
            'Input is supposed to be 1xN where N%8 = 0');
        throw(err)
    end
    hex = cell(1,0);
    for i = 1:8:size(bitstream,2)
        hex{end+1} = dec2hex(bin2dec(num2str(bitstream(i:i+7))),2);
    end
end


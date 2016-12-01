function [msb,lsb] = split_bytes(value)
% function [msb,lsb] = split_bytes(value)

value = round(value);

if value < 0
    error('The value is negative');
end

if value >= 2^16
    error('The value is too large');
end

lsb = dec2hex(bitand(value,255),2);
msb = dec2hex(bitshift(bitand(value,255*256),-8),2);
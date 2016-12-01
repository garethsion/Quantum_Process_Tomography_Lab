function [ ibsta ] = ibclr(gpib)
%ibclr -- clear device (device)
%   [ ibsta ] = ibclr( ud )
% ibclr() sends the clear command to the device specified by ud.

ibsta = calllib('ni4882', 'ibclr', gpib.ud);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end

function ibsta = ibpad(gpib, pad)
%ibpad -- set primary GPIB address (board or device)
%   ibsta = ibpad(ud, pad)
% ibpad() sets the GPIB primary address to pad  for the device or board
%specified by the descriptor ud. If ud is a device descriptor, then the 
%setting is local to the descriptor (it does not affect the behaviour of 
%calls using other descriptors, even if they refer to the same physical 
%device). If ud is a board descriptor, then the board's primary address is 
%changed immediately, which is a global change affecting anything (even 
%other processes) using the board. Valid GPIB primary addresses are in the 
%range from 0 to 30.

ibsta = calllib('ni4882', 'ibpad', gpib.ud, pad);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end

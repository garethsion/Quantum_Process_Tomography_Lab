function ibsta = ibsad(gpib, sad)
%ibsad -- set secondary GPIB address (board or device)
%   ibsta = ibsad(sad)
% ibsad() sets the GPIB secondary address of the device or board specified 
%by the descriptor ud. If ud is a device descriptor, then the setting is 
%local to the descriptor (it does not affect the behaviour of calls using 
%other descriptors, even if they refer to the same physical device). If ud 
%is a board descriptor, then the board's secondary address is changed 
%immediately, which is a global change affecting anything (even other 
%processes) using the board.
%
%This library follows NI's unfortunate convention of adding 0x60 
%hexadecimal (96 decimal) to secondary addresses. That is, if you wish to 
%set the secondary address to 3, you should set sad to 0x63. Setting sad to
%0 disables the use of secondary addressing. Valid GPIB secondary addresses
%are in the range from 0 to 30 (which correspond to sad values of 0x60 to 
%0x7e). 

ibsta = calllib('ni4882', 'ibsad', gpib.ud, sad);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end

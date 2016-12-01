function ibsta = ibwait(gpib, status_mask)
%ibwait -- wait for event (board or device)
%   Detailed explanation goes here
% ibwait() will sleep until one of the conditions specified in status_mask 
%is true. The meaning of the bits in status_mask are the same as the bits 
%of the ibsta  status variable.
%
% If status_mask is zero, then ibwait() will return immediately. This is 
%useful if you simply wish to get an updated ibsta. 

ibsta = calllib('ni4882', 'ibwait', gpib.ud, status_mask);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
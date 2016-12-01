function ibsta = ibrda(gpib, cnt)
%ibrd -- read data bytes (board or device)
%   ibsta = ibrd(buffer, num_bytes)
%
% ibrd() is used to read data bytes from a device or board. The argument ud
%can be either a device or board descriptor. Up to num_bytes bytes are read
%. The read may be terminated by a timeout occuring(see ibtmo()), the 
%talker asserting the EOI line, the 
%board receiving the end-of-string character (see ibeos()), receiving a 
%device clear command, or receiving an interface clear.
%
%If ud is a device descriptor, then the library automatically handles 
%addressing the device as talker and the interface board as listener before
%performing the read.
%
%If ud is a board descriptor, no addressing is performed and the board must
%be addressed as a listener by the controller-in-charge.
%
%After the ibrd() call, ibcnt and ibcntl are set to the number of bytes 
%read. 

    ibsta = calllib('ni4882', 'ibrda', gpib.ud, gpib.buffer, cnt);
    gpib.ibsta = ibsta;
    gpib.ibcnt = calllib('ni4882', 'ThreadIbcnt');
    assignin('caller', inputname(1), gpib);
end
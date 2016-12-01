function ibsta = ibwrt(gpib, data, cnt)
%ibwrt -- write data bytes (board or device)
%   Detailed explanation goes here
%ibwrt() is used to write data bytes to a device or board. The argument ud
%can be either a device or board descriptor. num_bytes specifies how many 
%bytes are written from the user-supplied array data. EOI may be asserted 
%with the last byte sent or when the end-of-string character is sent (see 
%ibeos() and  ibeot()). The write operation may be interrupted by a 
%timeout (see  ibtmo()), the board receiving a device clear command, or 
%receiving an interface clear.
%
%If ud is a device descriptor, then the library automatically handles 
%addressing the device as listener and the interface board as talker, 
%before sending the data bytes onto the bus.
%
%If ud is a board descriptor, the board simply writes the data onto the 
%bus. The controller-in-charge must address the board as talker.
%
%After the ibwrt() call, ibcnt and ibcntl are set to the number of bytes 
%written. 

ibsta = calllib('ni4882', 'ibwrt', gpib.ud, libpointer('voidPtr',[uint8(data) 0]), cnt);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
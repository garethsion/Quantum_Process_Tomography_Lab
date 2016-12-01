function [ ibsta ] = ibgts(gpib, shadow_handshake)
%ibgts -- release ATN (board)
%   
% ibgts() is the complement of ibcac(), and causes the board specified by 
%the board descriptor ud  to go to standby by releasing the ATN line. The 
%board must be controller-in-change to change the state of the ATN line. 
%If shadow_handshake is nonzero, then the board will handshake any data 
%bytes it receives until it encounters an EOI or end-of-string character, 
%or the ATN line is asserted again. The received data is discarded.
%
%It is generally not necessary to call ibgts(). It is provided for advanced
%users who want direct, low-level access to the GPIB bus. 

ibsta = calllib('ni4882', 'ibgts', gpib.ud, shadow_handshake);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
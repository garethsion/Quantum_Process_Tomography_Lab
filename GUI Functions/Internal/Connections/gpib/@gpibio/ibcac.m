function ibsta = ibcac(gpib, synchronous)
%ibcac -- assert ATN (board)
%   ibsta = ibcac(synchronous)
% ibcac() causes the board specified by the board descriptor ud  to become
%active controller by asserting the ATN line. The board must be 
%controller-in-change in order to assert ATN. If synchronous is nonzero, 
%then the board will wait for a data byte on the bus to complete its 
%transfer before asserting ATN. If the synchronous attempt times out, or 
%synchronous  is zero, then ATN will be asserted immediately.
%
% It is generally not necessary to call ibcac(). It is provided for 
%advanced users who want direct, low-level access to the GPIB bus. 

ibsta = calllib('ni4882', 'ibcac', gpib.ud, synchronous);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
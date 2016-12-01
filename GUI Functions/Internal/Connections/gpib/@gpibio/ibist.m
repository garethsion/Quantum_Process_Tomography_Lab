function ibsta = ibist(gpib, ist)
%ibist -- set individual status bit (board)
%   ibsta = ibist(ud, ist)
% If ist is nonzero, then the individual status bit of the board specified 
%by the board descriptor ud  is set. If ist is zero then the individual 
%status bit is cleared. The individual status bit is sent by the board in 
%response to parallel polls.
%
%On success, iberr is set to the previous ist value. 

ibsta = calllib('ni4882', 'ibist', gpib.ud, ist);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
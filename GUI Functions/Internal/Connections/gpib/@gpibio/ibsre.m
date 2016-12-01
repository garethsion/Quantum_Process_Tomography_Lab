function ibsta = ibsre(gpib, enable)
%ibsre -- set remote enable (board, enable)
%   Detailed explanation goes here
%If enable is nonzero, then the board specified by the board descriptor ud
%asserts the REN line. If enable is zero, the REN line is unasserted. The 
%board must be the system controller.

ibsta = calllib('ni4882', 'ibsre', gpib.ud, enable);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
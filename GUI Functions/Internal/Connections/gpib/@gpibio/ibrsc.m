function ibsta = ibrsc(gpib, request_control)
%ibrsc -- request system control (board)
%   ibsta = ibrsc( ud, request_control)
% If request_control is nonzero, then the board specified by the board 
%descriptor ud is made system controller. If request_control  is zero, then
%the board releases system control.
%
% The system controller has the ability to assert the REN and IFC lines, and
%is typically also the controller-in-charge. A GPIB bus may not have more 
%than one system controller. 

ibsta = calllib('ni4882', 'ibrsc', gpib.ud, request_control);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);

end
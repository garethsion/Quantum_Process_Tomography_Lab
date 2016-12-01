function ibsta = ibpct(gpib )
%ibpct -- pass control (board)
%   ibsta = ibpct( ud )
%ibpct() passes control to the device specified by the device descriptor
%ud. The device becomes the new controller-in-charge.

ibsta = calllib('ni4882', 'ibpct', gpib.ud);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end

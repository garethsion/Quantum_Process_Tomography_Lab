function ibsta = ibsic( gpib )
%ibsic -- perform interface clear (board)
%   ibsta = ibsic
%ibsic() resets the GPIB bus by asserting the 'interface clear' (IFC) bus
%line for a duration of at least 100 microseconds. The board specified by 
%ud must be the system controller in order to assert IFC. The interface 
%clear causes all devices to untalk and unlisten, puts them into serial 
%poll disabled state (don't worry, you will still be able to conduct serial
%polls), and the board becomes controller-in-charge.

ibsta = calllib('ni4882', 'ibsic', gpib.ud);
gpib.ibsta= ibsta;
assignin('caller', inputname(1), gpib);
end

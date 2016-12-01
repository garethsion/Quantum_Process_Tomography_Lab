function ibsta = ibtrg(gpib)
%ibtrg -- trigger device (device)
%   ibsta = ibtrg
%ibtrg() sends a GET (group execute trigger) command byte to the device
%specified by the device descriptor ud.

ibsta = calllib('ni4882', 'ibtrg', gpib.ud);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end

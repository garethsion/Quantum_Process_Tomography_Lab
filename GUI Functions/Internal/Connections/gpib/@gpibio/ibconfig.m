function ibsta = ibconfig(gpib, option, setting)
%ibconfig -- change configuration (board or device)
%   ibsta = ibconfig(ud, option, setting)
%Changes various configuration settings associated with the board or device
%descriptor ud. The option argument specifies the particular setting you 
%wish to modify. The setting  argument specifies the option's new 
%configuration. To query the descriptor's configuration, see ibask().

ibsta = calllib('ni4882', 'ibconfig', gpib.ud, option, setting);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
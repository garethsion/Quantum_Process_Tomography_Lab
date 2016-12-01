function gpib = ibdev(gpib, brd, pad, sad, tmo, send_eoi, eos)
    % ibdev -- open a device
    % gpib = ibdev( brd, pad, sad, tmo, send_eoi, eos)
    %
    % ibdev() is used to obtain a device descriptor, which can then be used 
    % by other functions in the library. The argument board_index  specifies
    % which GPIB interface board the device is connected to. The pad and sad
    % arguments specify the GPIB address of the device to be opened 
    % (see  ibpad() and ibsad()). The timeout for io operations is specified
    % by  timeout  (see ibtmo()). If send_eoi is nonzero, then the EOI line 
    % will be asserted with the last byte sent during writes (see ibeot()). 
    % Finally, the eos  argument specifies the end-of-string character and 
    % whether or not its reception should terminate reads (see  ibeos()).
    
    gpib.ud = calllib('ni4882', 'ibdev', brd,pad,sad,tmo,send_eoi,eos); 
    gpib.ibsta = calllib('ni4882', 'ThreadIberr');
    assignin('caller', inputname(1), gpib);
end
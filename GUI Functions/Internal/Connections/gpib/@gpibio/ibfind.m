function gpib = ibfind(gpib, name )
% ibfind -- open a board or device (board or device)
% gpib = ibfind(gpib, name )
%
% ibfind() returns a board or device descriptor based on the information
% found in the configuration file. It is not required to use this function, 
% since device descriptors can be obtained with ibdev()  and the 'board 
% index' (minor number in the configuration file) can be used directly as a 
% board descriptor.

%ud = calllib('gpib32', 'ibfindA', libpointer('voidPtr',[uint8(name) 0]));
gpib.ud = calllib('ni4882', 'ibfindA', name);
gpib.iberr = calllib('ni4882', 'ThreadIberr');
assignin('caller', inputname(1), gpib)
end
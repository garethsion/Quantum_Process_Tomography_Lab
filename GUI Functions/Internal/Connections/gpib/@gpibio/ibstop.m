function ibsta = ibstop( gpib )
%ibstop -- abort asynchronous i/o operation (board or device)
%   ibsta = ibstop
% ibstop() aborts an asynchronous i/o operation (for example, one started 
%with ibcmda(), ibrda(), or ibwrta()).
%
% The return value of ibstop() is counter-intuitive. On successfully 
%aborting an asynchronous operation, the ERR bit is set in ibsta, and iberr
%is set to EABO. If the ERR bit is not set in ibsta, then there was no 
%asynchronous i/o operation in progress. If the function failed, the ERR 
%bit will be set and iberr will be set to some value other than EABO. 

ibsta = calllib('ni4882', 'ibstop', gpib.ud);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end

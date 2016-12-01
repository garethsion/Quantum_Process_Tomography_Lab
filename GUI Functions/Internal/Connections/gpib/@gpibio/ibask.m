function value= ibask(gpib, option)
% ibask -- query configuration (board or device)
% Queries various configuration settings associated with the board or device
% descriptor ud. The option argument specifies the particular setting you 
% wish to query. The result of the query is written to the location 
% specified by result. To change the descriptor's configuration, see ibconfig().

gpib.ibsta = calllib('ni4882', 'ibask', gpib.ud, option, gpib.buffer);
value = char(gpib.buffer);
end
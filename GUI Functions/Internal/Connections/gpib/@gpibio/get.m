function val = get(gpib, propName)
% GET Get asset properties from the specified object
% and return the value
switch propName
case 'buffer'
   val = char(gpib.buffer);
case 'ibcnt'
   val = gpib.ibcnt;
case 'ibsta'
   val = gpib.ibsta;
case 'timeout'
   val = gpib.timeout;
otherwise
   error([propName,' Is not a valid asset property'])
end
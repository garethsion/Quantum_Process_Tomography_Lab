function ibsta = ibtmo(gpib, timeout)
%ibtmo -- adjust io timeout (board or device, timeout)
%   ibtmo() sets timeout for IO operations performed using the board or
%device descriptor ud. The actual amount of time before a timeout occurs
%may be greater than the period specified, but never less. timeout is 
%specified by using one of the following constants:
%
%0	Never timeout.
%1	10 microseconds
%2	30 microseconds
%3	100 microseconds
%4	300 microseconds
%5	1 millisecond
%6	3 milliseconds
%7	10 milliseconds
%8	30 milliseconds
%9	100 milliseconds
%10	300 milliseconds
%11	1 second
%12	3 seconds
%13	10 seconds
%14	30 seconds
%15	100 seconds
%16	300 seconds
%17	1000 seconds

ibsta = calllib('ni4882', 'ibtmo', gpib.ud, timeout);
gpib.ibsta = ibsta;
end
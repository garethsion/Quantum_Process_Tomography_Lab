function [ status ] = write(gpib, command)
%GPIB_WRITE: Write a string to a GPIB device.
    %  retval  = gpib_write(command)
    
    %check terminator input and set terminator to correct setting   
    term = gpib.Terminator;
    
    %calculate string length
    count = length(command) + length(term)/2;
    status=ibwrt(gpib, [command sprintf(term)],count);
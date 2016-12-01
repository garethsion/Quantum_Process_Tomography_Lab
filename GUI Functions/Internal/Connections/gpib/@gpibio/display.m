function display(gpib)
% display - prints the properties of gpibio object

    disp(' ');
    disp([inputname(1),' = '])
    disp(sprintf('%s%i', '       ud: ', gpib.ud))
    disp(sprintf('%s%i', '    ibcnt: ', gpib.ibcnt))
    disp(sprintf('%s%i','    ibsta: ' , gpib.ibsta))
    disp(sprintf('%s%i','    iberr: ' , gpib.iberr))
    disp(sprintf('%s%i','  timeout: ', gpib.timeout))
end
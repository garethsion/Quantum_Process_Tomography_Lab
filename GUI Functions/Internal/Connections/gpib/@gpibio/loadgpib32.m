function loadgpib32()
% Loads the dll gpib32. You may need to change the paths in this file.
% You will need to call this before you use any methods for the gpib class.
    loadlibrary('C:\Windows\SysWOW64\ni4882.dll', ...
        'C:\Program Files (x86)\National Instruments\Shared\ExternalCompilerSupport\C\include\ni4882.h', ...
        'alias' , 'ni4882' );
end
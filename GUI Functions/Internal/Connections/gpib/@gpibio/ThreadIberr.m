function iberr = ThreadIberr( gpib )
%THREADIBERR Updates the value of iberr

    gpib.ibsta.Value = calllib('ni4882', 'ThreadIberr');
    iberr = gpib.iberr.Value;
end

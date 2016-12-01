function ibsta = ThreadIbsta( gpib )
%THREADIBSTA Updates the value of ibsta

    gpib.ibsta.Value = calllib('ni4882', 'ThreadIbsta');
    ibsta = gpib.ibsta.Value;
end

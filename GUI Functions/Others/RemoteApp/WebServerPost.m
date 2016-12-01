
% Function to post data to a webserver using HTTP POST.
% This function is intended for use within the WebServerGet function.
%
%USAGE: WebServerPost('1', '<result>result</result'>
function WebServerPost(index, result)

    % Url to push data to.
    urlPush = 'http://iosrc.tebira.co.uk/mail_send.php';
    % Parameters required as a list of key-value pairs.
    params = {'index', index, 'message', result};
    
    % Perform HTTP POST
    r = urlread(urlPush, 'POST', params);
end

% Function to poll a remote webserver and retrieve tasks from it.
% Once the task has been received, the corresponding m-file is executed and
% the results returned to the webserver.
%
% USAGE: If polling mailbox n, WebServerGet(n) where n is of type integer.
function WebServerGet(index, postIndex)

    % In production usage, this value shouldn't be set and so a default
    % mailbox is used for posting results.
    if nargin < 2
        postIndex = '0';
    end
    
    % Create a local run Id value to prevent the same task being repeatedly
    % executed.
    localRunId = '-2';
    
    % This is used for xml parsing, MATLAB doesn't appear to be capable of
    % parsing xml in memory from a string.
    filename = 'temp.xml';
    % Url for checking and reading a mailbox.
    urlMailCheck = sprintf('http://iosrc.tebira.co.uk/mail_check.php?index=%d', index);
    urlMailRead = sprintf('http://iosrc.tebira.co.uk/mail_read.php?index=%d', index);
    
    % Run this indefinitely.  At present, operation will have to be
    % terminated via CTRL+C.
    fprintf('Server started.  Listening on Index: %d\n', index);
    
    initRun = 1;
    
    while true
        try
             % Check if mailbox contains data.
            str = urlread(urlMailCheck);

            % Handle returned xml information.
            xDoc = xmlreadstring(str);
            xmlwrite(filename, xDoc);

            % Retrieve the mail_ready node from the xml.
            mailReady = GetXmlParam(filename, 'mail_ready');

            % If mail_ready value is 1, a task has been posted.
            if(strcmp(mailReady, '1'))
                % Read the task that has been posted.
                str = urlread(urlMailRead);

                % Handle returned xml information.
                xDoc = xmlreadstring(str);
                xmlwrite('temp.xml', xDoc);

                % Get the run id value that was posted with this task.
                runId = char(GetXmlParam(filename, 'id'));
                
                % Check run id is valid i.e. that the run id was actually
                % present and ensure it is different to the local run id.
                % If they're the same, assume an already executed task has
                % been received and ignore it.
                if(strcmp(runId, '-1') == 0 && strcmp(runId, localRunId) == 0)
                    
                    % Set local run id to new run id.
                    localRunId = runId;
                    % Get the exmperiment to be carried out.
                    experiment = char(GetXmlParam(filename, 'action'));
                    
                    if initRun == 1
                        initRun = 0;
                        continue
                    end
                    
                    fprintf('New task: %s, RunID: %s\n', experiment, localRunId);

                    responseMessage = sprintf('<id>%s</id><result>Pending</result><error>None</error>', localRunId);
                    WebServerPost(int2str(postIndex), responseMessage);

                    %--------------------------%
                    %-- CARRY OUT EXPERIMENT --%
                    %--------------------------%
                    % This result value should be from the experiment.
                    [resultSet, resultError] = RunExperiment(experiment);

                    result = sprintf('<id>%s</id><result>%s</result><error>%s</error>', localRunId, resultSet, resultError);
                    fprintf(sprintf('Task %s complete\n', char(experiment)));
                    fprintf(sprintf('Posting results for RunID: %s\n', localRunId));

                    % Post result to webserver.
                    % NOTE: Using mailbox 0 to post results to.

                    WebServerPost(int2str(postIndex), result);
                end
            end
        catch
            try
                % Error occured during retrieval or execution of
                % experiment, notify the webserver.
                fprintf('Error occured, sending error notification\n');
                
                result = '<result>Error</result><error>Task Error</error>';
                
                pause(2);
                WebServerPost(int2str(postIndex), result);
            catch
                % Error occured in communicating with webserver.  Continue
                % with loop for now.
                fprintf('Error communicating with server');
            end
        end
        % Wait for half a second before polling again.
        pause(0.5);
    end
end
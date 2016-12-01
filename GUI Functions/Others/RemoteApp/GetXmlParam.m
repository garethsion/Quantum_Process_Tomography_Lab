
% Function to retrieve the value of the xml node specified in the file
% supplied.  If there are more than one nodes with the same node name, only
% the value of the first node will be returned.
%
% USAGE: value = GetXmlParam('filename.xml', 'action')
function xmlValue = GetXmlParam(filename, nodeName)
    % Read the xml file.
    xDoc = xmlread(filename);
    
    % Get the node specified by nodeName.
    xmlNode = xDoc.getElementsByTagName(nodeName);
    try
        % Get the value.
        xmlValue = xmlNode.item(0).getTextContent;
    catch
        % If the node doesn't exist, return '-1'.
        xmlValue = '-1';
    end
end

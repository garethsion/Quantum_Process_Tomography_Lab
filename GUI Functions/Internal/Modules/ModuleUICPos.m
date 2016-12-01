function [textPos, inputPos] = ModuleUICPos(pos1,pos2)
%This function provides the location for UIcontrols (similar to the subplot fct)
%within the module area
borders = 0.011;

text_width = 0.145;
text_height = 0.033;

input_width = 0.06;
input_height = 0.04;

total_width = 4*borders + text_width + input_width;

textPos = [borders+0.002 + (0.98*pos2-1)*total_width, ... %X
           1-5*borders - pos1*(text_height + 2*borders),... %Y
           text_width,... %width
           text_height]; %height

inputPos = [textPos(1) + text_width + borders,... %X
            textPos(2),... %Y
            input_width,... %width
            input_height]; %height
end


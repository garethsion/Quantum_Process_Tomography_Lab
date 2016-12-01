clear all;
%%
mark_width = 32;
mark_pos = 0;


marker_points = mark_width/4;
mark_pos = mark_pos + 24;

a = zeros(1,marker_points);
for ii = 0:1:marker_points-1
    wave_index = 24*(floor(mark_pos/32)+1)+mark_pos/4;
    mark_pos = mark_pos+4;
    
    a(ii+1) = wave_index;
    b(ii+1) = mark_pos;
end
'next'
a
b
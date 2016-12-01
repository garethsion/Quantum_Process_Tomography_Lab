classdef ShapeClass
    %PulseClass defines a compiled experiment pulse
    %ALL TIMES ARE IN UNIT OF 1/SAMPLING FREQUENCY (RAST)
    
    properties
        shape %Shape (Tptsx2, double): I,Q
        shape_rep %Real shape is shape concatenated shape_rep times
        channel %Channel (due to Markers, channel must be specific to a shape)
        markers %Markers for that pulse: logical/boolean matrix (time,4) for each marker channel
               %1- Defense pulse (to switch on/off LNA arm), off = LNA off
               %2- TWT on/off (embedded within defense pulse), off = TWT off
               %3- MW/RF switch channel, off = MW
               %4- Unused like a U1 channel?
    end
    
    methods
        function obj = ShapeClass(new_shape,new_shape_rep,new_channel,new_markers)
            obj.shape = new_shape;
            obj.shape_rep = new_shape_rep;
            obj.channel = new_channel;
            obj.markers = new_markers;
        end
    end
    
end


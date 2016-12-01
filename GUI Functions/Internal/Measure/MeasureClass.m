classdef MeasureClass < handle
    %This class helps define what sweep need to be made during experiment
    
    properties (Access = public)
        %Labels/Texts
        name  %Measurement type name
        label %Measurement label
        
        %State
        state = 0; %State status, if active, measure
        
        %Data
        data %Measured data
        get_data %Function to get data
        
        %"Transient" (sweep value given in one shot) axis
        transient_axis = [];
        
        %Parent module
        mod
    end
    
    methods
        %Create a new parameter
        function obj = MeasureClass(mod,name,label,get_data,varargin)
            obj.mod = mod;
            obj.name = name;
            obj.label = label;
            obj.get_data = get_data;
            
            if(~isempty(varargin))
                obj.transient_axis = ParameterClass(obj.mod,name,varargin{1},[],[],[]);
            end
        end   
    end
end


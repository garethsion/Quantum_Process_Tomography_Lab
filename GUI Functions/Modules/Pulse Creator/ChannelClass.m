classdef ChannelClass
%This class defines all the properties of a channel and its associated
%markers
    
    properties (SetAccess = private, GetAccess = public)
        %Index of channel for AWG (marker value)
        index
        
        %Minimum separation between waveforms of different channels
        preDefense %s
        postDefense %s
        
        %Separation between markers and associated waveforms
        preMarker %s
        postMarker %s
        
        %Waveform maximum duty cycle
        dutyCycle
    end
    
    properties (Access = public)
        RAST %MHz
    end
    
    methods
        function obj = ChannelClass(index,defense,marker,dutyCycle)
            obj.index = index;
            
            defense = abs(defense); 
            marker = abs(marker);
            defense = max(defense,marker);
            
            obj.preDefense = defense(1);
            obj.postDefense = defense(2);
            
            obj.preMarker = marker(1);
            obj.postMarker = marker(2);
            
            obj.dutyCycle= dutyCycle;
        end
        
        function value = get.preDefense(obj)
            value = ceil((obj.preDefense)*(obj.RAST*1e6)); 
        end
        
        function value = get.postDefense(obj)
            value = ceil((obj.postDefense)*(obj.RAST*1e6)); 
        end
        
        function value = get.preMarker(obj)
            value = ceil((obj.preMarker)*(obj.RAST*1e6)); 
        end
        
        function value = get.postMarker(obj)
            value = ceil((obj.postMarker)*(obj.RAST*1e6)); 
        end
        
        function value = get.dutyCycle(obj)
            value = obj.dutyCycle;
        end
    end
    
end


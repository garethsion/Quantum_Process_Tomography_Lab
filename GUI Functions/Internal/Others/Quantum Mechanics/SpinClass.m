classdef SpinClass
    %SpinClass is used to generate the pauli matrices.
    
    properties
        Number
        X
        Y
        Z
        I
        
        P
        M
        
        Sel
        
        vec
    end
    
    methods
        function obj = SpinClass(spinNumber)
            obj.Number = spinNumber;
            %Pauli X,Y,Z,I matrices
            obj.X = CreatePauli(spinNumber,'X');
            obj.Y = CreatePauli(spinNumber,'Y');
            obj.Z = CreatePauli(spinNumber,'Z');
            obj.I = CreatePauli(spinNumber,'I');
            
            %Creation/annihilation
            obj.P = CreatePauli(spinNumber,'P');
            obj.M = CreatePauli(spinNumber,'M');
            
            %State selective operator
            obj.Sel = cell(length(obj.I),1);
            for ct = 1:length(obj.I)
                obj.Sel{ct} = zeros(size(obj.I));
                obj.Sel{ct}(ct,ct) = 1;
            end
            
            obj.vec = {obj.I obj.X obj.Y obj.Z};
        end
    end
end


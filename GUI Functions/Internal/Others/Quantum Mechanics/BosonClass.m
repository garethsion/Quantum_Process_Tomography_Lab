classdef BosonClass
    %SpinClass is used to generate the pauli matrices.
    
    properties (SetAccess = private)
        ac %creation a+
        aa %annihilation a
        n %photon count
        
        X
        Y
        Z
        I
    end
    
    methods
        function obj = BosonClass(count)
            if(count < 1 || count~=round(count))
                error('Count must be an integer value > 0');
            end
            
            obj.n = count; 
            obj.ac = diag(sqrt(1:count),-1);
            obj.aa = diag(sqrt(1:count),1);
                  
            obj.X = obj.aa + obj.ac;
            obj.Y = 1i*(obj.aa - obj.ac);
            obj.Z = obj.ac*obj.aa;
            obj.I = eye(count+1);
        end
    end
end


classdef SiDonorClass < handle
    %Parameter class for the SiDonor sets of function
    %Donors currently defined:
    %  - Phosphorus '31P'
    %  - Arsenic '75As'
    %  - Antimony '121Sb' or '123Sb'
    %  - Bismuth '209Bi'
    %  - Selenium '77Se='
    
    properties (SetAccess = private)
        %Class params
        SymFlag
        Hdim
        ParamDim
        
        %Basic params
        I %Nuclear spin number
        B %Field, T
        A %Hyperfine, Hz
        E %Electron gyromagnetic ratio, Hz/T
        N %Nuclear gyromagnetic ratio, Hz/T
        
        %Stark params
        etaA %Hyperfine Stark parameter, m^2/V^2
        etag %Electron g-factor Stark parameter, m^2/V^2
        
        %T1 vs temperature
        T1 %[K s]
    end
    
    methods
        function obj = SiDonorClass(varargin)
%----------------------------------------------
%------------ Create SiDonor object -----------
%----------------------------------------------
%
%obj = SiDonorClass(varargin)
%
%Inputs (varargin): donor type
            obj.B = NaN;
            obj.SymFlag = 0;
            obj.ParamDim = 1;
            
            %Hyperfine/g-factor cofficients
            %http://www.kc.tsukuba.ac.jp/div-media/epr/inplist.php?category=Si&u=G
            %http://www.easyspin.org/documentation/isotopetable.html
            
            %T1 values
            %T. Castner, Phys. Rev. 130, 58 (1963). (Points digitized from
            %paper)
            
            if(~isempty(varargin))
                switch varargin{1}             
                    case '31P' %Checked
                        obj.A = 117.53e6;
                        obj.E = -2.8025e10*1.9985/2.002319;
                        obj.N = 17.235e6;
                        obj.I = 1/2;
                        
                        obj.etaA = -2.51e-3*1e-12;
                        obj.etag = 3.4e-6*1e-12;
                        
                        obj.T1 = [[20.20274 16.378803 13.823984 11.835591 ...
                                   10.785251 10.281191 9.011799 8.52604 ...
                                   8.060549 7.7096457 7.317303 7.048815 ...
                                   6.8607616 6.5376043 6.3429914 6.132923 ...
                                   5.883587 5.731825 5.246751 4.9800925 ...
                                   4.660899 4.425098 4.1413317 4.0461416 ...
                                   3.639747 3.258219 2.8894768 2.5993514 ...
                                   2.3494666 2.1333861 1.9376671 1.7525275]; ...
                                  [4.6724494E-7 1.9372194E-6 6.9480207E-6 ...
                                   2.8357703E-5 8.496095E-5 1.1796743E-4 ...
                                   0.0013234329 0.0021275838 0.00502961 ...
                                   0.008090011 0.01651498 0.028598541 ...
                                   0.066470735 0.112951465 0.20674467 ...
                                   0.345166 0.77278566 1.1143221 2.1099648 ...
                                   4.1519804 6.4307437 11.128082 17.554993 23.185604 ...
                                   43.482674 100.68913 274.64438 503.13593 ... 
                                   819.9063 1305.39 1763.7372 1884.5812]];
                        
                    case '75As' %Checked
                        obj.A = 198.35e6;
                        obj.E = -2.8025e10*1.99837/2.002319;
                        obj.N = 7.3150e6;
                        obj.I = 3/2;
                        
                        obj.etaA = -1.20e-3*1e-12;
                        obj.etag = 4.9e-6*1e-12;
                        
                        obj.T1 = [[24.092472 21.642923 20.317406 19.424774 ...
                                   18.652641 18.173416 17.644133 16.929762 ...
                                   15.837474 15.418721 14.858683 10.284425 ...
                                   9.4457 9.034812 8.415949 7.083376 6.575859 ...
                                   5.776857 5.50764 5.3663244 5.286125 4.984792 ...
                                   4.6153545 4.019188 3.980407 3.5658648 ...
                                   3.251774 3.0343897 2.6685662 2.4921427 ...
                                   2.3697112 2.0933945]; ...
                                  [1.9518792E-7 5.1389407E-7 1.0877305E-6 ...
                                   2.1808669E-6 2.974068E-6 4.0586283E-6 ...
                                   5.2409227E-6 1.0704508E-5 2.1049416E-5 ...
                                   4.3023498E-5 6.087696E-5 0.030778082 0.06751155 ...
                                   0.10661504 0.29171228 0.67324674 1.6196191 ...
                                   5.6103477 7.238271 9.698149 12.764342 17.075064 ...
                                   34.72678 92.45872 134.49884 190.3432 ...
                                   365.64496 610.7795 1017.80414 1014.98193 ...
                                   1165.9321 2036.5724]];
                        
                    case '121Sb' %Checked
                        obj.A = 186.8e6;
                        obj.E = -2.8025e10*1.99858/2.002319;
                        obj.N = 1.0256e7;
                        obj.I = 5/2;
                        
                        obj.etaA = -3.54e-3*1e-12;
                        obj.etag = 5.3e-6*1e-12;
                        
                        obj.T1 = [[9.154598 8.786098 8.344511 8.04058 7.375049 ...
                                   6.900184 6.453639 2.6914296 2.1042163 1.8388809];...
                                  [3.4136005E-7 6.131274E-7 8.8301005E-7 1.320189E-6 ...
                                   5.81836E-6 1.0631054E-5 2.333975E-5 54.669014 ...
                                   222.14383 265.1804]];
                        
                    case '123Sb' %Checked
                        obj.A = 101.5e6;
                        obj.E = -2.8025e10*1.99858/2.002319;
                        obj.N = 5.555e6; %NOT GOOD
                        obj.I = 7/2;
                        
                    case '209Bi' %Checked
                        obj.A = 1.47517e9; %Hz, from CT %OLD = 1.4754e9;
                        obj.E = -2.8025e10*2.0003/2.002319;
%                         obj.E = -2.80575e10;  %Hz/T, from CT + X-band EPR %OLD = -2.8025e10;
                        obj.N = 7e6; %Hz/T
                        obj.I = 9/2;
                        
                        obj.etaA = -0.24e-3*1e-12;
                        obj.etag = 3.0e-6*1e-12;
                        
                        obj.T1 = [[30.6581 29.802776 28.85301 ...
                                        27.541098 26.779482 26.286 25.09984 ...
                                        22.472853 20.034319 19.133022 17.768896 ...
                                        10    9      8      7       5       4.2];...
                                      [3.224314E-7 5.925413E-7 8.0267125E-7 ...
                                       1.4739998E-6 2.2987736E-6 2.904068E-6 4.2182696E-6 ...
                                       8.687296E-6 1.5180008E-5 2.0075513E-5 3.859317E-5 ...
                                       0.004733 0.012507 0.034158 0.120747 1.94389 6.99658]];
                        
                    case '77Se+'
                        obj.A = 1.66e9; %Hz %Not sure? 1598??
                        obj.E = -2.8025e10*2.0057/2.002319; 
                        obj.N = 8.1573e6; %Hz/T
                        obj.I = 1/2;
                    otherwise
                        disp('UNKNOWN DONOR: define manually I,A,gammaE,gammaN');                        
                end
            else
                disp('NO TYPE GIVEN: define manually I,A,gammaE,gammaN');
            end
            obj.Hdim = 2*(2*obj.I+1);
        end
        
        function set(obj,varargin) 
%----------------------------------------------
%------------ Parameters definition -----------
%----------------------------------------------
%
%SiDonorClass.setParams(varargin)
%
%Inputs: 2-by-2 inputs ['B', 'A', 'E', 'N'], [value, 'sym']
%        The nuclear spin number 'I' can also be modified
%        B (T) must be given, however A (Hz), E=gammaE (Hz/T) and 
%        N=gammaN (Hz/T) have their default value. An array of value for
%        a single parameter will be calculated (only the longest array to
%        avoid large memory demands).
        
        for ct = 1:floor(length(varargin)/2)
            switch(varargin{2*ct-1})
                case 'B' 
                    if(strcmp(varargin{2*ct},'sym'))
                        obj.B = sym('B', 'real');
                    elseif(~ischar(varargin{2*ct}))
                        obj.B = varargin{2*ct}(:).';
                    end
                case 'A' 
                    if(strcmp(varargin{2*ct},'sym'))
                        obj.A = sym('A', 'real');
                    elseif(~ischar(varargin{2*ct}))
                        obj.A = varargin{2*ct}(:).';
                    end
                case 'E'
                    if(strcmp(varargin{2*ct},'sym'))
                        obj.E = sym('E', 'real');
                    elseif(~ischar(varargin{2*ct}))
                        obj.E = varargin{2*ct}(:).';
                    end
                case 'N' 
                    if(strcmp(varargin{2*ct},'sym'))
                        obj.N = sym('N', 'real');
                    elseif(~ischar(varargin{2*ct}))
                        obj.N = varargin{2*ct}(:).';
                    end
                case 'I'
                    if(~ischar(varargin{2*ct}))
                        obj.I = varargin{2*ct};    
                    end
                    
                case 'etaA'
                    if(~ischar(varargin{2*ct}))
                        obj.etaA = varargin{2*ct};    
                    end
                    
                case 'etag'
                    if(~ischar(varargin{2*ct}))
                        obj.etag = varargin{2*ct};    
                    end
            end
        end
        
        if(isa(obj.B,'sym') || isa(obj.A,'sym') || ...
           isa(obj.E,'sym') || isa(obj.N,'sym'))
            obj.SymFlag = 1;
        else
            obj.SymFlag = 0;
        end
        
        obj.Hdim = 2*(2*obj.I+1);
        obj.ParamDim = max([length(obj.B) length(obj.A) ...
                            length(obj.E) length(obj.N)]);
            
        end
    end
end

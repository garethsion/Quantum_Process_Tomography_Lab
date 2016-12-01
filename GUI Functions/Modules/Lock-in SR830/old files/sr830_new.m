classdef sr830
    
    properties
        dev     % for gpib read/write operations  
        OFLT_val=[10e-6,30e-6,100e-6,300e-6,1e-3,3e-3,10e-3,30e-3,100e-3,300e-3,1,3,10,30,100,300,1e3,3e3,10e3,30e3];
        SENS_val=[2e-9,5e-9,10e-9,20e-9,50e-9,100e-9,200e-9,500e-9,1e-6,2e-6,5e-6,10e-6,20e-6,50e-6,100e-6,200e-6,500e-6,1e-3,2e-3,5e-3,10e-3,20e-3,50e-3,100e-3,200e-3,500e-3,1];
        OFSL_val=[6,12,18,24];
    end
    
    methods
        
        function [obj] = sr830(n)    
            if ~exist('n','var')
                n='SR830A';
            end
            obj.dev = gpibio(0,n,0,13,1,0);
            pause(0.1);
            obj.clear();
            reply = obj.dev.ask('*IDN?')
            %{
            if length(reply) < 5
                error(sprintf('*IDN? replies with %s - Please check the Stanford lock-in is plugged into the computer via GPIB\n',reply));
            else
                disp(reply);
            end
            
            reply = obj.dev.ask('*IDN?');
            %}
        end
        
        
        function [v] = clear(obj,n)
            obj.dev.write('*CLS');        
        end
        % =============================== %
        % INITIALIZE parameters
        % =============================== %
        function [obj] = set_all(obj,varargin)
            % Defualt settings:
            P.PHAS=0; % [deg] Phase
            P.FMOD=1; % [n/a] Internal reference
            P.FREQ=1234; % [Hz] Frequency 
            P.RSLP=0; % [n/a] external reference slope
            P.HARM=1;
            P.SLVL=0.004; % [V]
            P.ISRC=3;
            P.IGND=0;
            P.ICPL=0;
            P.ILIN=3;
            P.SENS=1; % [V]
            P.RMOD=1;
            P.OFLT=100e-3; % [s]
            P.OFSL=24; % [dB/oct]
            P.SYNC=0;
            P.DDEF=[1 0 0; 2 0 0]; % [ch var ratio] channel 1 and 2 display options
            P.FPOP=[1 1;2 1];
            P.OEXP=[1 0 0; 2 0 0]; % channel offset and expand options
            P.AUXV=[1 0; 2 0; 3 0; 4 0]; % [V] aux outputs
            P.OUTX=1;
            P.OVRM=1;
            P.KCLK=1;
            P.ALRM=1;
            % replace default if parameter specified explicitly
            if ~isempty(varargin)
                for i=1:2:length(varargin)
                    if isfield(P,upper(varargin{i}))==1
                        P=setfield(P,upper(varargin{i}),varargin{i+1});
                    else
                        error('Check inout field name! (%s)',varargin{i});
                    end
                end
            end
            % set lockin
            obj.set(...
                'PHAS',P.PHAS,... % [deg] Phase
                'FMOD',P.FMOD,... % [n/a] Internal reference
                'FREQ',P.FREQ,... % [Hz] Frequency 
                'RSLP',P.RSLP,... % [n/a] external reference slope
                'HARM',P.HARM,...
                'SLVL',P.SLVL,... % [V]
                'ISRC',P.ISRC,...
                'IGND',P.IGND,...
                'ICPL',P.ICPL,...
                'ILIN',P.ILIN,...
                'SENS',P.SENS,... % [V]
                'RMOD',P.RMOD,...
                'OFLT',P.OFLT,... % [s]
                'OFSL',P.OFSL,... % [dB/oct]
                'SYNC',P.SYNC,...
                'DDEF',P.DDEF(1,:),... % [ch var ratio] channel 1 and 2 display options
                'DDEF',P.DDEF(2,:),...
                'FPOP',P.FPOP(1,:),...
                'FPOP',P.FPOP(2,:),...
                'OEXP',P.OEXP(1,:),...% channel offset and expand options
                'OEXP',P.OEXP(2,:),...% channel offset and expand options
                'AUXV',P.AUXV(1,:),... % [V] aux outputs
                'AUXV',P.AUXV(2,:),...
                'AUXV',P.AUXV(3,:),...
                'AUXV',P.AUXV(4,:),...
                'OUTX',P.OUTX,...
                'OVRM',P.OVRM,...
                'KCLK',P.KCLK,...
                'ALRM',P.ALRM...
                );
        end
        % =============================== %
        % SET parameters
        % =============================== %
        function [obj] = set(obj,varargin)
            imax=length(varargin);
            for i=1:2:imax % loop through all queries 
                param=upper(varargin{i}); % read set parameter, ensure upper case
                
                switch param % read parameter
                    
                    case {... % parameters which do not require additional input
                            'PHAS','FMOD','FREQ','RSLP','HARM','SLVL',...
                            'ISRC','IGND','ICPL','ILIN',...
                            'RMOD','SYNC',...
                            'OUTX','OVRM','KCLK','ALRM',... 
                            'DDEF','FPOP','OEXP',...
                            'AUXV',...
                            'OUTP','OUTR','SNAP','OAUX'...
                            } 
                        ijk=varargin{i+1};
                    case 'OFLT'
                        ijk=find(obj.OFLT_val==varargin{i+1})-1;
                        if isempty(ijk)
                            error('Value not found! Check OFLT input parameter!');
                        end
                    case 'SENS'
                        ijk=find(obj.SENS_val==varargin{i+1})-1;
                        if isempty(ijk)
                            error('Value not found! Check SENS input parameter!');
                        end    
                    case 'OFSL'
                        ijk=find(obj.OFSL_val==varargin{i+1})-1;
                        if isempty(ijk)
                            error('Value not found! Check OFSL input parameter!');
                        end    
                otherwise
                        error('Check input parameter command (%s)!',param);    
                end
                
                % ---------- SET ---------- %
                % add comma between numerics for matrix array
                ijks=num2str(ijk(1));
                for j=2:1:length(ijk)
                    ijks=horzcat([ijks,',',num2str(ijk(j))]);
                end
                obj.dev.writef(horzcat([param,' ',ijks]));
                % ---------- SET ---------- %
            end
        end  
        
        % =============================== %
        % QUERY parameters
        % =============================== %
        function [varargout] = query(obj,varargin)
            imax=length(varargin);
            i=0; % counter for number of input queries
            iout=0; % secoundary counter in case optional arguments for queries are present
            while i<imax % loop through all queries
                i=i+1; 
                iout=iout+1;
                param=upper(varargin{i}); % read query parameter, ensure upper case
                
                switch param % read parameter
                    
                    case {... % parameters which do not require additional input
                            'PHAS','FMOD','FREQ','RSLP','HARM','SLVL',...
                            'ISRC','IGND','ICPL','ILIN',...
                            'SENS','RMOD','OFLT','OFSL','SYNC',...
                            'OUTX','OVRM','KCLK','ALRM',...
                            'SRAT','SEND','TSTR',...
                            'SPTS','FAST',...
                            'LOCL','OVRM'...
                            }
                        varargout{iout} = str2num(obj.dev.ask(horzcat([param,'? '])));
                    case {... % parameters requiring additional numeric input
                            'DDEF','FPOP','OEXP',...
                            'AUXV',...
                            'OUTP','OUTR','SNAP','OAUX'...
                            }
                        if length(varargin)<i+1 || ischar(varargin{i+1})
                            error('Insufficient input arguments (%s)!',param);
                        else
                            ijk=varargin{i+1}; % read additional input arguments
                            i=i+1; % additional increment on i, don't increment iout.
                        end
                        varargout{iout} = str2num(obj.dev.ask(horzcat([param,'? ',num2str(ijk)])));
                    otherwise
                        error('Check input parameter command (%s)!',param);    
                end
                
                % ---------- INTERPRET ---------- %
                % interpret parameter if necessary
                if isempty(varargout{iout})
                    error('Query unsuccessful! Try again!')
                elseif strcmp(param,'OFLT') % convert time constant settings to actual values in [s].
                    varargout{iout}=obj.OFLT_val(varargout{iout}+1);
                elseif strcmp(param,'SENS') % convert sensitivity settings to actual values in [V].
                    varargout{iout}=obj.SENS_val(varargout{iout}+1);
                end
            end
        end
        
        % =============================== %
        % READ parameters (same as QUERY but with extra holding period)
        % =============================== %
        function [out] = read(obj,nwait,varargin)        
            % nwait is the number of time constants to wait before reading data
            pause(obj.query('OFLT')*nwait); % wait till stable
            out=obj.query(varargin{:});
        end  
        
        % =============================== %
        % QUERY ALL parameters
        % =============================== %
        function [P] = query_all(obj)
           P.PHAS=obj.query('PHAS');
           P.FMOD=obj.query('FMOD');
           P.FREQ=obj.query('FREQ'); 
           P.RSLP=obj.query('RSLP');
           P.HARM=obj.query('HARM');
           P.DLVL=obj.query('SLVL');
           P.ISRC=obj.query('ISRC');
           P.IGND=obj.query('IGND');
           P.ICPL=obj.query('ICPL');
           P.ILIN=obj.query('ILIN');
           P.SENS=obj.query('SENS');
           P.RMOD=obj.query('RMOD');
           P.OFLT=obj.query('OFLT');
           P.OFSL=obj.query('OFSL');
           P.SYNC=obj.query('SYNC');
           P.DDEF=[1 0 0; 2 0 0];
           P.DDEF(1,2:3)=obj.query('DDEF',1);
           P.DDEF(2,2:3)=obj.query('DDEF',2);
           P.FPOP=[1 0; 2 0];
           P.FPOP(1,:)=obj.query('FPOP',1);
           P.FPOP(2,:)=obj.query('FPOP',2);
           P.OEXP=[1 0 0; 2 0 0];
           P.OEXP(1,2:3)=obj.query('OEXP',1);
           P.OEXP(2,2:3)=obj.query('OEXP',2);
           P.AUXV=zeros(1,4);
           P.AUXV(1)=obj.query('AUXV',1);
           P.AUXV(2)=obj.query('AUXV',2);
           P.AUXV(3)=obj.query('AUXV',3);
           P.AUXV(4)=obj.query('AUXV',4);
           P.OUTX=obj.query('OUTX');
           P.OVRM=obj.query('OVRM');
           P.KCLK=obj.query('KCLK');
           P.ALRM=obj.query('ALRM');
        end        
        
        
        %{
        function [rep] = report(obj)
            rep.phase = obj.get_phase();
            rep.freq = obj.get_ref_freq();
            rep.sensitivity = obj.get_sensitivity();
            rep.timeconstant = obj.get_time_constant();
            rep.filter = str2num(obj.dev.ask('OFSL?'));
            rep.reserve = str2num(obj.dev.ask('RMOD?'));
            rep.input = str2num(obj.dev.ask('ISRC?'));
        end
        %}
        %{
        function check_ranges(obj)
        

            % Check for an overload condition
            found_overload = 0;
            
            while obj.do_check_for_overload()==1
            
                found_overload = 1;
                if obj.increase_sensitivity()~=0    
                    obj.pause_n_time_constants(5);
                else
                    break
                end
                
            end
            
            if found_overload == 0
                
              while obj.do_check_for_underflow()==1    
                if obj.decrease_sensitivity()~=0
                   obj.pause_n_time_constants(5);
                else
                   break
                end
              end
            
            end
            
        end
        
        function pause_n_time_constants(obj,n)
        
            [tc_numeric,~] = obj.convert_tc_to_value(obj.get_oflt());
            pause(tc_numeric * n);
            
        end
        
        function [found_underflow]=do_check_for_underflow(obj)
        
            [full_scale,~]=obj.convert_sens_to_value(obj.get_sens());
            [r,~]=obj.bare_read_rtheta();

            if (r*20) < full_scale
                found_underflow = 1;
            else
                found_underflow = 0;
            end
        end
       
        function [result]=do_check_for_overload(obj)
            reply = obj.dev.ask('LIAS?');
            lias = sscanf(reply,'%d');
            result = (bitand(lias,4)==4);
            
        end
        
        function [x,y] = read_xy(obj)
            obj.check_ranges();
            [x,y] = bare_read_xy(obj);
        end
        
        function [x,y] = bare_read_xy(obj)
            result = obj.dev.ask('SNAP? 1,2');
            [a,b]=strtok(result,',');
            b=b(2:end);
            x=str2num(a);
            y=str2num(b);
        end
        
        function [r,theta] = read_rtheta(obj)
            obj.check_ranges();
            [r,theta] = bare_read_rtheta(obj);
        end
        
        function [r,theta] = bare_read_rtheta(obj)
            result = obj.dev.ask('SNAP? 3,4');
            [a,b]=strtok(result,',');
            b=b(2:end);
            r=str2num(a);
            theta=str2num(b);
        end

        % read noise
        function [xn,yn] = read_xnyn(obj)
            obj.check_ranges();
            [xn,yn] = bare_read_xnyn(obj);
        end
        
        function [xn,yn] = bare_read_xnyn(obj)
            obj.dev.writef('DDEF 1,2,0'); % set display to noise measurement
            obj.dev.writef('DDEF 2,2,0'); % set display to noise measurement
            xn = str2num(obj.dev.ask('OUTR? 1')); % read display
            yn = str2num(obj.dev.ask('OUTR? 2'));
        end        
        
        function increase_time_constant(obj)
            current_tc = str2num(obj.dev.ask('OFLT ?'));
            if current_tc < 19
                obj.dev.write(sprintf('OFLT %d',current_tc+1));
            end
        end
        
        function decrease_time_constant(obj)
            current_tc = str2num(obj.dev.ask('OFLT ?'));
            if current_tc > 0
                obj.dev.write(sprintf('OFLT %d',current_tc-1));
            end
        end
        
        
        function do_auto_gain(obj)
        
            obj.dev.write('AGAN');
            obj.dev.write('*CLS');
            obj.wait_for_stb_clear();
            
        end
        
        function do_auto_phase(obj)
            
            obj.dev.write('APHS');
            obj.dev.write('*CLS');
            obj.wait_for_stb_clear();
            
        end
               
        function wait_for_stb_clear(obj)
                   
            while (1==1)
        
                stb = obj.dev.serial_poll();
            
                if bitand(stb,2)==0
                    pause(0.1);
                else
                    break;
                end
            end
            
        end
                
        function [result]=increase_sensitivity(obj)
            current_s = str2num(obj.dev.ask('SENS ?'));
            if current_s < 26
                obj.dev.write(sprintf('SENS %d',current_s+1));
                result = 1;
            else 
                result = 0;
            end
        end
        
        function [result]=decrease_sensitivity(obj)
            current_s = str2num(obj.dev.ask('SENS ?'));
            if current_s > 0
                obj.dev.write(sprintf('SENS %d',current_s-1));
                result = 1;
            else
                result = 0;
            end
        end
        
        function set_state(obj,state)
            obj.set_sens(state.sens);
            obj.set_oflt(state.oflt);
            obj.set_phase(state.phase);
        end

        function [obj] = set_ref_ampl(obj,a)
            a = min( [a 5 ] );
            obj.dev.writef('SLVL %g',a);
        end        
        
        function [a] = get_ref_ampl(obj)
            a = str2num(obj.dev.ask('SLVL?'));
        end          
        
        function [obj] = set_ref_freq(obj,f)
            f = min( [ f 102e5 ] );
            obj.dev.writef('FREQ %g',f);
        end
        
        function [ref] = get_ref_freq(obj)
            ref = str2num(obj.dev.ask('FREQ?'));
        end
                
        function [sens] = get_sens(obj)
            sens = str2num(obj.dev.ask('SENS?'));
        end
       
        function [phase] = set_phase(obj,phi)
            obj.dev.writef('PHAS %g',phi);
        end
        
        function [phase] = get_phase(obj)
            phase = str2num(obj.dev.ask('PHAS?'));
        end
        
        function [phase] = set_sens(obj,sens)
            obj.dev.write(sprintf('SENS %g',sens));
        end
        
        function [phase] = set_oflt(obj,oflt)
            obj.dev.write(sprintf('OFLT %g',oflt));
        end
        
        function [oflt] = get_oflt(obj)
            oflt = str2num(obj.dev.ask('OFLT?'));
        end
                
        function [numeric,str_value]=get_sensitivity(obj)
            [numeric,str_value]=obj.convert_sens_to_value(str2num(obj.dev.ask('SENS?')));
        end
        
        function [numeric,str_value]=get_time_constant(obj)
            [numeric,str_value]=obj.convert_tc_to_value(str2num(obj.dev.ask('OFLT?')));
        end
 %}       
    end         
end
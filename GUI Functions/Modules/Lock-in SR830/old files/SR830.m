classdef SR830
    
    properties
        dev
        autorange
    end
    
    methods
        
        function [obj] = SR830(n,autorange)
            
            if ~exist('n','var')
                n='SR830A';
            end
            
            if ~exist('autorange','var')
                autorange = 0;
            end
            
            %fprintf('Using name = %s\n',n);
            obj.dev = gpibio(1,n,0,13,1,0);
            obj.autorange = autorange;
            %obj.dev.interface_clear();
            pause(0.1);
            
            obj.clear();
            reply = obj.dev.ask('*IDN?');
            
            if length(reply) < 5
                error(sprintf('*IDN? replies with %s - Please check the Stanford lock-in is plugged into the computer via GPIB\n',reply));
            else
                disp(reply);
            end
            reply = obj.dev.ask('*IDN?');
        end
        
        function check_ranges(obj)
        
            % Skip this if running old code
            if obj.autorange == 0
                return
            end
            
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

        function [result]=reset_buffer(obj)
            reply = obj.dev.write('REST');
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
        
        function auto_gain(obj)
            if obj.autorange ~= 0
                obj.do_auto_gain();
            end
        end
        
        function auto_phase(obj)
            if obj.autorange ~= 0
                obj.do_auto_phase();
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
        
        function [v] = clear(obj,n)
            obj.dev.write('*CLS');        
        end
        
        function [rep] = report(obj)
            rep.phase = obj.get_phase();
            rep.freq = obj.get_ref_freq();
            rep.sensitivity = obj.get_sensitivity();
            rep.timeconstant = obj.get_time_constant();
            rep.filter = str2num(obj.dev.ask('OFSL?'));
            rep.reserve = str2num(obj.dev.ask('RMOD?'));
            rep.input = str2num(obj.dev.ask('ISRC?'));
            rep.offset1 = str2num(obj.dev.ask('OEXP? 1'));
            rep.offset2 = str2num(obj.dev.ask('OEXP? 2'));
            rep.offset3 = str2num(obj.dev.ask('OEXP? 3'));
        end
    end
    
    methods (Static)
        
        function [numeric,str_value]=convert_sens_to_value(s)
            
            str_value='1V';
            
            switch s
                case 0
                    str_value='2nV';
                case 1
                    str_value='5nV';
                case 2
                    str_value='10nV';
                case 3
                    str_value='20nV';
                case 4
                    str_value='50nV';
                case 5
                    str_value='100nV';
                case 6
                    str_value='200nV';
                case 7
                    str_value='500nV';
                case 8
                    str_value='1uV';
                case 9
                    str_value='2uV';
                case 10
                    str_value='5uV';
                case 11
                    str_value='10uV';
                case 12
                    str_value='20uV';
                case 13
                    str_value='50uV';
                case 14
                    str_value='100uV';
                case 15
                    str_value='200uV';
                case 16
                    str_value='500uV';
                case 17
                    str_value='1mV';
                case 18
                    str_value='2mV';
                case 19
                    str_value='5mV';
                case 20
                    str_value='10mV';
                case 21
                    str_value='20mV';
                case 22
                    str_value='50mV';
                case 23
                    str_value='100mV';
                case 24
                    str_value='200mV';
                case 25
                    str_value='500mV';
                case 26
                    str_value='1V';
            end
            s=str_value(1:(end-1));
            
            switch s(end)
                case 'n'
                    numeric=str2num(s(1:(end-1)))*1e-9;
                case 'u'
                    numeric=str2num(s(1:(end-1)))*1e-6;
                case 'm'
                    numeric=str2num(s(1:(end-1)))*1e-3;
                otherwise
                    numeric=str2num(s);
            end
        end
       
        function [numeric,str_value]=convert_tc_to_value(tc)
            
            switch tc
                case 0
                    str_value='10usec';
                    numeric=10e-6;
                case 1
                    str_value='30usec';
                    numeric=30e-6;
                case     2
                    str_value='100usec';
                    numeric=100e-6;
                case     3
                    str_value='300usec';
                    numeric=300e-6;
                case     4
                    str_value='1msec';
                    numeric=1e-3;
                case     5
                    str_value='3msec';
                    numeric=3e-3;
                case     6
                    str_value='10msec';
                    numeric=10e-3;
                case     7
                    str_value='30msec';
                    numeric=30e-3;
                case     8
                    str_value='100msec';
                    numeric=100e-3;
                case     9
                    str_value='300msec';
                    numeric=300e-3;
                case     10
                    str_value='1sec';
                    numeric=1;
                case            11
                    str_value='3sec';
                    numeric=3;
                case             12
                    str_value='10sec';
                    numeric=10;
                case            13
                    str_value= '30sec';
                    numeric=30;
                case            14
                    str_value='100sec';
                    numeric=100;
                case           15
                    str_value='300sec';
                    numeric=300;
                case           16
                    str_value='1ksec';
                    numeric=1e3;
                case          17
                    str_value='3ksec';
                    numeric=3e3;
                case          18
                    str_value='10ksec';
                    numeric=10e3;
                case          19
                    str_value= '30ksec';
                    numeric=30e3;
                otherwise
                    str_value='error';
                    numeric=1;
            end
            
        end
        
    end
    
end
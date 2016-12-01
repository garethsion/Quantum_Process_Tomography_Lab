% gpibio.m
% Copyright Brent Valle 2009
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    For a full copy of the GNU General Public License
%    see .

classdef gpibio < instr
    
    properties 
        buffersize = 10000
        timeout = 13 % timeout
    end % of public properties
    properties (SetAccess = private)
        buffer        % a pointer to the buffer
        ud      = 0   % device descriptor
        ibcnt   = 0   % length of buffer from last read
        ibsta   = 0   % status
        iberr   = 0   % error
    end % of private access properties
    
    methods
        function gpib = set.iberr(gpib, err)
            gpib.iberr = err;
        end
        function gpib = set.ibcnt(gpib, value) 
            gpib.ibcnt = value;
        end
        function gpib = set.ibsta(gpib, value) 
            gpib.ibsta = value;
        end
        function gpib = set.ud(gpib, ud) 
            gpib.ud = ud;
        end
        function gpib = set.buffer(gpib, bufferval) 
            gpib.buffer = bufferval;
        end
    end
    
    methods 
           function gpib_obj = gpibio(varargin) % gpib_obj constructor
                % Creates a gpib object 
                %
                % You will need to load the gpib dll for this code to work. This is
                % accomplished using the following command:
                %
                % loadlibrary('C:\Windows\ni4882.dll','C:\Program Files\National ...
                % Instruments\NI-488.2\Languages\DLL Direct Entry\ni488.h', 'alias' , 'ni4882' );
                %
                % Where you may need to change the paths of the ni4882.dll or ni488.h
                % files according to your installation.
                % Be sure to use the alias option, as Matlab doesn't like the dash in
                % the library name. All gpib methods depend on the library name being
                % 'gpi32'
                
                % Load the ni4882.dll if not already loaded.
                if libisloaded('ni4882')==0
                     try 
                        loadlibrary('C:\Windows\SysWOW64\ni4882.dll',@gpibproto,'alias','ni4882');
                     catch
                        loadlibrary('C:\Windows\SysWOW64\ni4882.dll','C:\Program Files (x86)\National Instruments\Shared\ExternalCompilerSupport\C\include\ni4882.h', 'alias' , 'ni4882' );
                        disp('error loading ni4882.dll from prototype')
                        disp('loading from ni4882.h ...')
                        
                        if ~libisloaded('ni4882')
                            error('failed to load ni4882.dll')
                        end % if
                    end % try
                end 

                % disp('ni4882.dll is loaded')
                
                gpib_obj = gpib_obj@instr('gpib', 'initialized');
                
                switch nargin
                    case 1
                        gpib_obj.ibfind(varargin{1});
                    case 6
                        gpib_obj.ibdev(varargin{1}, varargin{2}, varargin{3}, varargin{4}, varargin{5},  varargin{6});
                end
                
                gpib_obj.buffer=libpointer('voidPtr',[uint8(blanks(gpib_obj.buffersize)) 0]);
                
           end % function gpibio(varargin)
           
                           % set methods
%            function gpib = set.Terminator(gpib,terminator)
%                if ~(strcmpi(terminator,'\r') ||... 
%                     strcmpi(terminator,'\n') ||... 
%                     strcmpi(terminator,'\r\n'))
%                     error('Terminator must be \r, \n, or \r\n')
%                end
%                gpib.Terminator = terminator;
%            end
           function gpib = set.timeout(gpib, tmo)
               gpib.timeout = tmo;
               gpib.ibtmo(tmo)
           end
           function gpib = set.buffersize(gpib, size)
               gpib.buffersize = size;
               gpib.buffer = libpointer('voidPtr',[uint8(blanks(size)) 0]);
           end
           
                             % high level methods
                      buffer = read(gpib) 
                      status = write(gpib, command)
                      

                             % canonical class methods
                         val = get(gpib, propName)
                               display(gpib)
                    function delete(gpib)
                        if gpib.ud > 0
                            gpib.ibonl(0);
                        end
                    end 
                    function close(gpib)
                        if gpib.ud > 0
                            gpib.ibonl(0);
                        end
                    end
                    
                             % ni4882.dll methods
                       value = ibask(gpib, option)
                       ibsta = ibcac(gpib, synchronous)
                       ibsta = ibclr(gpib)
                       ibsta = ibcmd(gpib, command, cnt)
                       ibsta = ibcmda(gpib, command, cnt)
                       ibsta = ibconfig(gpib, option, setting)
                        gpib = ibdev(gpib, brd, pad, sad, tmo, send_eoi, eos)
                       ibsta = ibdma(gpib, dma)
                        gpib = ibfind(gpib, name)
                       ibsta = ibgts(gpib, shadow_handshake)
                       ibsta = ibist(gpib,ist)
                       ibsta = ibonl(gpib, online)
                       ibsta = ibpad(gpib, pad)
                       ibsta = ibpct(gpib)
                       ibsta = ibppc(gpib, configuration)
                       ibsta = ibrd(gpib, cnt)
                       ibsta = ibrda(gpib, cnt)
             [ibsta, result] = ibrpp(gpib)
                       ibsta = ibrsc(gpib, request_control)
        [ibsta, status_byte] = ibrsp(gpib)
                       ibsta = ibrsv(gpib, status_byte)
                       ibsta = ibsad(gpib, sad)
                       ibsta = ibsic(gpib)
                       ibsta = ibsre(gpib, enable)
                       ibsta = ibstop(gpib)
                       ibsta = ibtmo(gpib, timeout)
                       ibsta = ibtrg(gpib)
                       ibsta = ibwait(gpib, status_mask)
                       ibsta = ibwrt(gpib, data, cnt)
                       ibsta = ibwrta(gpib, data, cnt)   
    end % methods
    
    
    methods(Static)
        errcode = codeiberr(gpib,err)
        stacode = codeibsta(gpib,sta)
    end
    
    
end % classdef
     

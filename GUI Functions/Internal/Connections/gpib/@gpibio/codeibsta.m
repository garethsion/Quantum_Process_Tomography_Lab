function stacode =codeibsta(gpib,sta)
    % codeibsta - returns the error mnemonics for a given status code
    % stacode =codeibsta(ibsta)
    %
%     bit     value (hexadecimal)	meaning	used for board/device
%     DCAS	0x1 	DCAS is set when a board receives the device clear command (that is, the SDC or DCL command byte). It is cleared on the next 'traditional' or 'multidevice' function call following ibwait() (with DCAS set in the wait mask), or following a read or write (ibrd(), ibwrt(), Receive(), etc.). The DCAS and DTAS bits will only be set if the event queue is disabled. The event queue may be disabled with ibconfig().	board
%     DTAS	0x2 	DTAS is set when a board has received a device trigger command (that is, the GET command byte). It is cleared on the next 'traditional' or 'multidevice' function call following ibwait() (with DTAS in the wait mask). The DCAS and DTAS bits will only be set if the event queue is disabled. The event queue may be disabled with ibconfig().	board
%     LACS	0x4 	Board is currently addressed as a listener.	board
%     TACS	0x8 	Board is currently addressed as talker.	board
%     ATN 	0x10	The ATN line is asserted.	board
%     CIC 	0x20	Board is controller-in-charge, so it is able to set the ATN line.	board
%     REM 	0x40	Board is in 'remote' state.	board
%     LOK 	0x80	Board is in 'lockout' state.	board
%     CMPL	0x100	I/O operation is complete. Useful for determining when an asynchronous io operation (ibrda(), ibwrta(), etc) has completed.	board or device
%     EVENT	0x200	One or more clear, trigger, or interface clear events have been received, and are available in the event queue (see ibevent()). The EVENT bit will only be set if the event queue is enabled. The event queue may be enabled with ibconfig().	board
%     SPOLL	0x400	If this bit is enabled (see ibconfig()), it is set when the board is serial polled. The SPOLL bit is cleared when the board requests service (see ibrsv()) or you call ibwait() on the board with SPOLL in the wait mask. 	board
%     RQS 	0x800	RQS indicates that the device has requested service, and one or more status bytes are available for reading with ibrsp(). RQS will only be set if you have automatic serial polling enabled (see ibconfig()).	device
%     SRQI	0x1000	SRQI indicates that a device connected to the board is asserting the SRQ line. It is only set if the board is the controller-in-charge. If automatic serial polling is enabled (see ibconfig()), SRQI will generally be cleared, since when a device requests service it will be automatically polled and then unassert SRQ.	board
%     END 	0x2000	END is set if the last io operation ended with the EOI line asserted, and may be set on reception of the end-of-string character. The IbcEndBitIsNormal option of ibconfig() can be used to configure whether or not END should be set on reception of the eos character. 	board or device
%     TIMO	0x4000	TIMO indicates that the last io operation or ibwait() timed out.	board or device
%     ERR 	0x8000	ERR is set if the last 'traditional' or 'multidevice' function call failed. The global variable iberr will be set indicate the cause of the error.	board or device
    
    codes = {'DCAS'; 'DTAS' ; 'LACS'; 'TACS'; 'ATN'; 'CIC'; 'REM'; 'LOK'; 'CMPL'; ...
        'EVENT'; 'SPOLL'; 'RQS'; 'SRQI'; 'END'; 'TIMO'; 'ERR'};
    
    stacode={};
    count = 1;
    
    for i = 1:16
        if (bitget(sta,i) == 1)
            stacode{count} = codes{i};
            count = count+1;
        end
    end
end
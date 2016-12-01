function ibsta = ibcmd(gpib, command, cnt )
%ibcmd -- write command bytes (board)
%ibcmd() writes the command bytes  contained in the array commands  
%to the bus. The number of bytes written from the array is specified by 
%num_bytes. The ud argument is a board descriptor, and the board must be 
%controller-in-charge. Most of the possible command bytes are declared as 
%constants in the header files. In particular, the constants GTL, SDC, 
%PPConfig, GET, TCT, LLO, DCL, PPU, SPE, SPD, UNL, UNT,and PPD are 
%available. Additionally, the inline functions MTA(), MLA(), MSA(), and 
%PPE_byte() are available for producing 'my talk address', 'my listen 
%address', 'my secondary address', and 'parallel poll enable' command 
%bytes respectively.
%
%It is generally not necessary to call ibcmd(). It is provided for advanced
%users who want direct, low-level access to the GPIB bus. 

ibsta = calllib('ni4882', 'ibcmd', gpib.ud, libpointer('voidPtr',[uint8(command) 0]), cnt);
gpib.ibsta = ibsta;
assignin('caller', inputname(1), gpib);
end
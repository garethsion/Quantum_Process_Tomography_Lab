function [Xaxis,Yaxis,signal,main] = ConvertDataUI( varargin )
%PLOTGARII Summary of this function goes here
%   Detailed explanation goes here
 if ~isempty( varargin )

 else
     [filename, pathname] = uigetfile('*.mat', ' Open GARII data file', 'C:\Instruments\GARII\Data');
 end
 file = load([pathname filename]);
 
 main = file.MAIN;
 [Xaxis,Yaxis,signal] = ConvertData(main);
end
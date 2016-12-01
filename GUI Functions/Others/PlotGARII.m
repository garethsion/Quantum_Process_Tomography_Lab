function [ hfig, hplots ] = PlotGARII( varargin )
%PLOTGARII Plot GARII data files
%   varargin{1} = path to file
%   varargin{2} = style of plotting: 1: same figure, 2: separate figures
 if ~isempty( varargin )
    filepath = varargin{1};
    plot_style = varargin{2};
    [pathname,name,ext] = fileparts(filepath);
    filename = [name ext];
    
 else
     [filename, pathname] = uigetfile('*.mat', ' Open GARII data file', 'C:\Instruments\GARII\Data');
     filepath = [pathname filename];
     plot_style = input(sprintf(['Choose plotting style for different measures: \n' ...  
                                 '1: Same figure \n2: Separate figures \nInput: ']));
 end
 file = load(filepath);
 
 main = file.MAIN;
 [Xaxis,Yaxis,signal] = ConvertData(main);
 [Nchannels, ~] = size(signal);
 
 hfig = [];
 hplots = [];
 legendstr = {};
 if size(signal{1,3},2) == 1
     %1D sweep
     hfig = [hfig figure(100);];
     if plot_style == 1
         for cCh = 1:Nchannels
             hp = plot(Xaxis{1,3}, signal{cCh,3});
             hold on
             hplots = [hplots hp];
             %ylabel(signal{1,2})
             legendstr = [legendstr signal{cCh,2}];
         end    
         xlabel(Xaxis{1,2})
         legend(hplots, legendstr)
         title(filename,'interpreter','none');
         axis tight
     elseif plot_style == 2
         for cCh = 1:Nchannels
             figure(99+cCh);
             hp = plot(Xaxis{1,3}, signal{cCh,3});
             hold on
             hplots = [hplots hp];
             ylabel(signal{1,2});
             xlabel(Xaxis{1,2});
             title(filename,'interpreter','none');
             axis tight;
         end    
     else
         error('Wrong input, aborted')
     end
 else
     % 2D sweep
     for cCh = 1:Nchannels
         hfig = [hfig figure()];
         hp = imagesc(Xaxis{1,3}, Yaxis{1,3}, signal{cCh,3}.');
         set(gca, 'YDir', 'normal')
         hplots = [hplots hp];
         xlabel(Xaxis{1,2})
         ylabel(Yaxis{1,2})
         cbar = colorbar;
         ylabel(cbar, signal{cCh,2})
         title(filename,'interpreter','none');
         axis tight
     end
 end
 
end


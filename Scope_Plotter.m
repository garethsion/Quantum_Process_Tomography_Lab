function Scope_Plotter = Scope_Plotter(datax, datai, dataq)
    % Scope_Plotter plots the output seen at the oscilloscope

    % xdata: time axis of the oscilloscope.
    % dataI: array of the in phase channel for all phase_cycles and averages. 
    % This is a FOUR-dimensional array, with dimensions:
    % 1st dim: Array of datapoints from oscilloscope (matches dimensions of 
    %          data)
    % 2nd dim: Parameter (e.g. pulse separation etc.) which was varied - not 
    %          always used, in which case this dimension is just 1
    % 3rd dim: Used for phase-cycling: repeating the same experiment various 
    %          times with simple variants regarding pulse phases/amplitudes
    % 4th dim: Used for averaging 
    % dataQ: as dataI, but for the quadrature channel. 
    
    % PhaseCycle 1: +Z state input, no process
	% PhaseCycle 2: +Z state input, with process
	% PhaseCycle 3: -Z state input, no process
	% PhaseCycle 4: -Z state input, with process
	% PhaseCycle 5: +X state input, no process
	% PhaseCycle 6: +X state input, with process
	% PhaseCycle 7: +Y state input, no process
	% PhaseCycle 8: +Y state input, with process
    
    % For example - plot(xdata, dataI(:, 1, 5, 7))

    g = gausswin(20); % <-- this value determines the width of the smoothing window
    g = g/sum(g);

    figure;
    subplot(2,2,1);
    ZdataI_plus_np = datai(:, 1, 1, 1);
    ZdataQ_plus_np = dataq(:, 1, 1, 1);
    ZdataI_plus_np_smooth = conv(ZdataI_plus_np, g, 'same');
    ZdataQ_plus_np_smooth = conv(ZdataQ_plus_np, g, 'same');
    plot(datax, ZdataI_plus_np_smooth);
    hold on;
    plot(datax, ZdataQ_plus_np_smooth);
    title('+Z State Input - No Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');

    subplot(2,2,2);
    ZdataI_plus_wp = datai(:, 1, 2, 7);
    ZdataQ_plus_wp = dataq(:, 1, 2, 7);
    ZdataI_plus_wp_smooth = conv(ZdataI_plus_wp, g, 'same');
    ZdataQ_plus_wp_smooth = conv(ZdataQ_plus_wp, g, 'same');
    plot(datax, ZdataI_plus_wp_smooth);
    hold on;
    plot(datax, ZdataQ_plus_wp_smooth);
    title('+Z State Input - With Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');

    subplot(2,2,3);
    ZdataI_minus_np = datai(:, 1, 3, 7);
    ZdataQ_minus_np = dataq(:, 1, 3, 7);
    ZdataI_minus_np_smooth = conv(ZdataI_minus_np, g, 'same');
    ZdataQ_minus_np_smooth = conv(ZdataQ_minus_np, g, 'same');
    plot(datax, ZdataI_minus_np_smooth);
    hold on;
    plot(datax, ZdataQ_minus_np_smooth);
    title('-Z State Input - No Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');

    subplot(2,2,4);
    ZdataI_minus_wp = datai(:, 1, 4, 7);
    ZdataQ_minus_wp = dataq(:, 1, 4, 7);
    ZdataI_minus_wp_smooth = conv(ZdataI_minus_wp, g, 'same');
    ZdataQ_minus_wp_smooth = conv(ZdataQ_minus_wp, g, 'same');
    plot(datax, ZdataI_minus_wp_smooth);
    hold on;
    plot(datax, ZdataQ_minus_wp_smooth);
    title('-Z State Input - With Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');

    figure;
    subplot(2,2,1);
    XdataI_plus_np = datai(:, 1, 5, 7);
    XdataQ_plus_np = dataq(:, 1, 5, 7);
    XdataI_plus_np_smooth = conv(XdataI_plus_np, g, 'same');
    XdataQ_plus_np_smooth = conv(XdataQ_plus_np, g, 'same');
    plot(datax, XdataI_plus_np_smooth);
    hold on;
    plot(datax, XdataQ_plus_np_smooth);
    title('+X State Input - No Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');

    subplot(2,2,2);
    XdataI_plus_wp = datai(:, 1, 6, 7);
    XdataQ_plus_wp = dataq(:, 1, 6, 7);
    XdataI_plus_wp_smooth = conv(XdataI_plus_wp, g, 'same');
    XdataQ_plus_wp_smooth = conv(XdataQ_plus_wp, g, 'same');
    plot(datax, XdataI_plus_wp_smooth);
    hold on;
    plot(datax, XdataQ_plus_wp_smooth);
    title('+X State Input - With Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');

    subplot(2,2,3);
    YdataI_plus_np = datai(:, 1, 7, 7);
    YdataQ_plus_np = dataq(:, 1, 7, 7);
    YdataI_plus_np_smooth = conv(YdataI_plus_np, g, 'same');
    YdataQ_plus_np_smooth = conv(YdataQ_plus_np, g, 'same');
    plot(datax, YdataI_plus_np_smooth);
    hold on;
    plot(datax, YdataQ_plus_np_smooth);
    title('+Y State Input - No Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');

    subplot(2,2,4);
    YdataI_plus_wp = datai(:, 1, 8, 7);
    YdataQ_plus_wp = dataq(:, 1, 8, 7);
    YdataI_plus_wp_smooth = conv(YdataI_plus_wp, g, 'same');
    YdataQ_plus_wp_smooth = conv(YdataQ_plus_wp, g, 'same');
    plot(datax, YdataI_plus_wp_smooth);
    hold on;
    plot(datax, YdataQ_plus_wp_smooth);
    title('+Y State Input - With Process');
    legend('IData', 'QData');
    xlabel('Time (secs)');
end
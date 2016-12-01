[Xaxis,Yaxis,signal] = ConvertDataUI()
figure
plot(signal{2,3}-1078,signal{1,3});
axis tight
xlabel('Wavelength-1078 (nm)')
ylabel('Voltage (V)')
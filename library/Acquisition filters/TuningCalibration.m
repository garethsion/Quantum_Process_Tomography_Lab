function data = TuningCalibration(freq,data)

cal = load('TuningCal.mat');
dataCal = interp1(cal.cal.freq,cal.cal.data,freq);
data = data./dataCal;

end


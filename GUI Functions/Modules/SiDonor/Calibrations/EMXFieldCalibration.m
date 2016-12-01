function Bout = EMXFieldCalibration(Bin,flag)
%Fields in T

pp = [-0.000939991690479 1.001387919565878 0.000053524745579];

if(flag == 0)
    %Bin = experiment (X values), Bout = real
    Bout = pp(1)*Bin.^2 + pp(2)*Bin + pp(3);
else
    %Bin = real, Bout = experiment (X values)
    delta = pp(2)^2 - 4*pp(1)*(pp(3)-Bin);
    Bout = (-pp(2) + sqrt(delta))/(2*pp(1));
end

end


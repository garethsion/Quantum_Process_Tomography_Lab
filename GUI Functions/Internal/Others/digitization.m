function RAST = digitization(signalFun,LMS_conv_error,max_RAST,Tend)
%RAST = digitization(signalFun,LMS_conv_error,max_RAST,Tend)
%Discretize such that digitization (aliasing) error < LMSerror
%Output = sampling frequency (RAST)
%Gary Wolfowicz, 06/01/2014

if(Tend == 0)
    RAST = 0;
    return;
end

signalFun = @(t) eval(signalFun);
RAST = max_RAST;

%Compute signal from initial RAST
dt = 1/RAST;
time = 0:dt:Tend-dt;
old_y = signalFun(time);

flag = 1;
while(flag)
    %STARTS FROM BEST AND FIND WORST BEST
    RAST = RAST/2;

    %Compute signal from new RAST
    dt = 1/RAST;
    time = (0:dt:Tend-dt).';
    new_y = signalFun(time);

    new_y2 = repmat(new_y(:,1).',2,1);
    new_y2 = new_y2(:).';
    old_y2 = old_y(1:length(new_y2));

    %Compute LMS error: Best-Worst if variation small(converge) then stop
    LMS_error = abs((new_y2(:) - old_y2(:))./max(old_y2(:),new_y2(:)));
    LMS_error = min(1,LMS_error);
    LMS_error = (LMS_error.'*LMS_error)/length(new_y2);
    
    if(LMS_error > LMS_conv_error)
        flag = 0;
    else
        old_y = new_y;
    end
      
    if(dt > Tend/10)
        break;
    end
end

RAST = RAST*2;

% figure(10)
% dt = 1/RAST;
% time = 0:dt:Tend-dt;
% y = signalFun(time);
% plot(time,y,'+-');
end
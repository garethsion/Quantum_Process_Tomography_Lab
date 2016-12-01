function [ out ] = adaPulse( T,freq0,delta0,phi )

timeT=max(T);
len=length(T);
%Parameters
td=len/4;
tau=len;

% %Freuqency parameters
% freq0=9.76;
% delta0=0.006;

%Amplitude parameters
amp0=1;

% %Phase parameters
% phi=pi;
ts=2*td;


for i=1:len
    
    %Get Frequency
    if i<td
        frequency=freq0 + (delta0/2) * ( cos( (pi*i)/td)+1);
    elseif td<=i && i<(tau-td);
        frequency=freq0;
    else
        frequency=freq0 + (delta0/2) * ( cos( pi*(i-tau+td) / td )-1);
    end
    freqMem(i)=frequency;
    
    %Get Amplitude
    if i<td
        amplitude=(amp0/2) * ( 1 - cos(  (pi*i) / td ) );
    elseif td<=i && i<(tau-td)
        amplitude=amp0;
    else
        amplitude=(amp0/2) * ( 1 + cos(  pi*(i-tau+td)  / td  ) );
    end
    ampMem(i)=amplitude;
        
    %Get Phase
    if i<td
        phase=0;
    elseif td<=i && i<tau/2
        phase= (phi/4)  *  (1   - cos (   2*pi*(i-td)/ts    )   );
    elseif (tau/2)<=i && i<(tau-td)
        phase= (phi/4)  *  (3  -  cos (   2*pi*(i-tau/2)/ts   )    )    +pi;
    else
        phase=2*pi;
    end
    
    phaseMem(i)=phase;
    
    % {
    I(i)=amplitude* cos(+frequency*(T(i)-timeT/2)+phase);
    Q(i)=amplitude* sin(+frequency*(T(i)-timeT/2)+phase);
    
    %}
    
    %{
    complexAmplitude(i) = amplitude + exp(1i*(frequency*T(i)*2*pi+phase));
    I(i) = real(complexAmplitude(i));
    Q(i) = imag(complexAmplitude(i));
    %}
end



out=[I;Q]';


%{
figure(70);clf(70)
plot(T,phaseMem)
    a=1;
%}
end




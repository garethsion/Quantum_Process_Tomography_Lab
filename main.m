%{
    Quantum State and Process Tomography Using Donors in Silicon
    Term 1, Lab 1

    Author: Gareth Siôn Jones
    UCL_ID: UCAPGSJ
    Email: gareth.jones.16@ucl.ac.uk

    Date: 11/11/2016
    Code Version: 4.0
%}

% Load the experimental dataset
file_dir = 'C:\Users\Gareth\Desktop\UCL - MRES Year\Tomography Lab\2016-11-10\';
file_ext = '.mat';

% Build the process matrices for the experimental dataset
XPi_Gate_file_name = '013_StateTomography_XpiGate_8Cycles_7K';
XPiFile = strcat(file_dir, XPi_Gate_file_name, file_ext);

YPi_Gate_file_name = '015_StateTomography_YpiGate_8Cycles_7K';
YPiFile = strcat(file_dir, YPi_Gate_file_name, file_ext);

ZComp_Gate_file_name = '018_StateTomography_ZCompositeGate_8Cycles_7K';
ZCompFile = strcat(file_dir, ZComp_Gate_file_name, file_ext);

TComp_Gate_file_name = '019_StateTomography_TCompositeGate_8Cycles_7K';
TCompFile = strcat(file_dir, TComp_Gate_file_name, file_ext);

HComp_Gate_file_name = '020_StateTomography_HCompositeGate_8Cycles_7K';
HCompFile = strcat(file_dir, HComp_Gate_file_name, file_ext);

ZPiOver2_Gate_file_name = '024_StateTomography_Zpiover2_8Cycles_7K';
Zp2File = strcat(file_dir, ZPiOver2_Gate_file_name, file_ext);

Deco1_file_name = '021_StateTomography_DecoSweep1_8Cycles_7K';
Deco1File = strcat(file_dir, Deco1_file_name, file_ext);

Deco2_file_name = '022_StateTomography_DecoSweep2_8Cycles_7K';
Deco2File = strcat(file_dir, Deco2_file_name, file_ext);

Deco3_file_name = '023_StateTomography_DecoSweep3_8Cycles_7K';
Deco3File = strcat(file_dir, Deco3_file_name, file_ext);

Ada_file_name = '027_Sweep_PulseDuration12000_ProcessTomo_AdaZGate_30MHz';
AdaFile = strcat(file_dir, Ada_file_name, file_ext);

XPiGate_Chi = BuildChi(XPiFile);
YPiGate_Chi = BuildChi(YPiFile);
ZCompGate_Chi = BuildChi(ZCompFile);
TCompGate_Chi = BuildChi(TCompFile);
HCompGate_Chi = BuildChi(HCompFile);
ZPi2Gate_Chi = BuildChi(Zp2File);
Deco1_Chi = BuildChi(Deco1File);
Deco2_Chi = BuildChi(Deco2File);
Deco3_Chi = BuildChi(Deco3File);
Ada_Chi = BuildChi(AdaFile);

%%%%%%%%%%%%%%%%%%%%%%%%%%
% Report Figures
%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(1,2,1);
bar3(real(XPiGate_Chi), 'r');
hold on;
bar3(imag(XPiGate_Chi), 'b');
set(gca,'fontsize',16)
title('X \pi Rotation', 'FontSize', 30);

subplot(1,2,2);
bar3(real(YPiGate_Chi), 'r');
hold on;
bar3(imag(YPiGate_Chi), 'b');
set(gca,'fontsize',16)
title('Y \pi Rotation', 'FontSize', 30);

subplot(2,2,3);
bar3(real(ZCompGate_Chi), 'r');
hold on;
bar3(imag(ZCompGate_Chi), 'b');
set(gca,'fontsize',16)
title('Z \pi Rotation', 'FontSize', 30);

subplot(2,2,4);
bar3(real(HCompGate_Chi), 'r');
hold on;
bar3(imag(HCompGate_Chi), 'b');
set(gca,'fontsize',16)
title('Hadamard Gate', 'FontSize', 30);

%Plot a customised legend, highlighting the seperation of real and imag
h = zeros(2, 1);
h(1) = plot(NaN,NaN,'*r');
h(2) = plot(NaN,NaN,'*b');
legend(h, 'Real', 'Imaginary');

%%%%%%%%%%%%
% Analysis
%%%%%%%%%%%%

% Fidelity
% Perfect X Gate - Apparently 0.9465
PerfectX=zeros(4,4);
PerfectX(2,2) = 1;
PerfectX; 
Fidelity(XPiGate_Chi, PerfectX);

% Perfect Y Gate - Apparently 0.9424
PerfectY=zeros(4,4);
PerfectY(3,3) = 1;
PerfectY; 
Fidelity(YPiGate_Chi, PerfectY);

%Perfect Z Gate
PerfectZ = zeros(4,4);
PerfectZ(4,4) = 1;
PerfectZ;
Fidelity(ZCompGate_Chi, PerfectZ);

%Perfect H Gate
PerfectH = zeros(4,4);
PerfectH(2,2) = 0.5;
PerfectH(4,2) = 0.5;
PerfectH(4,4) = 0.5;
PerfectH(2,4) = 0.5;
PerfectH;
Fidelity(HCompGate_Chi, PerfectH);

%Deco1
PerfectI = zeros(4,4);
PerfectI(1,1) = 1;
PerfectI;
Fidelity(Deco1_Chi, PerfectI);

%Deco2
Fidelity(Deco2_Chi, PerfectI);

%Deco3
Fidelity(Deco3_Chi, PerfectI);

%Adiabatic Fast Passaga
Fidelity(Ada_Chi, PerfectZ);
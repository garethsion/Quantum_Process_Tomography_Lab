%This is a test for running GIC (the experiment graphical interface program) from a script
clear all; %Just clear variables
GIC('PG','AWG','MSO'); %Launch the graphical interface for the matlab instrument control

%%
WebServerGet(2,0);
clear all;
close all;
clc;
a = newfis('Myupdatedfiz'); %generate new fuzzy 

%Add first input Capacity
a = addvar(a,'input','Capacity',[0 10]); %add first input capacity
a = addmf(a,'input',1,'Low','trapmf',[-2.844 -0.6886 0.6886 2.844]); %add membership function of first input
a = addmf(a,'input',1,'Medium','trapmf', [2.82 4.5 5.5 7.167]); %add membership function of first input
a = addmf(a,'input',1,'High','trapmf', [7.156 9.311 10.69 12.84]); %add membership function of first input


%Add second input Capacity
a = addvar(a,'input','Probability Off',[0 10]); %add second input Probability Off
a = addmf(a,'input',2,'Low','trapmf',[0 0 1 3]); %add membership function of second input
a = addmf(a,'input',2,'Medium','trapmf',[2.97 4.404 5.5 7.04]); %add membership function of second input
a = addmf(a,'input',2,'High','trapmf',[7 8 10 10]); %add membership function of second input

%Add third input Capacity
a = addvar(a,'input','Interference ratio',[0 10]); %add third input Interference ratio
a = addmf(a,'input',3,'Low','trapmf',[0 0 1 3]); %add membership function of third input
a = addmf(a,'input',3,'Medium','trapmf',[3.03 4.5 5.5 7.037]); %add membership function of third input
a = addmf(a,'input',3,'High','trapmf',[7 8 10 10]); %add membership function of third input

%Add fourth input Capacity
a = addvar(a,'input','SNR',[0 10]); %add third input SNR
a = addmf(a,'input',4,'Low','trapmf',[0 0 1 3]); %add membership function of fourth input
a = addmf(a,'input',4,'Medium','trapmf', [2.963 4.5 5.5 7]); %add membership function of fourth input
a = addmf(a,'input',4,'High','trapmf',[7 8 10 10]); %add membership function of fourth input

%Add output
a = addvar(a,'output','output',[0 10]); %add output
a = addmf(a,'output',1,'Low','trimf', [0 5 10]); %add membership function of output
a = addmf(a,'output',1,'Medium','trimf',[10 15 20]); %add membership function of output
a = addmf(a,'output',1,'High','trimf', [20 25 30]); %add membership function of output

%Add rules of my system
sys = readfis('Myupdatedfiz');
rule1 =[2 2 1 2 2 1 1];
rule2 = [1 1 2 1 1 1 1];
rulelist = [rule1;rule2];
sys = addrule(sys,rulelist);
showrule(sys)

%Perform fuzzy inference calculations (((use these lines in command window)))
% Output = evalfis([5 6 1 7],sys); you can copy paste this line in command window and enter 4 inputs values to get the result
% If you wanna enter your inputs multiple times you can use the command lines below
Inputs = [5 4 2 5; 
          9 8 2 10;
          1 2 8 3];
%  outputs = evalfis(inputs,sys);    

%Plot the membership functions and rule surface

plotmf(a,'input',1); %Plot the membership function of capacity
figure
plotmf(a,'input',2); %Plot the membership function of Probability Off
figure
plotmf(a,'input',3); %Plot the membership function of Interference ratio
figure
plotmf(a,'input',4); %Plot the membership function of SNR
figure
plotmf(a,'output',1); %Plot the membership function of output
figure

gensurf(sys) %plot rule surface



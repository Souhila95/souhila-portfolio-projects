clear all
clc
lambda = linspace(300,800,100);
x = lambda/555-1;
% h =  6.6260e-34;
% % f = 474000000;
% c = 2.998*10^8;
% % q = 0.02;
% e = 0.02;
% mu = 0.9;
S = exp(-88*(x.^2)+41*(x.^3));;
plot(lambda,S,'k','LineWidth',2')
% fplot(lambda,f,LineSpec)
xlabel('Responsivity(A/W)')
ylabel('Wavelength(nm)')
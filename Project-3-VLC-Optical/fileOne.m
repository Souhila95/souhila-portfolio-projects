clear all
clc
close all
lambda_i = 1120;
lambda = 360:lambda_i;
x = lambda/555-1;
S = exp(-88*(x.^2)+41*(x.^3));%sensitivity eqn proposed by Agarwal
%%%%
% 
% lambda_i = 1120;
% lambda = 360:lambda_i;
% x = lambda/555-1;
% S = exp(-88*(x.^2)+41*(x.^3));%sensitivity eqn proposed by Agarwal
%%%%
plot(lambda,S,'LineWidth',2')
xlabel('wavelength (nm)')
ylabel('luminous efficiency')
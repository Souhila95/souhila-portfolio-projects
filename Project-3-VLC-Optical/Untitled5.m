clear all
clc
lambda = linspace(300,2000,100);
h =  6.6260e-34;
% f = 474000000;
c = 2.998*10^8;
% q = 0.02;
e = 0.02;
mu = 0.9;
f = mu*e*lambda/h*c;
plot(lambda,f)
% fplot(lambda,f,LineSpec)
xlabel('Responsivity(A/W)')
ylabel('Wavelength(nm)')
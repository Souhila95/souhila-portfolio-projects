clear all
clc
% %% introducing the elliptic curve example
% [x,y] = meshgrid(linspace(-2,2,250));
% contour(x,y,y.^2-x.^3+x,'LevelList',0)
% title('Y^2 = X^3-X')
% hold on
%%%%%%
% Define the elliptic curve equation
f = @(x,y) (y.^2 - x.^3 + x);

% Plot the elliptic curve
ezplot(f,[-2,2])
title('affine form')
% Label the axes
xlabel('x');
ylabel('y');
hold on 
%%%%%
% Define the elliptic curve parameters
p = 5;

% Define a point on the curve
x1 = 2;
y1 = 3;

% Define a scalar value for multiplication
k = 3;

% Multiplication
lambda = (y1*k)/(x1*k*k+1);
x3 = mod((lambda^2 - x1 - x1), p);
y3 = mod((lambda*(x1 - x3) - y1), p);
m=[x3,y3];
display(m);

plot(x3,y3,'ro'); 
 hold on
% Squaring
lambda = (3*x1^2+1)/(2*y1);
x4 = mod((lambda^2 - x1 - x1), p);
y4 = mod((lambda*(x1 - x4) - y1), p);
s=[x4,y4];
display(s);
plot(x3,y3,'b*'); 
 hold on
% Inversion
x5 = mod(x1, p);
y5 = mod((-y1), p);
i=[x5,y5];
display(i);
plot(x3,y3,'g+'); 
 hold off
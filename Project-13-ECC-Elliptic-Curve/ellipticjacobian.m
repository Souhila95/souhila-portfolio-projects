
clear all

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
title('jacobian form')
% Label the axes
xlabel('x');
ylabel('y');
hold on 
%%%%%


%%%%%%

% Define the elliptic curve parameters
p = 5;

% Define a point on the curve
x1 = 2;
y1 = 3;
z1 = 1;

% Define a scalar value for multiplication
k = 3;

% Multiplication
lambda = (y1*z1*k)/(x1*z1*z1*k+z1*z1);
x3 = mod((lambda^2 - x1 - x1), p);
y3 = mod((lambda*(x1 - x3) - y1*z1*z1), p);
z3 = mod((y1*z1*k), p);
m2=[x3,y3,z3];
display(m2);
scatter(x3,y3,z3,'ro'); 
 hold on
% Squaring
lambda = (3*x1^2+1)/(2*y1*z1);
x4 = mod((lambda^2 - x1 - x1), p);
y4 = mod((lambda*(x1 - x4) - y1*z1*z1), p);
z4 = mod((y1*z1), p);
s2=[x4,y4,z4];
display(s2);
scatter(x4,y4,z4,'b*'); 
 hold on
% Inversion
x5 = mod((x1*z1^2), p);
y5 = mod((y1*z1^3), p);
z5 = mod(z1, p);
i2=[x5,y5,z5];
display(i2);
scatter(x5,y5,z5,'g+'); 
 hold off
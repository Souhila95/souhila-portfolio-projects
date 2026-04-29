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
title('double-and-add form')
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

% Initialize current point
P = [x1, y1];

% Initialize result point
R = [0, 0];

% Convert scalar to binary
bin_k = de2bi(k);

% Iterate through binary digits
for i = 1:length(bin_k)
    % Double current point
    if bin_k(i) == 1
        % Add current point to result
        lambda = (3*P(1)^2+1)/(2*P(2));
        R(1) = mod((lambda^2 - P(1) - P(1)), p);
        R(2) = mod((lambda*(P(1) - R(1)) - P(2)), p);
    end
    % Update current point
    lambda = (3*P(1)^2+1)/(2*P(2));
    P(1) = mod((lambda^2 - P(1) - P(1)), p);
    P(2) = mod((lambda*(P(1) - P(1)) - P(2)), p);
end

x3 = R(1);
y3 = R(2);
m3=[x3,y3];
display(m3);
plot(x3,y3,'ro'); 
 hold on

%%%%%squaring 

% Define the elliptic curve parameters
p = 5;

% Define a point on the curve
x1 = 2;
y1 = 3;

% Initialize current point
P = [x1, y1];

% Initialize result point
R = [0, 0];

% Iterate through binary digits
for i = 1:2
    % Double current point
    lambda = (3*P(1)^2+1)/(2*P(2));
    P(1) = mod((lambda^2 - P(1) - P(1)), p);
    P(2) = mod((lambda*(P(1) - P(1)) - P(2)), p);
end

x4 = P(1);
y4 = P(2);
s3=[x4,y4];
display(s3);
plot(x4,y4,'b*'); 
 hold on
%%%%%%%inversion

% Define the elliptic curve parameters
p = 5;

% Define a point on the curve
x1 = 2;
y1 = 3;

x5 = mod(x1, p);
y5 = mod((-y1), p);
i3=[x5,y5];
display(i3);
plot(x5,y5,'g+'); 
 hold on
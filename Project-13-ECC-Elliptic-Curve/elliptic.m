% Define the elliptic curve parameters
a = 0;
b = 7;
p = 11;

% Define the two points on the curve
P = [3,4];
Q = [8,5];

% Time the execution of the affine method
tic
% Check if the two points are the same
if P(1) == Q(1) && P(2) == Q(2)
    % The slope is defined as (3*Px^2 + a)/(2*Py)
    m = (3*P(1)^2 + a)/(2*P(2));
else
    % The slope is defined as (Qy-Py)/(Qx-Px)
    m = (Q(2)-P(2))/(Q(1)-P(1));
end

% Calculate the x and y coordinates of the result
Rx = mod(m^2 - P(1) - Q(1),p);
Ry = mod(m*(P(1)-Rx) - P(2),p);

% The result is the point R = (Rx, Ry)
R = [Rx, Ry];
affine_time = toc;

% Time the execution of the Jacobian method
tic
% Define the two points on the curve
P = [3,4,1];
Q = [8,5,1];

% Check if the two points are the same
if P(1) == Q(1) && P(2) == Q(2) && P(3) == Q(3)
    % The slope is defined as (3*Px^2 + a*Pz^4)/(2*Py*Pz^2)
    m = (3*P(1)^2 + a*P(3)^4)/(2*P(2)*P(3)^2);
else
    % The slope is defined as (Qy*Pz^3-Py*Qz^3)/(Qx*Pz^3-Px*Qz^3)
    m = (Q(2)*P(3)^3-P(2)*Q(3)^3)/(Q(1)*P(3)^3-P(1)*Q(3)^3);
end

% Calculate the x and y coordinates of the result
Rx = mod(m^2 - P(1) - Q(1),p);
Rz = mod(P(3)*Q(3)*m,p);
Ry = mod(m*(P(1)-Rx) - P(2),p);

% The result is the point R = (Rx, Ry, Rz)
R = [Rx, Ry, Rz];
jacobian_time = toc;

% Time the execution of the double-and-add method
tic
R=P;

while Q(1) ~= P(1) && Q(2) ~= P(2)
    if Q(1) > P(1)
        R = point_addition(Q,R,a,b,p);
        Q = point_addition(Q,Q,a,b,p);
    else
        R = point_addition(P,R,a,b,p);
P = point_addition(P,P,a,b,p);
end
end
double_and_add_time = toc;

% Compare the execution time of each method
fprintf('Affine method execution time: %f seconds\n',affine_time);
fprintf('Jacobian method execution time: %f seconds\n',jacobian_time);
fprintf('Double-and-add method execution time: %f seconds\n',double_and_add_time);

% Define the point_addition function
function R = point_addition(P,Q,a,b,p)
if P(1) == Q(1) && P(2) == Q(2)
% The slope is defined as (3Px^2 + a)/(2Py)
m = ((3*P(1)^2) + a)/(2*P(2));
else
% The slope is defined as (Qy-Py)/(Qx-Px)
m = (Q(2)-P(2))/(Q(1)-P(1));
end
% Calculate the x and y coordinates of the result
Rx = mod(m^2 - P(1) - Q(1),p);
Ry = mod(m*(P(1)-Rx) - P(2),p);
R = [Rx, Ry];
end

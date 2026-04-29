clear all
% Define the elliptic curve parameters
a = 0;
b = 1;
p = 7; % prime number

% Define the starting point in Jacobian coordinates
x1 = 2;
y1 = 5;
z1 = 1;

% Define the scalar value
k = 3;

% Initialize the counters for multiplications, squarings, and inversions
mult_counter = 0;
square_counter = 0;
inv_counter = 0;

% Perform the point multiplication using the Jacobian method
x3 = mod(x1^2*z1,p);
y3 = mod(y1*z1^3,p);
z3 = mod(x1*y1*z1^2,p);

% Update the counters
mult_counter = mult_counter + 2;
square_counter = square_counter + 1;
inv_counter = inv_counter + 1;

% Convert the point back to affine coordinates
z3_inv = mod(1/z3,p);
x3 = mod(x3*z3_inv^2,p);
y3 = mod(y3*z3_inv^3,p);

% Update the counters
inv_counter = inv_counter + 1;
mult_counter = mult_counter + 2;

% Display the results
disp(['x3 = ', num2str(x3)]);
disp(['y3 = ', num2str(y3)]);
disp(['Number of multiplications: ', num2str(mult_counter)]);
disp(['Number of squarings: ', num2str(square_counter)]);
disp(['Number of inversions: ', num2str(inv_counter)]);
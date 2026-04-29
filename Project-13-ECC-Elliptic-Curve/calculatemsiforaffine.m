% Define the elliptic curve parameters
a = 0;
b = 1;
p = 7; % prime number

% Define the starting point
x1 = 2;
y1 = 5;

% Define the scalar value
k = 3;

% Initialize the counters for multiplications, squarings, and inversions
mult_counter = 0;
square_counter = 0;
inv_counter = 0;

% Perform the point multiplication using the affine method
x3 = (x1^2 - 1) * mod(1/(2*y1),p);
y3 = (x1*(x1 - 1) - y1) * mod(1/(2*x1*y1),p);

% Update the counters
mult_counter = mult_counter + 2;
square_counter = square_counter + 1;
inv_counter = inv_counter + 2;

% Display the results
disp(['x3 = ', num2str(x3)]);
disp(['y3 = ', num2str(y3)]);
disp(['Number of multiplications: ', num2str(mult_counter)]);
disp(['Number of squarings: ', num2str(square_counter)]);
disp(['Number of inversions: ', num2str(inv_counter)]);
clear all
% Define the elliptic curve parameters
a = 0;
b = 1;

% Define the point P
Px = 2;
Py = 3;

% Define the scalar k
k = 5;

% Initialize counters for multiplication, squaring, and inversion
mult_count = 0;
sqr_count = 0;
inv_count = 0;

% Initialize the current point as P
Qx = Px;
Qy = Py;

% Iterate through the binary representation of k
for i = 1:length(dec2bin(k))
    % Check if the current bit is 1
    if bitget(k,i) == 1
        % Perform point addition
        if Qy == 0
            Qx = Inf;
            Qy = Inf;
        else
            if Qx == Px
                lambda = (3*Px^2 + a)/(2*Qy);
            else
                lambda = (Qy - Py)/(Qx - Px);
            end
            Rx = lambda^2 - Px - Qx;
            Ry = lambda*(Px - Rx) - Py;
            Qx = Rx;
            Qy = Ry;
            mult_count = mult_count + 1;
        end
    else
        % Perform point doubling
        if Qy == 0
            Qx = Inf;
            Qy = Inf;
        else
            lambda = (3*Qx^2 + a)/(2*Qy);
            Rx = lambda^2 - 2*Qx;
            Ry = lambda*(Qx - Rx) - Qy;
            Qx = Rx;
            Qy = Ry;
            sqr_count = sqr_count + 1;
        end
    end
end

% Print the final point and the operation counts
disp(['Final point: (' num2str(Qx) ',' num2str(Qy) ')']);
disp(['Multiplication count: ' num2str(mult_count)]);
disp(['Squaring count: ' num2str(sqr_count)]);
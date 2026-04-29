% User-defined settings
use_fixed_number_of_DGs = false; % Set to true to fix the number of DGs, false to let optimization decide
fixed_number_of_DGs = 5;         % Specify the number of DGs if fixed is enabled

% Format: [Bus_ID, Active Power Demand, Reactive Power Demand, DG Power Generation, DG Presence]
bus_data = [ 
    1    0    0    0    0;
    2    100  60   0    0;
    3    90   40   0    0;
    4    120  80   0    0;
    5    60   30   0    0;
    6    60   20   0    0;
    7    200  100  0    0;
    8    200  100  0    0;
    9    60   20   0    0;
    10   60   20   0    0;
    11   60   20   0    0;
    12   60   35   0    0;
    13   50   35   0    0;
    14   60   30   0    0;
    15   80   40   0    0;
    16   50   30   0    0;
    17   50   30   0    0;
    18   80   40   0    0;
    19   90   40   0    0;
    20   60   20   0    0;
    21   90   40   0    0;
    22   60   20   0    0;
    23   200  100  0    0;
    24   200  100  0    0;
    25   60   20   0    0;
    26   60   20   0    0;
    27   200  100  0    0;
    28   200  100  0    0;
    29   40   20   0    0;
    30   60   40   0    0;
    31   0    0    0    0;
    32   0    0    0    0;
    33   0    0    0    0;
    34   0    0    0    0;
    35   0    0    0    0;
    36   0    0    0    0;
    37   0    0    0    0;
    38   0    0    0    0;
];

% Define branch data
bra_data = [
    1    1    2    0.09  0.05;
    2    1    3    0.50  0.25;
    3    2    4    0.37  0.19;
    4    3    5    0.38  0.19;
    5    4    6    0.82  0.71;
    6    5    7    0.19  0.62;
    7    6    8    0.71  2.36;
    8    7    9    1.03  0.74;
    9    8   10    1.05  0.74;
    10  11   12    0.20  0.65;
    11  12   13    0.38  0.12;
    12  13   14    1.47  1.16;
    13  14   15    0.54  0.72;
    14  15   16    0.59  0.53;
    15  16   17    1.29  1.13;
    16  17   18    0.74  0.58;
    17  18   19    1.51  1.36;
    18  19   20    0.96  0.94;
    19  20   21    0.45  1.49;
    20  21   22    0.71  0.94;
    21  22   23    0.45  0.94;
    22  23   24    0.90  0.71;
    23  24   25    0.93  0.71;
    24  25   26    2.04  1.31;
    25  26   27    1.01  0.67;
    26  27   28    0.90  0.94;
    27  28   29    1.08  0.97;
    28  29   30    0.31  0.55;
    29  30   31    1.96  0.53;
    30  31   32    2.01  2.01;
    31  32   33    2.01  2.01;
    32  33   34    2.01  2.01;
    33   34   35    0.50  0.50;
    34   35   36    0.50  0.50;
    35   36   37    0.50  0.50;
    36   37   38    0.50  0.50;
];

% Number of buses
n = size(bus_data, 1);

% Initialize voltage magnitudes and angles
V = ones(n, 1);  % Initial voltage magnitude (p.u.)
theta = zeros(n, 1);  % Initial voltage angles (radians)

% Convert bus power data to per-unit
S_base = 100;  % System base apparent power (MVA)
P = bus_data(:, 2) / S_base;  % Active power in per unit
Q = bus_data(:, 3) / S_base;  % Reactive power in per unit

% Initialize Ybus matrix
Ybus = zeros(n);

% Populate Ybus matrix from branch data
for i = 1:size(bra_data, 1)
    from = bra_data(i, 2);
    to = bra_data(i, 3);
    R = bra_data(i, 4);
    X = bra_data(i, 5);
    Z = R + 1j * X;
    
    % Off-diagonal terms
    Ybus(from, to) = Ybus(from, to) - 1 / Z;
    Ybus(to, from) = Ybus(to, from) - 1 / Z;
    
    % Diagonal terms
    Ybus(from, from) = Ybus(from, from) + 1 / Z;
    Ybus(to, to) = Ybus(to, to) + 1 / Z;
end

% Function to optimize DG placement and minimize power loss with penalties
objective_function = @(DG_params) power_loss_with_penalty(DG_params, Ybus, P, Q, n);

% Define bounds for DG placement (0 to 1 for each bus indicating DG presence, and power generation limits)
lb = [zeros(n, 1); zeros(n, 1)];  % No DGs at all buses initially
ub = [ones(n, 1); 100 * ones(n, 1)];  % Maximum DG at each bus with max power generation of 100 per unit
% Nonlinear constraint function for fixed number of DGs
function [c, ceq] = fixed_dg_constraint(DG_params, fixed_number_of_DGs, n)
    % No inequality constraints (c)
    c = [];
    % Equality constraint: sum of DG_locations must equal fixed_number_of_DGs
    DG_locations = DG_params(1:n);
    ceq = sum(round(DG_locations)) - fixed_number_of_DGs;
end

if use_fixed_number_of_DGs
    nonlcon = @(DG_params) fixed_dg_constraint(DG_params, fixed_number_of_DGs, n);
else
    nonlcon = [];
end


% Set the options for Genetic Algorithm
options = optimoptions('ga', 'MaxGenerations', 100, 'PopulationSize', 50, ...
    'Display', 'iter', 'FunctionTolerance', 1e-6);

% Run the Genetic Algorithm with constraints
[DG_opt, fval] = ga(objective_function, 2 * n, [], [], [], [], lb, ub, nonlcon, options);

% Separate DG locations and power generation from optimization result
DG_locations = DG_opt(1:n);
DG_power = DG_opt(n+1:end);

% Ensure DG_locations and DG_power are column vectors
DG_locations = DG_locations(:);
DG_power = DG_power(:);

% Display results
disp('Optimized DG Locations and Power Generation (per unit):');
optimal_dg_table = array2table([find(round(DG_locations)), DG_power(round(DG_locations) > 0)], ...
    'VariableNames', {'Bus_ID', 'DG_Power'});
disp(optimal_dg_table);

disp('Total Power Loss after Optimization (p.u.):');
disp(fval);

disp('Optimal Number of DGs Used:');
disp(sum(round(DG_locations)));

disp('Buses with DGs Installed:');
disp(find(round(DG_locations)));

% Function to calculate power loss with DGs and penalties
function loss = power_loss_with_penalty(DG_params, Ybus, P, Q, n)
    % Extract DG presence and power generation
    DG_locations = DG_params(1:n);
    DG_power = DG_params(n+1:end);
    
    % Update P and Q with DG power generation
    P_with_DG = P + DG_locations .* DG_power;
    Q_with_DG = Q + DG_locations .* DG_power;
    
    % Solve power flow using Gauss-Seidel
    V = ones(n, 1);  % Initial voltage magnitude
    theta = zeros(n, 1);  % Initial voltage angle
    tolerance = 1e-6;
    max_iter = 100;
    iter = 0;
    
    while iter < max_iter
        V_old = V;
        for i = 1:n
            sum1 = 0;
            for j = 1:n
                if i ~= j
                    sum1 = sum1 + Ybus(i, j) * V(j) * exp(1j * (theta(j) - theta(i)));
                end
            end
            
            % Calculate voltage magnitude and angle using Gauss-Seidel update
            V(i) = (P_with_DG(i) - 1j * Q_with_DG(i) - sum1) / Ybus(i, i);
            theta(i) = angle(V(i));  % Voltage angle
            V(i) = abs(V(i));  % Voltage magnitude
        end
        
        % Check for convergence
        if max(abs(V - V_old)) < tolerance
            break;
        end
        
        iter = iter + 1;
    end
    
    % Calculate the total power loss
    power_loss = 0;
    for i = 1:n
        for j = i+1:n
            power_loss = power_loss + abs(Ybus(i,j)) * (V(i) * V(j)) * (1 - cos(theta(i) - theta(j)));
        end
    end
    
    % Calculate penalties
    budget_penalty = 0.01 * sum(DG_power);  % 0.01 per unit of DG power
    environment_penalty = 0.1 * sum(DG_locations > 0);  % 0.1 penalty per DG used
    
    % Total loss with penalties
    loss = power_loss + budget_penalty + environment_penalty;
end

% Output the DG locations and power
disp('Optimized DG Locations and Power Generation (per unit):');
disp(array2table([DG_locations, DG_power], 'VariableNames', {'DG_Location', 'DG_Power'}));

% Display the total power loss after optimization
disp('Total Power Loss after Optimization (p.u.):');
disp(fval);

% Calculate the total number of DGs placed
num_DGs_used = sum(round(DG_locations));

% Display the total number of DGs used
disp('Optimal Number of DGs Used:');
disp(num_DGs_used);


% Display the optimal DG locations and corresponding power
disp('Optimized DG Locations and Power Generation (per unit):');
optimal_dg_table = array2table([find(round(DG_locations)), DG_power(round(DG_locations) > 0)], ...
    'VariableNames', {'Bus_ID', 'DG_Power'});
disp(optimal_dg_table);

% Display total power loss after optimization
disp('Total Power Loss after Optimization (p.u.):');
disp(fval);

% Display total number of DGs placed and their locations
num_DGs_used = sum(round(DG_locations));
disp('Optimal Number of DGs Used:');
disp(num_DGs_used);

% Display the buses where DGs are installed
disp('Buses with DGs Installed:');
disp(find(round(DG_locations)));


dg_buses = find(round(DG_locations));  % Buses where DGs are installed
dg_powers = DG_power(round(DG_locations) > 0);  % Corresponding DG power generation

figure;
bar(dg_buses, dg_powers);
title('DG Power Generation at Each Bus');
xlabel('Bus ID');
ylabel('DG Power Generation (p.u.)');

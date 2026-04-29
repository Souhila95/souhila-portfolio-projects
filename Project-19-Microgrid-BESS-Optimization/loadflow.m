clc;
clear;
close all;

% --- Simulation Parameters ---
num_buses = 33;              % Number of buses (IEEE 33-bus system)
base_MVA = 100;              % Base power in MVA
base_kV = 12.66;             % Base voltage in kV
tolerance = 1e-4;            % Convergence criterion for load flow
max_iter = 50;               % Maximum iterations for convergence
time_horizon = 24;           % 24-hour simulation

% --- Define Corrected PV Profile ---
% Time vector
hours = 1:24;

% Initialize PV profile
PV_profile = zeros(1, 24);

% Define sunrise and sunset hours
sunrise = 6;
sunset = 18;

% PV generation during daylight hours (sinusoidal)
PV_profile(sunrise:sunset) = sin(pi * (hours(sunrise:sunset) - sunrise) / (sunset - sunrise));

% Normalize PV profile to peak at 1
PV_profile = PV_profile / max(PV_profile);

% --- Load Data ---
load_data = load('loaddata33bus.m');      % Load data: [Bus, P (kW), Q (kVar)]
line_data = load('linedata33bus.m');      % Line data: [From, To, R (ohm), X (ohm)]

% --- Per-Unit Conversion ---
Z_base = (base_kV^2) / base_MVA;          % Base impedance
P_load = load_data(:, 2) / (1000 * base_MVA); % Active power in PU
Q_load = load_data(:, 3) / (1000 * base_MVA); % Reactive power in PU
R = line_data(:, 3) / Z_base;             % Line resistance in PU
X = line_data(:, 4) / Z_base;             % Line reactance in PU

% --- Topology ---
num_branches = size(line_data, 1);
adj_matrix = zeros(num_buses, num_buses);
for i = 1:num_branches
    from = line_data(i, 1);
    to = line_data(i, 2);
    adj_matrix(from, to) = 1;
    adj_matrix(to, from) = 1;
end

% --- Initialize Variables ---
voltages = zeros(num_buses, time_horizon); % Voltage profile over 24 hours
total_grid_power = zeros(1, time_horizon); % Total power from grid
total_pv_power = zeros(1, time_horizon);   % Total PV power
base_voltage = 1;                          % Reference voltage in PU

% --- Load Flow and Simulation Loop ---
for t = 1:time_horizon
    % PV Power Injection (scale by PV profile)
    PV_power = PV_profile(t) * sum(P_load); % PV power in PU
    P_injected = P_load - PV_power / num_buses; % Adjusted load per bus
    Q_injected = Q_load;                     % No change in Q for simplicity

    % Initialize voltages and currents
    V = ones(num_buses, 1) * base_voltage;  % Initial voltage guess
    I_br = zeros(num_branches, 1);          % Branch currents
    iter = 0;                               % Iteration counter
    
    % --- Backward/Forward Sweep ---
    while iter < max_iter
        iter = iter + 1;
        V_old = V;

        % Backward Sweep: Branch Currents
        for i = num_branches:-1:1
            to = line_data(i, 2);
            from = line_data(i, 1);
            I_br(i) = conj(P_injected(to) + 1j * Q_injected(to)) / V(to);
            % Add contributions from downstream branches
            for j = 1:num_branches
                if line_data(j, 1) == to
                    I_br(i) = I_br(i) + I_br(j);
                end
            end
        end

        % Forward Sweep: Update Voltages
        for i = 1:num_branches
            from = line_data(i, 1);
            to = line_data(i, 2);
            V(to) = V(from) - I_br(i) * (R(i) + 1j * X(i));
        end

        % Check Convergence
        if max(abs(V - V_old)) < tolerance
            break;
        end
    end

    % Store Results
    voltages(:, t) = abs(V);                     % Voltage magnitude
    total_grid_power(t) = sum(P_injected) * base_MVA; % Total grid power in MW
    total_pv_power(t) = PV_power * base_MVA;     % Total PV power in MW
end

% --- Visualization ---
time = 1:time_horizon;

% Voltage Profile for All Buses
figure;
plot(time, voltages, 'LineWidth', 1.5);
title('Voltage Profiles Over 24 Hours');
xlabel('Time (hours)');
ylabel('Voltage (PU)');
grid on;
legend(arrayfun(@(x) sprintf('Bus %d', x), 1:num_buses, 'UniformOutput', false));

% Total Grid Power
figure;
plot(time, total_grid_power, '-o', 'LineWidth', 1.5);
title('Total Grid Power Over 24 Hours');
xlabel('Time (hours)');
ylabel('Grid Power (MW)');
grid on;

% Total PV Power
figure;
plot(time, total_pv_power, '-o', 'LineWidth', 1.5);
title('Total PV Power Over 24 Hours');
xlabel('Time (hours)');
ylabel('PV Power (MW)');
grid on;

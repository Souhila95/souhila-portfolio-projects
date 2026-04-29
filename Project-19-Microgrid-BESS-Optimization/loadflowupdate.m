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

total_grid_power = total_grid_power*10;
total_pv_power = total_pv_power*10;


%%%%%%%%%%

hours = length(total_grid_power);

%% Define Parameters  
%% Define Parameters  
T = 24; % Time horizon (hours)
SOC_min = 20; % Minimum SOC
SOC_max = 100; % Maximum SOC
P_BESS_max = 100; % Maximum charge/discharge rate (kW)
kWhrated = 200; % Energy capacity (kWh)
p_chr = 0.00116;  % Cost per kWh for charging the battery
p_dch = 0.0616;  % Cost per kWh for discharging the battery

% Energy Prices
p_offpeak = 0.109; % USD/kWh
p_peak = 0.247; % USD/kWh
p_prepostpeak = 0.158; % USD/kWh

% Define Time-of-Use (ToU) Prices
time_blocks = {'offpeak', 'offpeak', 'offpeak', 'offpeak', 'offpeak', 'offpeak', ...
               'offpeak', 'offpeak', 'offpeak', 'offpeak', 'offpeak', 'offpeak', ...
               'offpeak', 'offpeak', 'offpeak', 'offpeak', 'offpeak', 'prepeak', ...
               'onpeak', 'onpeak', 'onpeak', 'prepeak', 'offpeak', 'offpeak'};

% Assign energy prices based on time blocks
p_energy = zeros(T, 1); % Column vector for energy prices
for i = 1:T
    switch time_blocks{i}
        case 'offpeak'
            p_energy(i) = p_offpeak;
        case 'onpeak'
            p_energy(i) = p_peak;
        case 'prepeak'
            p_energy(i) = p_prepostpeak;
    end
end

hbess = 0.95; % Battery efficiency

% Define the PCC Maximum Power Capacity
SOC_init = 20; % Initial SOC (40%)
P_pcc_max = 150; % Maximum power through PCC in kW
P_import_max = 150; % Maximum import power in kW
P_export_max = 150; % Maximum export power in kW
% Calculate excess PV power
excess_pv_power = total_pv_power - total_grid_power;
excess_pv_power(excess_pv_power < 0) = 0;  

% Battery Parameters
initial_soc = SOC_init;  % Initial state of charge set to 40%

%% Define decision variables
P_grid_import = optimvar('P_grid_import', T, 'LowerBound', 0, 'UpperBound', P_import_max);  % Grid imports
P_grid_export = optimvar('P_grid_export', T, 'LowerBound', 0, 'UpperBound', P_export_max);  % Grid exports
P_battery_charge = optimvar('P_battery_charge', T, 'LowerBound', 0, 'UpperBound', P_BESS_max);  % Battery charging
P_battery_discharge = optimvar('P_battery_discharge', T, 'LowerBound', 0, 'UpperBound', P_BESS_max);  % Battery discharging
SOC = optimvar('SOC', T, 'LowerBound', SOC_min, 'UpperBound', SOC_max);  % State of charge of the battery

% Binary variables for import/export
binary_import = optimvar('binary_import', T, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);  % Binary variable for import
binary_export = optimvar('binary_export', T, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);  % Binary variable for export

% Initialize variables for energy losses as optimization variables
E_loss_charge = optimvar('E_loss_charge', T, 'LowerBound', 0);  % Energy losses during charging
E_loss_discharge = optimvar('E_loss_discharge', T, 'LowerBound', 0);  % Energy losses during discharging
Eloss = optimvar('Eloss', T, 'LowerBound', 0);  % Total energy losses

% PV Curtailment Variable
P_pv_curtail = optimvar('P_pv_curtail', T, 'LowerBound', 0, 'UpperBound', total_pv_power);  % PV curtailment

%% Objective function: Minimize energy cost
objective = sum(p_chr * P_battery_charge + p_dch * P_battery_discharge + p_energy .* P_grid_import - p_energy .* P_grid_export);

% Create the problem object
problem = optimproblem('Objective', objective);

%% Initialize the constraints arrays
equality_constraints = [];   % Array for equality constraints
inequality_constraints = [];  % Array for inequality constraints

%% Energy balance and loss constraints
for t = 1:T
    % Energy balance constraint (equality)
    equality_constraints = [equality_constraints, ...
        P_grid_import(t) + total_pv_power(t) - P_pv_curtail(t) + P_battery_discharge(t) - P_grid_export(t) - P_battery_charge(t) == total_grid_power(t)];

inequality_constraints = [inequality_constraints, binary_import(t) + binary_export(t) <= 1];  % Only one can be 1, the other must be 0
inequality_constraints = [inequality_constraints, P_grid_import(t) <= P_import_max * binary_import(t)];
inequality_constraints = [inequality_constraints, P_grid_export(t) <= P_export_max * binary_export(t)];


    % Ensure that if importing, exporting must be zero
    inequality_constraints = [inequality_constraints, P_grid_import(t) <= P_import_max * binary_import(t)];
    inequality_constraints = [inequality_constraints, P_grid_export(t) <= P_export_max * (1 - binary_import(t))];  
    inequality_constraints = [inequality_constraints, P_grid_export(t) <= P_export_max * binary_export(t)];
    inequality_constraints = [inequality_constraints, P_grid_import(t) <= P_import_max * (1 - binary_export(t))];  

% %% Voltage-based Constraints
% % Voltage thresholds
% V_over = 1.04; % Overvoltage threshold
% V_under = 0.95; % Undervoltage threshold
% 
% % Voltage-based charging and discharging constraints
% for t = 1:T
%     % Charging only when voltage is above 1.04
%     inequality_constraints = [inequality_constraints, ...
%         P_battery_charge(t) <= P_BESS_max * (Vpv(t) >= V_over)];
% 
%     % Discharging only when voltage is below 0.95
%     inequality_constraints = [inequality_constraints, ...
%         P_battery_discharge(t) <= P_BESS_max * (Vpv(t) <= V_under)];
% end


%%%%%%%
    % Total energy losses for the hour (equality)
    equality_constraints = [equality_constraints, Eloss(t) == E_loss_charge(t) + E_loss_discharge(t)];
end

%% Battery state of charge (SOC) constraints (equality)
for t = 2:T
    equality_constraints = [equality_constraints, SOC(t) == SOC(t-1) + ...
        (hbess * P_battery_charge(t-1) / kWhrated * 100) - ...
        (P_battery_discharge(t-1) / kWhrated * 100)];
end

% Initial SOC constraint (equality)
equality_constraints = [equality_constraints, SOC(1) == initial_soc];

% Ensure SOC in the end equals initial SOC
equality_constraints = [equality_constraints, SOC(T) == SOC_init];

%% Add equality and inequality constraints to the problem object
problem.Constraints.Equality = equality_constraints;
problem.Constraints.Inequality = inequality_constraints;

%% Solve the MILP using intlinprog
options = optimoptions('linprog', 'Display', 'iter');
[solution, fval] = solve(problem, 'Options', options);


%% Calculate total energy losses from the optimized values
total_losses = sum(solution.Eloss);  % Total energy losses calculated

% Display the total optimized energy cost and losses
fprintf('Total optimized energy cost: $%.2f\n', fval);
fprintf('Total energy losses throughout the day: %.2f kWh\n', total_losses);

% Calculate energies (kWh)
E_shf = sum(solution.P_battery_charge - solution.P_battery_discharge);  % Energy shifted by battery (charging - discharging)
E_load = sum(total_grid_power);  % Energy load (total demand)
E_import = sum(solution.P_grid_import);  % Energy imported from the grid
E_export = sum(solution.P_grid_export);  % Energy exported to the grid
E_pv = sum(total_pv_power);  % Energy generated by PV

% Display the energy results
fprintf('Total Energy Load (E_load): %.2f kWh\n', E_load);
fprintf('Total Energy Imported from Grid (E_import): %.2f kWh\n', E_import);
fprintf('Total Energy Exported to Grid (E_export): %.2f kWh\n', E_export);
fprintf('Total Energy from PV (E_pv): %.2f kWh\n', E_pv);

%% Plotting Power Balance with Excess PV and PV Power
figure;
hold on;

% Load power 
plot(-total_grid_power, 'b-', 'LineWidth', 1, 'DisplayName', '-P_{load}'); 

% Export power
plot(-solution.P_grid_export, 'ro-', 'LineWidth', 1, 'MarkerSize', 6, 'DisplayName', '-P_{export}'); 

% Import power 
plot(solution.P_grid_import, 'g--', 'LineWidth', 1, 'DisplayName', 'P_{import}');

% Charging power 
plot(-solution.P_battery_charge, 'm-', 'LineWidth', 1, 'DisplayName', 'P_{charge}');

% Discharging power 
stem(solution.P_battery_discharge, 'k-', 'Marker', '^', 'MarkerSize', 6, 'DisplayName', 'P_{discharge}'); 

% PV power output 
plot(total_pv_power, 'c-', 'LineWidth', 1.5, 'DisplayName', 'P_{PV}');  

% Excess PV power (highlighted with yellow area)
%area(hours, excess_pv_power, 'FaceColor', 'yellow', 'DisplayName', 'Excess PV Power', 'FaceAlpha', 0.3);

xlabel('Time (hours)');
ylabel('Power (kW)');
xlim([0 25]);  
%ylim([-max(total_grid_power) max(total_pv_power)]);  % 
legend show;
title('Power Balance Over 24 Hours');
grid on;

%% Plotting State of Charge (SOC)
figure;
hold on;
stairs(solution.SOC / 100, 'b-', 'LineWidth', 1.5, 'DisplayName', 'SOC');

% Min and Max SOC as horizontal lines
yline(SOC_min / 100, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Min SOC');
yline(SOC_max / 100, 'g--', 'LineWidth', 1.5, 'DisplayName', 'Max SOC');

xlabel('Time (hours)');
ylabel('State of Charge');
xlim([0 24]);  
ylim([SOC_min/100, SOC_max/100]);  
title('State of Charge Over 24 Hours');
grid on;
legend show;

%%%%%%%
% --- Voltage Profiles After Optimization ---
voltages_optimized = zeros(num_buses, time_horizon); % Initialize voltage profiles after optimization

for t = 1:time_horizon
    % Adjust power injections based on optimization results
    P_injected = total_grid_power(t) - solution.P_grid_import(t) + solution.P_grid_export(t) ...
                 - solution.P_battery_charge(t) + solution.P_battery_discharge(t) - solution.P_pv_curtail(t);
    P_injected = (P_injected / num_buses) * ones(num_buses, 1); % Distribute equally across buses
    Q_injected = Q_load; % Reactive power remains unchanged

    % Initialize voltages and currents
    V = ones(num_buses, 1) * base_voltage; % Initial voltage guess
    I_br = zeros(num_branches, 1); % Branch currents
    iter = 0; % Iteration counter

    % --- Backward/Forward Sweep for Voltage Calculation ---
    while iter < max_iter
        iter = iter + 1;
        V_old = V;

        % Backward Sweep: Calculate Branch Currents
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

    % Store Optimized Voltage Results
    voltages_optimized(:, t) = abs(V); % Voltage magnitudes
end

% --- Plot Optimized Voltage Profiles ---
figure;
hold on;
for bus = 1:num_buses
    plot(1:time_horizon, voltages_optimized(bus, :), 'LineWidth', 1.5, 'DisplayName', sprintf('Bus %d', bus));
end
title('Voltage Profiles After Optimization Over 24 Hours');
xlabel('Time (hours)');
ylabel('Voltage (PU)');
yline(1.04, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Over-voltage Threshold');
yline(0.95, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Under-voltage Threshold');
legend('show');
grid on;


%%%%%%%ù
% Specify the bus where the BESS is connected
BESS_bus = 5; %  Connect BESS to Bus 5

% --- Voltage Profiles Before Optimization ---
voltages_before = zeros(num_buses, time_horizon); % Initialize voltage profiles

for t = 1:time_horizon
    % PV Power Injection (scale by PV profile)
    PV_power = PV_profile(t) * sum(P_load); % PV power in PU
    P_injected = P_load - PV_power / num_buses; % Adjusted load per bus
    Q_injected = Q_load; % No change in reactive power

    % Initialize voltages and currents
    V = ones(num_buses, 1) * base_voltage; % Initial voltage guess
    I_br = zeros(num_branches, 1); % Branch currents
    iter = 0; % Iteration counter

    % --- Backward/Forward Sweep for Voltage Calculation ---
    while iter < max_iter
        iter = iter + 1;
        V_old = V;

        % Backward Sweep: Calculate Branch Currents
        for i = num_branches:-1:1
            to = line_data(i, 2);
            from = line_data(i, 1);
            I_br(i) = conj(P_injected(to) + 1j * Q_injected(to)) / V(to);
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

    % Store Voltage Results Before Optimization
    voltages_before(:, t) = abs(V); % Voltage magnitudes
end

% --- Voltage Profiles After Optimization ---
voltages_after = zeros(num_buses, time_horizon); % Initialize voltage profiles after optimization

for t = 1:time_horizon
    % Adjust power injections based on optimization results
    P_injected = P_load - PV_power / num_buses; % Base load adjustment
    P_injected(BESS_bus) = P_injected(BESS_bus) - (solution.P_battery_discharge(t) - solution.P_battery_charge(t)) / base_MVA; % Include BESS
    Q_injected = Q_load; % Reactive power remains unchanged

    % Initialize voltages and currents
    V = ones(num_buses, 1) * base_voltage; % Initial voltage guess
    I_br = zeros(num_branches, 1); % Branch currents
    iter = 0; % Iteration counter

    % --- Backward/Forward Sweep for Voltage Calculation ---
    while iter < max_iter
        iter = iter + 1;
        V_old = V;

        % Backward Sweep: Calculate Branch Currents
        for i = num_branches:-1:1
            to = line_data(i, 2);
            from = line_data(i, 1);
            I_br(i) = conj(P_injected(to) + 1j * Q_injected(to)) / V(to);
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

    % Store Voltage Results After Optimization
    voltages_after(:, t) = abs(V); % Voltage magnitudes
end

% --- Plot Voltage Profiles Before and After Optimization ---
figure;
for bus = 1:num_buses
    subplot(2, 1, 1);
    hold on;
    plot(1:time_horizon, voltages_before(bus, :), 'LineWidth', 1.5);
    title('Voltage Profiles Before Optimization');
    xlabel('Time (hours)');
    ylabel('Voltage (PU)');
    grid on;

    subplot(2, 1, 2);
    hold on;
    plot(1:time_horizon, voltages_after(bus, :), 'LineWidth', 1.5);
    title('Voltage Profiles After Optimization after connection to bus 5');
    xlabel('Time (hours)');
    ylabel('Voltage (PU)');
    grid on;
end

% Add Over-voltage and Under-voltage Thresholds
subplot(2, 1, 1);
yline(1.04, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Over-voltage Threshold');
yline(0.95, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Under-voltage Threshold');
legend show;

subplot(2, 1, 2);
yline(1.04, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Over-voltage Threshold');
yline(0.95, 'b--', 'LineWidth', 1.5, 'DisplayName', 'Under-voltage Threshold');
legend show;

%%%%%


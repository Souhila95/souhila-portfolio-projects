% Before running the code, ensure you have YALMIP installed and added to the path

%% Initialize OpenDSS and Run Simulation
DSSObj = actxserver('OpenDSSEngine.DSS');
if ~DSSObj.Start(0)
    error('Unable to start the OpenDSS Engine');
end    

DSSText = DSSObj.Text;
currentPath = pwd;
DSSText.Command = "Compile (" + currentPath + "\microgrid.dss)";
disp('microgrid(1).dss file loaded and compiled successfully.');

DSSText.Command = 'set mode=daily';
DSSText.Command = 'set stepsize=1h';
DSSText.Command = 'set number=24';  % Simulate for 24 hours
DSSText.Command = 'solve';
disp('Simulation completed for 24 hours.');

%% Define Parameters  
T = 24; % Time horizon (hours)
SOC_min = 20; % Minimum SOC
SOC_max = 100; % Maximum SOC
P_BESS_max = 60; % Maximum charge/discharge rate (kW)
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
SOC_init = 40; % Initial SOC (40%)
P_pcc_max = 200; % Maximum power through PCC in kW
P_import_max = 200; % Maximum import power in kW
P_export_max = 200; % Maximum export power in kW

% Load the PV system and grid-to-microgrid data
pv_data = readmatrix('microgrid_Mon_mon_1.csv');  % PV system data
grid_data = readmatrix('microgrid_Mon_gridtomicrogrid_1.csv');  % Grid data

% Extract the hours and power (kVA) columns from both datasets
hours = pv_data(:, 1);  % Time (hours)

% Extract total PV power output (sum of three phases S1, S2, S3 in kVA)
pv_power_s1 = pv_data(:, 3);  % Phase 1 PV power
pv_power_s2 = pv_data(:, 5);  % Phase 2 PV power
pv_power_s3 = pv_data(:, 7);  % Phase 3 PV power
total_pv_power = pv_power_s1 + pv_power_s2 + pv_power_s3;

% Scale the PV generation to simulate a larger capacity
scaling_factor = 1;  % Adjust this factor to simulate larger PV systems
total_pv_power_scaled = total_pv_power * scaling_factor;


% Extract grid power flow (sum of three phases S1, S2, S3 in kVA)
grid_power_s1 = grid_data(:, 3);  % Phase 1 grid power
grid_power_s2 = grid_data(:, 5);  % Phase 2 grid power
grid_power_s3 = grid_data(:, 7);  % Phase 3 grid power
total_grid_power = grid_power_s1 + grid_power_s2 + grid_power_s3;

% Reduce grid demand to simulate load reduction
demand_reduction_factor = 0.75;  % Reduce grid demand by 25%
total_grid_power_reduced = total_grid_power * demand_reduction_factor;

% Calculate excess PV power
excess_pv_power = total_pv_power_scaled - total_grid_power_reduced;
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
P_pv_curtail = optimvar('P_pv_curtail', T, 'LowerBound', 0, 'UpperBound', total_pv_power_scaled);  % PV curtailment

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
        P_grid_import(t) + total_pv_power_scaled(t) - P_pv_curtail(t) + P_battery_discharge(t) - P_grid_export(t) - P_battery_charge(t) == total_grid_power_reduced(t)];
    
    % Constraints for grid import and export
    inequality_constraints = [inequality_constraints, P_grid_import(t) <= P_import_max * binary_import(t)];  
    inequality_constraints = [inequality_constraints, P_grid_export(t) <= P_export_max * binary_export(t)];  
    inequality_constraints = [inequality_constraints, binary_import(t) + binary_export(t) <= 1];  % Cannot import and export simultaneously

    % Ensure that if importing, exporting must be zero
    inequality_constraints = [inequality_constraints, P_grid_import(t) <= P_import_max * binary_import(t)];
    inequality_constraints = [inequality_constraints, P_grid_export(t) <= P_export_max * (1 - binary_import(t))];  
    inequality_constraints = [inequality_constraints, P_grid_export(t) <= P_export_max * binary_export(t)];
    inequality_constraints = [inequality_constraints, P_grid_import(t) <= P_import_max * (1 - binary_export(t))];  

    % Import/Export Mutual Exclusivity Constraints
    inequality_constraints = [inequality_constraints, ...
        P_grid_import(t) <= P_import_max * binary_import(t)];
    inequality_constraints = [inequality_constraints, ...
        P_grid_export(t) <= P_export_max * binary_export(t)];
    inequality_constraints = [inequality_constraints, ...
        binary_import(t) + binary_export(t) <= 1];  % Ensure exclusivity
    
    % Calculate losses during charging and discharging (equality)
    equality_constraints = [equality_constraints, E_loss_charge(t) == P_battery_charge(t) * (1 - hbess)];
    equality_constraints = [equality_constraints, E_loss_discharge(t) == P_battery_discharge(t) * (1 - hbess)];
    
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
options = optimoptions('intlinprog', 'Display', 'iter');
[solution, fval] = solve(problem, 'Options', options);

%% Calculate total energy losses from the optimized values
total_losses = sum(solution.Eloss);  % Total energy losses calculated

% Display the total optimized energy cost and losses
fprintf('Total optimized energy cost: $%.2f\n', fval);
fprintf('Total energy losses throughout the day: %.2f kWh\n', total_losses);

% Calculate energies (kWh)
E_shf = sum(solution.P_battery_charge - solution.P_battery_discharge);  % Energy shifted by battery (charging - discharging)
E_load = sum(total_grid_power_reduced);  % Energy load (total demand)
E_import = sum(solution.P_grid_import);  % Energy imported from the grid
E_export = sum(solution.P_grid_export);  % Energy exported to the grid
E_pv = sum(total_pv_power_scaled);  % Energy generated by PV

% Display the energy results
fprintf('Total Energy Load (E_load): %.2f kWh\n', E_load);
fprintf('Total Energy Imported from Grid (E_import): %.2f kWh\n', E_import);
fprintf('Total Energy Exported to Grid (E_export): %.2f kWh\n', E_export);
fprintf('Total Energy from PV (E_pv): %.2f kWh\n', E_pv);

%% Plotting Power Balance with Excess PV and PV Power
figure;
hold on;

% Load power 
plot(hours, -total_grid_power_reduced, 'b-', 'LineWidth', 1, 'DisplayName', '-P_{load}'); 

% Export power
plot(hours, -solution.P_grid_export, 'ro-', 'LineWidth', 1, 'MarkerSize', 6, 'DisplayName', '-P_{export}'); 

% Import power 
plot(hours, solution.P_grid_import, 'g--', 'LineWidth', 1, 'DisplayName', 'P_{import}');

% Charging power 
plot(hours, -solution.P_battery_charge, 'm-', 'LineWidth', 1, 'DisplayName', 'P_{charge}');

% Discharging power 
stem(hours, solution.P_battery_discharge, 'k-', 'Marker', '^', 'MarkerSize', 6, 'DisplayName', 'P_{discharge}'); 

% PV power output 
plot(hours, total_pv_power_scaled, 'c-', 'LineWidth', 1.5, 'DisplayName', 'P_{PV}');  

% Excess PV power (highlighted with yellow area)
area(hours, excess_pv_power, 'FaceColor', 'yellow', 'DisplayName', 'Excess PV Power', 'FaceAlpha', 0.3);

xlabel('Time (hours)');
ylabel('Power (kW)');
xlim([0 25]);  
ylim([-max(total_grid_power_reduced) max(total_pv_power_scaled)]);  % 
legend show;
title('Power Balance Over 24 Hours');
grid on;

%% Plotting State of Charge (SOC)
figure;
hold on;
stairs(hours, solution.SOC / 100, 'b-', 'LineWidth', 1.5, 'DisplayName', 'SOC');

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

clc
clear all
close all

currentPath = pwd; %get current path to the files and folders
% execute DSSStartup.m to obtain COM access to openDSS
[DSSStartOK, DSSObj, DSSText] = DSSStartup;
if ~DSSStartOK
    return;
end

DSSText.command="Compile ("+currentPath+"\model20210502.dss)"; %compile master.dss file
DSSCircuit=DSSObj.ActiveCircuit;   % use this element to access circuit data
DSSObj.AllowForms = false; 


DSSText.Command="New monitor.TR1 Transformer.XFM1 Terminal=2 mode=1 ppolar=0";
% DSSSolution=DSSCircuit.Solution;
% DSSSolution.Solve;

%Run simulation for 24 hrs, without PV or BESS
DSSText.Command='set mode=daily stepsize=1h number=1';
DSSText.Command="set hour=0";
for i=1:24
    DSSText.Command="solve";
    V1(:,i) = DSSCircuit.AllNodeVmagPUByPhase(1);
    V2(:,i) = DSSCircuit.AllNodeVmagPUByPhase(2);
    V3(:,i) = DSSCircuit.AllNodeVmagPUByPhase(3);
    DSSText.Command="Export monitor TR1";
    TRmonitorFile = DSSText.Result;
    DSSText.Command="CktLosses";
    Ploss_NoPV_NoBESS(i,:) = str2num(DSSText.Result);
    %     DSSText.Command='Export Voltages';
    %     DSSText.Command='Export meter';
    %     DSSText.Command='Export monitor main';
end
Vload=(V1+V2+V3)/3;
rfile=readmatrix(TRmonitorFile);
Ptr_NoPV_NoBESS=sum(rfile(:,[3,5,7]),2);
%% introduce PV system
DSSText.Command="New XYCurve.FatorPvsT npts=4 xarray=[0 25 75 100] yarray=[1.2 1.0 .8 .6]";   % this is to declare P vs T curve for PV
DSSText.Command="New XYCurve.Eff npts=4 xarray=[.1 .2 .4 1.0] yarray=[.86 .9 .93 .97]";       % this is to declate PV efficiency curve
DSSText.Command="New loadshape.IRR npts=24 interval=1 mult=[0 0 0 0 0 0 0.045 0.085 0.504 0.763 0.914 0.906 0.866 0.69 0.604 0.513 0.389 0.239 0.037 0 0 0 0 0]"; % declare irredaiance of the day
DSSText.Command="New Tshape.tempCurve npts=24 interva=1 temp=[28 27 27 27 27 26 27 28 30 31 32 32 32 33 33 33 32 32 32 31 30 30 30 29 28]"; %declare temperature of the day
DSSText.Command="Redirect PVsystem.txt"; % assign PV at each load bus
DSSText.Command="New monitor.pv PVSystem.PV1 mode=1 ppolar=0"; % add monitor to one PV
DSSText.Command='set mode=daily stepsize=1h number=1';

% Run simulation for 24 hrs, with PV
DSSText.Command="set hour=0";
for i=1:24
    DSSText.Command="solve";
     V1(:,i) = DSSCircuit.AllNodeVmagPUByPhase(1);    % get bus voltage for phase - 2
    V2(:,i) = DSSCircuit.AllNodeVmagPUByPhase(2);    % get bus voltage for phase - 2
     V3(:,i) = DSSCircuit.AllNodeVmagPUByPhase(3);    % get bus voltage for phase - 2
     DSSText.Command="Export monitor TR1";
    TRmonitorFile = DSSText.Result;
    DSSText.Command="CktLosses";
    Ploss_NoBESS(i,:) = str2num(DSSText.Result);
end
rfile=readmatrix(TRmonitorFile);
Ptr_NoBESS=sum(rfile(:,[3,5,7]),2);
Vpv=(V1+V2+V3)/3;

% figure % Plot transformer loading
% plot(0:23,Ptr_NoPV_NoBESS);
% hold on
% plot(0:23,Ptr_NoBESS);
total_grid_power=[110 80 86 93 97 120 181 84 73 113 107 111 100 93 120 107 140 174 200 240 134 111 117 168];
 total_pv_power=[0 0 0 0 0 0 0 27 159 240 285 283 271 218 191 163 124 76 0 0 0 0 0 0];
% total_pv_power=Ptr_NoBESS-Ptr_NoPV_NoBESS;
% total_pv_power=abs(total_pv_power);
%total_grid_power=-Ptr_NoPV_NoBESS;
hours=length(total_grid_power);
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
options = optimoptions('linprog', 'Display', 'iter');
[solution, fval] = solve(problem, 'Options', options);

% % Run simulation for 24 hrs, with PV
% DSSText.Command="set hour=0";
% for i=1:24
%     DSSText.Command="solve";
%      V1(:,i) = DSSCircuit.AllNodeVmagPUByPhase(1);    % get bus voltage for phase - 2
%     V2(:,i) = DSSCircuit.AllNodeVmagPUByPhase(2);    % get bus voltage for phase - 2
%      V3(:,i) = DSSCircuit.AllNodeVmagPUByPhase(3);    % get bus voltage for phase - 2
% 
% end
% 
% Vp=(V1+V2+V3)/3;

% for i=1
% % Create a new load shape for battery charging and discharging based on the optimization results
% battery_charge_profile = solution.P_battery_charge;
% battery_discharge_profile = solution.P_battery_discharge;
% 
% % Write these profiles to a text file that OpenDSS can read
% dlmwrite('BatteryChargeProfile.txt', battery_charge_profile, 'delimiter', '\n');
% dlmwrite('BatteryDischargeProfile.txt', battery_discharge_profile, 'delimiter', '\n');
% 
% % Update the OpenDSS model with these new profiles
% DSSText.Command = 'New Loadshape.BatteryCharge npts=24 interval=1 mult=(file=BatteryChargeProfile.txt)';
% DSSText.Command = 'New Loadshape.BatteryDischarge npts=24 interval=1 mult=(file=BatteryDischargeProfile.txt)';
% 
% % Update the storage element to use these profiles
% DSSText.Command = 'Edit Storage.Battery daily=BatteryCharge';
% DSSText.Command = 'Edit Storage.Battery daily=BatteryDisCharge';
% DSSText.Command = 'Solve';
% 
% %Run simulation for 24 hrs, without PV or BESS
% DSSText.Command='set mode=daily stepsize=1h number=1';
% DSSText.Command="set hour=0";
% 
%  DSSText.Command="solve";
%      V1(:,i) = DSSCircuit.AllNodeVmagPUByPhase(1);    % get bus voltage for phase - 2
%     V2(:,i) = DSSCircuit.AllNodeVmagPUByPhase(2);    % get bus voltage for phase - 2
%      V3(:,i) = DSSCircuit.AllNodeVmagPUByPhase(3);    % get bus voltage for phase - 2
% 
% 
% end
% V=(V1+V2+V3)/3;

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


% 

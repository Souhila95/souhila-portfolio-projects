



clc;

% system constants
 %Ts = 10e-9;                 % Sampling time
Ts = 0.00001; 
P = 50e3;                   % Rated power
U = 380;                    % Inverter phase-to-phase voltage
f = 60;                     % grid frequency
fsw = 5e3;                  % switching frequency of inverter                       %active_load_power
SOC_max  = 90 ; 
SOC_min = 20; 

% /////////////////////////////////////////////////////////////////
% PV power calculations
% pv_unit_power_max = 213.15  in Watt(W)
no_series_PV_units = 14 ;
no_parrell_PV_units = 17 ;
Vpv_out_max = 29 * no_series_PV_units ;   % 406 v in this values
Ipv_out_max = 7.35 * no_parrell_PV_units ; % 124.95 in this values
PV_power_max = Vpv_out_max * Ipv_out_max ; % max Power can be got from PV
% //////////////////////////////////////////////////////////////////

% design of boost converter
Vmpp = Vpv_out_max;
V_bus_ref = 800;
Vin = Vmpp;                 % input voltage of boost converter
Vo = V_bus_ref;             % output voltage of boost converter
fsw_boost = 5e3;            % switching frequency of boost converter
D = 1 - (Vin/Vo);
L_bound = ((1-D)^2)*D*(Vo^2)/(2*fsw_boost*P);
L_boost = 10*L_bound;
C_boost_min = (D*P)/(0.01*Vo^2*fsw_boost);
C_boost = 1000e-6;
%////////////////////////////////////////////////////////////////////

Lf = ((0.1*U^2)/(2*pi*f*(P/3))); % inverter feletr 


%%%%
% Load the data from the Excel file
%filename = 'solar_irradiance_and_tempreture_load.xlsx';

% Load the data from the Excel file
%filename = 'testdata2.xlsx';
%filename = 'file.xlsx'; 
filename = 'mpptdata.xlsx'; 
% Read the table from the Excel file
data = readtable(filename);

% Time_hours = data.Time_(hours);
Solar_Irradiance = data.Solar_Irradiance;
Temperature = data.Temperature;
numericIrradiance = cellfun(@str2double, Solar_Irradiance);
numericTemperature = cellfun(@str2double, Temperature);

% Display the variables for verification
%disp('Time (hours):'); disp(Time_hours);
disp('Solar Irradiance:'); disp(numericIrradiance);
disp('Temperature:'); disp(numericTemperature);


%%%%%%

% % Load the data from the Excel file
% filename1 = 'PV Output Data in W.xlsx';
% 
% % Read the table from the Excel file
% data = readtable(filename1);
% pv_power = data{:, 1}; 
% 
% % Load the data from the Excel file
% filename2 = 'Load_2024_hourly.csv';
% 
% % Read the table from the Excel file
% data = readtable(filename2);
% load_Power = data{:, 2}; 

%%%%%%%


% simOut = sim('Full_Grid');
% loggedData = simOut.logsout; % Retrieve logged signals
% simOut = sim('Full_Grid');
% loggedData = simOut.logsout; % Retrieve logged signals
% 
% simOut = sim('Full_Grid');
% loggedData = BatOut.logsout; % Retrieve logged signals
% 
% time = out.batsoc.time;        % Extract time vector
% data = out.batsoc.signals.values; % Extract signal values




%downsampled_data = Vpvsimulink(1:1000:end); % Logs every 10th point




clc;

% system constants
 %Ts = 10e-9;                 % Sampling time
Ts = 0.0001; 
P = 50e3;                   % Rated power
U = 380;                    % Inverter phase-to-phase voltage
f = 60;                     % grid frequency
fsw = 5e3;                  % switching frequency of inverter                       %active_load_power

% /////////////////////////////////////////////////////////////////
% PV power calculations
% pv_unit_power_max = 213.15  in Watt(W)
no_series_PV_units = 14 ;
no_parrell_PV_units = 1 ;
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

%filename = 'mpptdata.xlsx'; 
filename = 'august.xlsx'; 
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


% %downsampling the data
% 
% dutydata = duty_data(1:1000:end);
% 
% Idata = I_data(1:1000:end);
% Vdata = V_data(1:1000:end);


%%% preparing data to use in ANN simulink 

% % Extract data only
I_data = out.I.Data;       % Current values
V_data = out.V.Data;       % Voltage values
% duty_data = out.duty.Data; % Duty cycle values  % Extract time and data
% I_time = out.I.Time;       % Time for current
% I_data = out.I.Data;       % Current values
% 
% V_time = out.V.Time;       % Time for voltage
% V_data = out.V.Data;       % Voltage values
% 
% duty_time = out.duty.Time; % Time for duty cycle
% duty_data = out.duty.Data; % Duty cycle values

% %downsampling the data
% 
% dutydata3 = duty_data(1:1000:end);
% 
 Idata = I_data(1:1000:end);
Vdata = V_data(1:1000:end);
% time = V_time(1:1000:end);
% dutytime = duty_time(1:1000:end);
%inputs = [time,Vdata,Idata];% input vector 
%inputs=inputs';



%%%%

duty_data = out.duty1.Data;
% duty_data = out.duty.Data;
dutydata = duty_data(1:1000:end);
I_data = out.I.Data;       % Current values
V_data = out.V.Data;       % Voltage values
Idata = I_data(1:1000:end);
Vdata = V_data(1:1000:end);
I_time = out.I.Time;
time = I_time(1:1000:end);

V_inputs= [time,Vdata] ;
I_inputs= [time,Idata] ;
Time= [ time,time] ;
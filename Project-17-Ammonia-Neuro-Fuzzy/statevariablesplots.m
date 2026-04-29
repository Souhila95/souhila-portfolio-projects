% Generate synthetic historical data for testing
dt = 0.1;
time = (0:dt:100)'; % Make time a column vector
n = length(time);

% Synthetic data 
T_data = sin(0.1 * time); % Temperature data
Q_data = cos(0.1 * time); % Heater power data
C_data = 0.5 * sin(0.1 * time) + 0.1 * cos(0.1 * time); % Concentration data
F_data = 0.7 * cos(0.1 * time) + 0.3 * sin(0.1 * time); % Flow data
P_data = 0.4 * sin(0.1 * time) + 0.6 * cos(0.1 * time); % Pressure data

% Ensure data is in the correct format 
T_data = T_data(:);
Q_data = Q_data(:);
C_data = C_data(:);
F_data = F_data(:);
P_data = P_data(:);

% Preprocess the data
T_data = (T_data - min(T_data)) / (max(T_data) - min(T_data));
C_data = (C_data - min(C_data)) / (max(C_data) - min(C_data));
Q_data = (Q_data - min(Q_data)) / (max(Q_data) - min(Q_data));
F_data = (F_data - min(F_data)) / (max(F_data) - min(F_data));
P_data = (P_data - min(P_data)) / (max(P_data) - min(P_data));

% Create a new fuzzy inference system
fis = mamfis('Name', 'AmmoniaControl');

% Add input variables with their ranges
fis = addInput(fis, [min(T_data) max(T_data)], 'Name', 'Temperature');
fis = addInput(fis, [min(C_data) max(C_data)], 'Name', 'Concentration');
fis = addInput(fis, [min(Q_data) max(Q_data)], 'Name', 'HeatPower');
fis = addInput(fis, [min(F_data) max(F_data)], 'Name', 'Flow');
fis = addInput(fis, [min(P_data) max(P_data)], 'Name', 'Pressure');

% Add membership functions for each input
fis = addMF(fis, 'Temperature', 'gaussmf', [0.1 0.5], 'Name', 'Low');
fis = addMF(fis, 'Temperature', 'gaussmf', [0.1 0.5], 'Name', 'Medium');
fis = addMF(fis, 'Temperature', 'gaussmf', [0.1 0.5], 'Name', 'High');

fis = addMF(fis, 'Concentration', 'gaussmf', [0.1 0.5], 'Name', 'Low');
fis = addMF(fis, 'Concentration', 'gaussmf', [0.1 0.5], 'Name', 'Medium');
fis = addMF(fis, 'Concentration', 'gaussmf', [0.1 0.5], 'Name', 'High');

fis = addMF(fis, 'HeatPower', 'gaussmf', [0.1 0.5], 'Name', 'Low');
fis = addMF(fis, 'HeatPower', 'gaussmf', [0.1 0.5], 'Name', 'Medium');
fis = addMF(fis, 'HeatPower', 'gaussmf', [0.1 0.5], 'Name', 'High');

fis = addMF(fis, 'Flow', 'gaussmf', [0.1 0.5], 'Name', 'Low');
fis = addMF(fis, 'Flow', 'gaussmf', [0.1 0.5], 'Name', 'Medium');
fis = addMF(fis, 'Flow', 'gaussmf', [0.1 0.5], 'Name', 'High');

fis = addMF(fis, 'Pressure', 'gaussmf', [0.1 0.5], 'Name', 'Low');
fis = addMF(fis, 'Pressure', 'gaussmf', [0.1 0.5], 'Name', 'Medium');
fis = addMF(fis, 'Pressure', 'gaussmf', [0.1 0.5], 'Name', 'High');

% Add output variable
fis = addOutput(fis, [0 1], 'Name', 'ControlSignal');

% Add membership functions for output
fis = addMF(fis, 'ControlSignal', 'gaussmf', [0.1 0.0], 'Name', 'Decrease');
fis = addMF(fis, 'ControlSignal', 'gaussmf', [0.1 0.5], 'Name', 'Maintain');
fis = addMF(fis, 'ControlSignal', 'gaussmf', [0.1 1.0], 'Name', 'Increase');

% Define fuzzy rules
ruleList = [
    "Temperature == Low & Concentration == Low & HeatPower == Low & Flow == Low & Pressure == Low => ControlSignal = Increase"
    "Temperature == Medium & Concentration == Medium & HeatPower == Medium & Flow == Medium & Pressure == Medium => ControlSignal = Maintain"
    "Temperature == High & Concentration == High & HeatPower == High & Flow == High & Pressure == High => ControlSignal = Decrease"
];

fis = addRule(fis, ruleList);

% Display the fuzzy inference system
plotfis(fis);

% Prepare inputs for the simulation
n = length(T_data); % Assuming T_data, C_data, Q_data, F_data, P_data have the same length
initial_conditions = [T_data(1); C_data(1); Q_data(1); F_data(1); P_data(1)];

% Define the step input
step_time = 10; % Time at which step occurs
step_value = 1; % Value of the step
step_input = zeros(n, 1);
step_input(time >= step_time) = step_value; % Apply step change

% Define the combined control signal function
alpha = 0.5; % Weighting factor for combining FIS and NN outputs
u = @(T, C, Q, F, P, step) alpha * evalfis(fis, [T, C, Q, F, P]) + (1 - alpha) * step;

% Differential Equations
dT_dt = @(t, y) a_T * y(1) + b_T * u(y(1), y(2), y(3), y(4), y(5), step_input(round(t/dt) + 1));
dC_dt = @(t, y) a_C * y(2) + b_C * u(y(1), y(2), y(3), y(4), y(5), step_input(round(t/dt) + 1));
dQ_dt = @(t, y) a_Q * y(3) + b_Q * u(y(1), y(2), y(3), y(4), y(5), step_input(round(t/dt) + 1));
dF_dt = @(t, y) a_F * y(4) + b_F * u(y(1), y(2), y(3), y(4), y(5), step_input(round(t/dt) + 1));
dP_dt = @(t, y) a_P * y(5) + b_P * u(y(1), y(2), y(3), y(4), y(5), step_input(round(t/dt) + 1));

% Run the simulation using ode45
[t, y] = ode45(@(t, y) [dT_dt(t, y); dC_dt(t, y); dQ_dt(t, y); dF_dt(t, y); dP_dt(t, y)], time, initial_conditions);

% Plot the simulation results
figure;
subplot(5,1,1); plot(t, y(:,1)); title('Temperature Response'); xlabel('Time'); ylabel('Temperature');
subplot(5,1,2); plot(t, y(:,2)); title('Concentration Response'); xlabel('Time'); ylabel('Concentration');
subplot(5,1,3); plot(t, y(:,3)); title('Heater Power Response'); xlabel('Time'); ylabel('Heater Power');
subplot(5,1,4); plot(t, y(:,4)); title('Flow Response'); xlabel('Time'); ylabel('Flow');
subplot(5,1,5); plot(t, y(:,5)); title('Pressure Response'); xlabel('Time'); ylabel('Pressure');

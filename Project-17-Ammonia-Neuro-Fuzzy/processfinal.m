%Generate synthetic historical data for testing
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

% Plot the synthetic data
figure;
subplot(5,1,1); plot(time, T_data); title('Temperature Data'); xlabel('Time'); ylabel('Temperature');
subplot(5,1,2); plot(time, Q_data); title('Heater Power Data'); xlabel('Time'); ylabel('Power');
subplot(5,1,3); plot(time, C_data); title('Concentration Data'); xlabel('Time'); ylabel('Concentration');
subplot(5,1,4); plot(time, F_data); title('Flow Data'); xlabel('Time'); ylabel('Flow');
subplot(5,1,5); plot(time, P_data); title('Pressure Data'); xlabel('Time'); ylabel('Pressure');

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
% Save the updated FIS for code generation
fisCodeGenData = getFISCodeGenerationData(fis);
save('AmmoniaControlFIS_CG.mat', 'fisCodeGenData');

% Display the fuzzy inference system
plotfis(fis);

% Target data for control signals
n = length(T_data); % Assuming T_data, C_data, Q_data, F_data, P_data have the same length
targets = zeros(1, n);
for i = 1:n
    if T_data(i) > 0.7 && C_data(i) > 0.7 && Q_data(i) > 0.7 && F_data(i) > 0.7 && P_data(i) > 0.7
        targets(i) = 0; % Decrease
    elseif T_data(i) < 0.3 && C_data(i) < 0.3 && Q_data(i) < 0.3 && F_data(i) < 0.3 && P_data(i) < 0.3
        targets(i) = 1; % Increase
    else
        targets(i) = 0.5; % Maintain
    end
end

% Prepare input and target data for the neural network
inputs = [T_data'; C_data'; Q_data'; F_data'; P_data'];
targets = targets;

% Create and train the neural network
net = feedforwardnet(10); % Adjust the number of hidden neurons as needed
net = train(net, inputs, targets);

% View the neural network
view(net);

% Combine Fuzzy Logic and Neural Network
control_signals_nn = net(inputs); % Get control signals from the neural network

% Extract Control Signal Functions
f_FIS = @(T, C, Q, F, P) evalfis(fis, [T, C, Q, F, P]);
f_NN = @(T, C, Q, F, P) net([T; C; Q; F; P]);

% Define the combined control signal function
alpha = 0.5; % Weighting factor for combining FIS and NN outputs
u = @(T, C, Q, F, P) alpha * f_FIS(T, C, Q, F, P) + (1 - alpha) * f_NN(T, C, Q, F, P);

% Parameters for Differential Equation Model
a_T = -0.5; % Process dynamics parameter for T
b_T = 1.0;  % Process input gain for T

a_C = -0.3; % Process dynamics parameter for C
b_C = 0.8;  % Process input gain for C

a_Q = -0.2; % Process dynamics parameter for Q
b_Q = 0.6;  % Process input gain for Q

a_F = -0.4; % Process dynamics parameter for F
b_F = 0.9;  % Process input gain for F

a_P = -0.6; % Process dynamics parameter for P
b_P = 0.7;  % Process input gain for P

% Differential Equations
dT_dt = @(t, T, C, Q, F, P) a_T * T + b_T * u(T, C, Q, F, P);
dC_dt = @(t, T, C, Q, F, P) a_C * C + b_C * u(T, C, Q, F, P);
dQ_dt = @(t, T, C, Q, F, P) a_Q * Q + b_Q * u(T, C, Q, F, P);
dF_dt = @(t, T, C, Q, F, P) a_F * F + b_F * u(T, C, Q, F, P);
dP_dt = @(t, T, C, Q, F, P) a_P * P + b_P * u(T, C, Q, F, P);

% Define the state-space model
A = [a_T 0 0 0 0;
     0 a_C 0 0 0;
     0 0 a_Q 0 0;
     0 0 0 a_F 0;
     0 0 0 0 a_P];

B = [b_T;
     b_C;
     b_Q;
     b_F;
     b_P];

C = eye(5); 
D = zeros(5, 1); 

% Create a state-space model
sys = ss(A, B, C, D);

% Simulate the system
initial_conditions = [T_data(1); C_data(1); Q_data(1); F_data(1); P_data(1)];
t_span = time;
u_fun = @(t) u(T_data(round(t/dt) + 1), C_data(round(t/dt) + 1), Q_data(round(t/dt) + 1), F_data(round(t/dt) + 1), P_data(round(t/dt) + 1)); % Interpolate control signal

% Run the simulation using ode45
[t, y] = ode45(@(t, y) A*y + B*u_fun(t), t_span, initial_conditions);

% Plot the simulation results
figure;
plot(t, y);
legend('Temperature', 'Concengensimgetration', 'Heat Power', 'Flow', 'Pressure');
xlabel('Time');
ylabel('States');
title('Simulation of Ammonia Synthesis Process Control');


% Simulate the system using ode45
[t, y] = ode45(@(t, y) A*y + B*u_fun(t), t_span, initial_conditions);

% Extract temperature response (first state variable)
temperature_response = y(:, 1);

% Generate combined control signal
combined_control_signal = arrayfun(@(t) u_fun(t), t);

% Create a new figure
figure;

% Plot the temperature response in the first subplot
subplot(2, 1, 1);
plot(t, temperature_response, 'b', 'LineWidth', 1.5);
xlabel('Time');
ylabel('Temperature');
title('Temperature Response');
grid on;

% Plot the combined control signal in the second subplot
subplot(2, 1, 2);
plot(t, combined_control_signal, 'r--', 'LineWidth', 1.5);
xlabel('Time');
ylabel('Combined Control Signal');
title('Combined Control Signal');
grid on;


% Plot the simulation results
figure;
subplot(5,1,1); plot(t, y(:,1)); title('Temperature Response'); xlabel('Time'); ylabel('Temperature');
subplot(5,1,2); plot(t, y(:,2)); title('Concentration Response'); xlabel('Time'); ylabel('Concentration');
subplot(5,1,3); plot(t, y(:,3)); title('Heater Power Response'); xlabel('Time'); ylabel('Heater Power');
subplot(5,1,4); plot(t, y(:,4)); title('Flow Response'); xlabel('Time'); ylabel('Flow');
subplot(5,1,5); plot(t, y(:,5)); title('Pressure Response'); xlabel('Time'); ylabel('Pressure');



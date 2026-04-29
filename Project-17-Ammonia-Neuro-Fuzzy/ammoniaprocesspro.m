% Preprocess the data
T_data = (T_data - min(T_data)) / (max(T_data) - min(T_data));
C_data = (C_data - min(C_data)) / (max(C_data) - min(C_data));
Q_data = (Q_data - min(Q_data)) / (max(Q_data) - min(Q_data));

% Create a new fuzzy inference system
fis = mamfis('Name', 'AmmoniaControl');

% Add input variables with their ranges
fis = addInput(fis, [min(T_data) max(T_data)], 'Name', 'Temperature');
fis = addInput(fis, [min(C_data) max(C_data)], 'Name', 'Concentration');
fis = addInput(fis, [min(Q_data) max(Q_data)], 'Name', 'HeatPower');

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

% Add output variable
fis = addOutput(fis, [0 1], 'Name', 'ControlSignal');

% Add membership functions for output
fis = addMF(fis, 'ControlSignal', 'gaussmf', [0.1 0.0], 'Name', 'Decrease');
fis = addMF(fis, 'ControlSignal', 'gaussmf', [0.1 0.5], 'Name', 'Maintain');
fis = addMF(fis, 'ControlSignal', 'gaussmf', [0.1 1.0], 'Name', 'Increase');

% Define fuzzy rules
ruleList = [
    "Temperature == Low & Concentration == Low & HeatPower == Low => ControlSignal = Increase"
    "Temperature == Medium & Concentration == Medium & HeatPower == Medium => ControlSignal = Maintain"
    "Temperature == High & Concentration == High & HeatPower == High => ControlSignal = Decrease"
];

fis = addRule(fis, ruleList);

% Display the fuzzy inference system
plotfis(fis);

% target data for control signals
n = length(T_data); % Assuming T_data, C_data, Q_data have the same length
targets = zeros(1, n);
for i = 1:n
    if T_data(i) > 0.7 && C_data(i) > 0.7 && Q_data(i) > 0.7
        targets(i) = 0; % Decrease
    elseif T_data(i) < 0.3 && C_data(i) < 0.3 && Q_data(i) < 0.3
        targets(i) = 1; % Increase
    else
        targets(i) = 0.5; % Maintain
    end
end

% Prepare input and target data for the neural network
inputs = [T_data'; C_data'; Q_data'];
targets = targets;

% Create and train the neural network
net = feedforwardnet(10); % Adjust the number of hidden neurons as needed
net = train(net, inputs, targets);

% View the neural network
view(net);

% Combine Fuzzy Logic and Neural Network
control_signals_nn = net(inputs); % Get control signals from the neural network

% Extract Control Signal Functions
f_FIS = @(T, C, Q) evalfis(fis, [T, C, Q]);
f_NN = @(T, C, Q) net([T; C; Q]);

% Define the combined control signal function
alpha = 0.5; % Weighting factor for combining FIS and NN outputs
u = @(T, C, Q) alpha * f_FIS(T, C, Q) + (1 - alpha) * f_NN(T, C, Q);

% Parameters for Differential Equation Model
a_T = -0.5; %  process dynamics parameter for T
b_T = 1.0;  %  process input gain for T

a_C = -0.3; %  process dynamics parameter for C
b_C = 0.8;  %  process input gain for C

a_Q = -0.2; %  process dynamics parameter for Q
b_Q = 0.6;  %  process input gain for Q

% Differential Equations
dT_dt = @(t, T, C, Q) a_T * T + b_T * u(T, C, Q);
dC_dt = @(t, T, C, Q) a_C * C + b_C * u(T, C, Q);
dQ_dt = @(t, T, C, Q) a_Q * Q + b_Q * u(T, C, Q);

% Define the system of differential equations
odefun = @(t, Y) [dT_dt(t, Y(1), Y(2), Y(3)); dC_dt(t, Y(1), Y(2), Y(3)); dQ_dt(t, Y(1), Y(2), Y(3))];

% Initial conditions
Y0 = [0.5; 0.5; 0.5]; % Initial values for T, C, and Q

% Simulation time span
time_span = [0 10];

% Solve the system of differential equations
[t, Y] = ode45(odefun, time_span, Y0);

% Extract the results
T = Y(:, 1);
C = Y(:, 2);
Q = Y(:, 3);

% Plot results
figure;
subplot(3, 1, 1);
plot(t, T);
title('Temperature Response over Time');
xlabel('Time (s)');
ylabel('Temperature (T)');
grid on;

subplot(3, 1, 2);
plot(t, C);
title('Concentration Response over Time');
xlabel('Time (s)');
ylabel('Concentration (C)');
grid on;

subplot(3, 1, 3);
plot(t, Q);
title('Heat Power Response over Time');
xlabel('Time (s)');
ylabel('Heat Power (Q)');
grid on;

% Transfer Function Model
s = tf('s');
G_T = b_T / (s - a_T);
G_C = b_C / (s - a_C);
G_Q = b_Q / (s - a_Q);

fprintf('Transfer Function for Temperature:\n');
disp(G_T);

fprintf('Transfer Function for Concentration:\n');
disp(G_C);

fprintf('Transfer Function for Heat Power:\n');
disp(G_Q);

% Display transfer function step responses
figure;
subplot(3, 1, 1);
step(G_T);
title('Transfer Function Step Response for Temperature');
grid on;

subplot(3, 1, 2);
step(G_C);
title('Transfer Function Step Response for Concentration');
grid on;

subplot(3, 1, 3);
step(G_Q);
title('Transfer Function Step Response for Heat Power');
grid on;

% State-Space Representation
A = [a_T 0 0; 0 a_C 0; 0 0 a_Q];
B = [b_T; b_C; b_Q];
C = eye(3);
D = zeros(3, 1);

% State-space model
sys_ss = ss(A, B, C, D);
fprintf('State-Space Representation:\n');
disp(sys_ss);

% Display state-space step responses
figure;
step(sys_ss);
title('State-Space Step Response');
grid on;

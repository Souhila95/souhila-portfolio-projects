%%temperature

% Given temperature data
temperature = [40, 120, 280, 320, 430, 520, 540, 540, 540, 540];

% Ensure temperature data is in the correct format
temperature = temperature(:);

% Synthetic data for other parameters dt = 0.1;
time_syn = (0:dt:100)'; % Synthetic time
n = length(time_syn);

Q_data = cos(0.1 * time_syn); % Heater power data
C_data = 0.5 * sin(0.1 * time_syn) + 0.1 * cos(0.1 * time_syn); % Concentration data
F_data = 0.7 * cos(0.1 * time_syn) + 0.3 * sin(0.1 * time_syn); % Flow data
P_data = 0.4 * sin(0.1 * time_syn) + 0.6 * cos(0.1 * time_syn); % Pressure data

% Ensure data is in the correct format 
Q_data = Q_data(:);
C_data = C_data(:);
F_data = F_data(:);
P_data = P_data(:);

% Normalize the data 
C_data = (C_data - min(C_data)) / (max(C_data) - min(C_data));
Q_data = (Q_data - min(Q_data)) / (max(Q_data) - min(Q_data));
F_data = (F_data - min(F_data)) / (max(F_data) - min(F_data));
P_data = (P_data - min(P_data)) / (max(P_data) - min(P_data));

% Interpolate synthetic data to match the provided time points
time = linspace(0, 100, length(temperature))'; % Create time points for given temperature data
Q_data_interp = interp1(time_syn, Q_data, time);
C_data_interp = interp1(time_syn, C_data, time);
F_data_interp = interp1(time_syn, F_data, time);
P_data_interp = interp1(time_syn, P_data, time);

% Normalize the temperature data
T_data = (temperature - min(temperature)) / (max(temperature) - min(temperature));

% Create a new fuzzy inference system
fis = mamfis('Name', 'AmmoniaControl');

% Add input variables with their ranges
fis = addInput(fis, [min(T_data) max(T_data)], 'Name', 'Temperature');
fis = addInput(fis, [min(C_data_interp) max(C_data_interp)], 'Name', 'Concentration');
fis = addInput(fis, [min(Q_data_interp) max(Q_data_interp)], 'Name', 'HeatPower');
fis = addInput(fis, [min(F_data_interp) max(F_data_interp)], 'Name', 'Flow');
fis = addInput(fis, [min(P_data_interp) max(P_data_interp)], 'Name', 'Pressure');

% Add membership functions for each input
inputs = {'Temperature', 'Concentration', 'HeatPower', 'Flow', 'Pressure'};
for i = 1:length(inputs)
    fis = addMF(fis, inputs{i}, 'gaussmf', [0.1 0.5], 'Name', 'Low');
    fis = addMF(fis, inputs{i}, 'gaussmf', [0.1 0.5], 'Name', 'Medium');
    fis = addMF(fis, inputs{i}, 'gaussmf', [0.1 0.5], 'Name', 'High');
end

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

% Prepare input and target data for the neural network
inputs = [T_data'; C_data_interp'; Q_data_interp'; F_data_interp'; P_data_interp'];
targets = zeros(1, length(T_data));

% Define target control signals based on given conditions
for i = 1:length(T_data)
    if T_data(i) > 0.7 && C_data_interp(i) > 0.7 && Q_data_interp(i) > 0.7 && F_data_interp(i) > 0.7 && P_data_interp(i) > 0.7
        targets(i) = 0; % Decrease
    elseif T_data(i) < 0.3 && C_data_interp(i) < 0.3 && Q_data_interp(i) < 0.3 && F_data_interp(i) < 0.3 && P_data_interp(i) < 0.3
        targets(i) = 1; % Increase
    else
        targets(i) = 0.5; % Maintain
    end
end

% Create and train the neural network
net = feedforwardnet(10); % Adjust the number of hidden neurons as needed
net = train(net, inputs, targets);

% Combine Fuzzy Logic and Neural Network
control_signals_nn = net(inputs); % Get control signals from the neural network

% Apply control signals to the temperature data
adjusted_temperature = temperature; % Copy of the original temperature data
for i = 1:length(control_signals_nn)
    if control_signals_nn(i) < 0.33
        % Decrease temperature
        adjusted_temperature(i) = temperature(i) - 10; % Example decrease value
    elseif control_signals_nn(i) > 0.66
        % Increase temperature
        adjusted_temperature(i) = temperature(i) + 10; % Example increase value
    end
end

% Plot the original and adjusted temperature data
figure;
plot(time, temperature, 'b-', 'LineWidth', 2); hold on;
plot(time, adjusted_temperature, 'r--', 'LineWidth', 2);
xlabel('Time');
ylabel('Temperature');
legend('Original Temperature', 'Adjusted Temperature');
title('Temperature Control Using Combined FIS and Neural Network');
grid on;

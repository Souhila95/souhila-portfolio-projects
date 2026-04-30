%% Step 1: Load and Normalize Data
% Define your data
time_hours = 0:23; % Time in hours
solar_irradiance = [0, 0, 0, 0, 0, 0, 0, 150, 400, 600, 800, 900, 1000, 1050, ...
                    1000, 900, 700, 400, 150, 0, 0, 0, 0, 0]; % Solar irradiance in W/m²
temperature = [28, 27, 27, 26, 25, 25, 26, 28, 31, 34, 37, 39, 41, 42, ...
               43, 42, 40, 37, 34, 32, 31, 30, 29, 28]; % Temperature in °C
active_power = [5, 4, 4, 4, 5, 10, 15, 25, 35, 40, 45, 50, 50, 45, ...
                40, 35, 30, 25, 20, 15, 10, 8, 6, 5]; % Load demand in kW

% Normalize the data to [0, 1]
time_norm = time_hours / max(time_hours);
solar_irradiance_norm = solar_irradiance / max(solar_irradiance);
temperature_norm = (temperature - min(temperature)) / (max(temperature) - min(temperature));
active_power_norm = active_power / max(active_power);

% Combine into a dataset
data = [time_norm', solar_irradiance_norm', temperature_norm', active_power_norm'];

%% Step 2: Define the RL Environment

% Observation space: [Time, Solar Irradiance, Temperature, Active Power Demand, SOC]
obsInfo = rlNumericSpec([5 1], 'LowerLimit', [0; 0; 0; 0; 0], 'UpperLimit', [1; 1; 1; 1; 1]);
obsInfo.Name = 'State';
obsInfo.Description = 'Time, Solar Irradiance, Temperature, Active Power, SOC';

% Action space: Discrete actions (1: Charge, 2: Discharge, 3: Import, 4: Export, 5: Idle)
actInfo = rlFiniteSetSpec([1 2 3 4 5]);
actInfo.Name = 'Action';

% Create the environment
env = rlFunctionEnv(obsInfo, actInfo, @batteryStep, @batteryReset);

%% Step 3: Define the Q-Network for DQN Agent

% Define the Q-network
qNetwork = [
    featureInputLayer(5, 'Normalization', 'none', 'Name', 'state')
    fullyConnectedLayer(64, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(64, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(5, 'Name', 'qValues')]; % One output per action

% Create a critic representation
criticOptions = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);
critic = rlQValueRepresentation(qNetwork, obsInfo, actInfo, ...
    'Observation', {'state'}, criticOptions);

%% Step 4: Create the DQN Agent

agentOptions = rlDQNAgentOptions(...
    'TargetUpdateFrequency', 4, ...
    'ExperienceBufferLength', 1e6, ...
    'DiscountFactor', 0.99, ...
    'MiniBatchSize', 64);

% Configure epsilon-greedy exploration
agentOptions.EpsilonGreedyExploration.EpsilonDecay = 0.01; % Epsilon decay rate
agentOptions.EpsilonGreedyExploration.Epsilon = 1;         % Initial epsilon
agentOptions.EpsilonGreedyExploration.EpsilonMin = 0.1;    % Minimum epsilon

agent = rlDQNAgent(critic, agentOptions);

%% Step 5: Train the DQN Agent

trainOpts = rlTrainingOptions(...
    'MaxEpisodes', 500, ...
    'MaxStepsPerEpisode', 24, ...
    'StopTrainingCriteria', 'AverageReward', ...
    'StopTrainingValue', 200, ...
    'ScoreAveragingWindowLength', 10, ...
    'Verbose', true, ...
    'Plots', 'training-progress');

trainingStats = train(agent, env, trainOpts);

%% Step 6: Save the Trained Agent
save('trainedDQNAgent.mat', 'agent');

%% Environment Functions

% Step function
function [nextObs, reward, isDone, loggedSignals] = batteryStep(action, loggedSignals)
    % Extract logged signals
    time = loggedSignals.time;
    solarIrradiance = loggedSignals.solarIrradiance;
    temperature = loggedSignals.temperature;
    activePower = loggedSignals.activePower;
    soc = loggedSignals.soc;

    % Define battery parameters
    SOC_min = 0.2;
    SOC_max = 1.0;
    batteryCapacity = 50; % kWh
    efficiency = 0.95; % Charging/discharging efficiency

    % Define actions: Charge, Discharge, Import, Export, Idle
    switch action
        case 1 % Charge
            batteryPower = 10; % Charging power in kW
            gridPower = 0;
        case 2 % Discharge
            batteryPower = -10; % Discharging power in kW
            gridPower = 0;
        case 3 % Import
            batteryPower = 0;
            gridPower = 10; % Importing power from grid
        case 4 % Export
            batteryPower = 0;
            gridPower = -10; % Exporting power to grid
        otherwise % Idle
            batteryPower = 0;
            gridPower = 0;
    end

    % Update SOC
    soc = soc + (batteryPower / batteryCapacity) * efficiency;
    soc = max(min(soc, SOC_max), SOC_min); % Clamp SOC

    % Calculate reward
    netPower = solarIrradiance + batteryPower + gridPower - activePower;
    reward = -abs(netPower); % Reward closer to zero imbalance

    % Check terminal condition (end of the 24-hour cycle)
    isDone = time >= 23;

    % Update time
    time = time + 1;

    % Update observations
    nextObs = [time / 24; solarIrradiance; temperature; activePower; soc];

    % Update logged signals
    loggedSignals.time = time;
    loggedSignals.soc = soc;
end

% Reset function
function [initialObservation, loggedSignals] = batteryReset()
    % Initialize state
    loggedSignals.time = 0; % Start time
    loggedSignals.solarIrradiance = 0.5; % Normalized solar irradiance
    loggedSignals.temperature = 0.5; % Normalized temperature
    loggedSignals.activePower = 0.5; % Normalized load demand
    loggedSignals.soc = 0.5; % Initial SOC (50%)

    % Initial observation
    initialObservation = [0; 0.5; 0.5; 0.5; 0.5];
end

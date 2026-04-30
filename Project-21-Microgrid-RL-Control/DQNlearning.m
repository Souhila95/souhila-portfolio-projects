% Define Observation and Action Spaces
obsInfo = rlNumericSpec([6 1], 'Name', 'Observations');
discreteActions = linspace(-10, 10, 21); % Discretized action space
actInfo = rlFiniteSetSpec(discreteActions, 'Name', 'Battery_controling_current');

% Define Simulink Environment
env = rlSimulinkEnv('Full_Grid', 'Full_Grid/Controller/two', obsInfo, actInfo);
set_param('Full_Grid', 'StopTime', '24'); % Simulate for 24 hours
set_param('Full_Grid', 'Solver', 'FixedStepDiscrete', 'FixedStep', '0.0001');

% Define Q-value Network
qNetwork = [
    featureInputLayer(6, 'Normalization', 'none', 'Name', 'state')
    fullyConnectedLayer(24, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(24, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(numel(discreteActions), 'Name', 'q_output')];

qRepresentationOptions = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);
qRepresentation = rlQValueRepresentation(qNetwork, obsInfo, actInfo, ...
    'Observation', {'state'}, qRepresentationOptions);

% Define DQN Agent Options
agentOptions = rlDQNAgentOptions(...
    'SampleTime', 1, ... % Interaction every 1 hour
    'UseDoubleDQN', true, ...
    'DiscountFactor', 0.99, ...
    'ExperienceBufferLength', 1e6, ...
    'MiniBatchSize', 64);

% Create DQN Agent
agent = rlDQNAgent(qRepresentation, agentOptions);

% Define Training Options
trainingOptions = rlTrainingOptions(...
    'MaxEpisodes', 300, ...
    'MaxStepsPerEpisode', 24, ... % 24 steps (1 per hour)
    'StopTrainingCriteria', 'AverageReward', ...
    'StopTrainingValue', 300, ...
    'ScoreAveragingWindowLength', 10, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'UseParallel', false);

% Train the Agent
trainingStats = train(agent, env, trainingOptions);

% Save the Trained Agent
save('trainedDQNAgent.mat', 'agent');

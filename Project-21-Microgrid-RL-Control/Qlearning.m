% Define Observation and Action Spaces
obsInfo = rlNumericSpec([6 1]); % Six inputs: pv_power, load_power, etc.
obsInfo.Name = 'Observations';

% Define discrete action space (e.g., 21 actions from -10 to 10)
discreteActions = linspace(-10, 10, 21); % Discretized action space
actInfo = rlFiniteSetSpec(discreteActions);
actInfo.Name = 'Battery_controling_current';

% Define Simulink Environment
env = rlSimulinkEnv('Full_Grid', 'Full_Grid/Controller/two', obsInfo, actInfo);
set_param('Full_Grid/Controller/two', 'Agent', 'agent');

% Define Q-value Network (Single Network for Q-learning)
qNetwork = [
    featureInputLayer(6, 'Normalization', 'none', 'Name', 'state')
    fullyConnectedLayer(24, 'Name', 'fc1')
    reluLayer('Name', 'relu1')
    fullyConnectedLayer(24, 'Name', 'fc2')
    reluLayer('Name', 'relu2')
    fullyConnectedLayer(numel(discreteActions), 'Name', 'q_output')]; % Outputs Q-values for all actions

% Define Q-value Representation
qRepresentationOptions = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);

qRepresentation = rlQValueRepresentation(qNetwork, obsInfo, actInfo, ...
    'Observation', {'state'}, qRepresentationOptions);

% Define DQN Agent Options
agentOptions = rlDQNAgentOptions(...
    'SampleTime', 0.1, ...                   % Interaction time with environment
    'UseDoubleDQN', true, ...               % Double DQN for stability
    'DiscountFactor', 0.99, ...             % Discount factor for future rewards
    'ExperienceBufferLength', 1e6, ...      % Size of replay buffer
    'MiniBatchSize', 64, ...                % Batch size for training
    'EpsilonGreedyExploration', struct(...  % Epsilon-greedy exploration strategy
        'Epsilon', 1, ...                   % Initial exploration rate
        'EpsilonDecay', 1e-4, ...           % Rate of decay for epsilon
        'EpsilonMin', 0.01));               % Minimum exploration rate

% Create the DQN Agent
agent = rlDQNAgent(qRepresentation, agentOptions);

% Define Training Options
trainingOptions = rlTrainingOptions(...
    'MaxEpisodes', 300, ...                 % Maximum number of episodes
    'MaxStepsPerEpisode', 100, ...          % Maximum steps per episode
    'StopTrainingCriteria', 'AverageReward', ... % Stopping criteria
    'StopTrainingValue', 300, ...           % Stopping value for the average reward
    'ScoreAveragingWindowLength', 10, ...   % Number of episodes to average reward over
    'Verbose', true, ...                    % Display progress in the Command Window
    'Plots', 'training-progress', ...       % Show training progress plot
    'SaveAgentCriteria', 'EpisodeReward', ... % Save the agent based on reward
    'SaveAgentValue', 200, ...              % Save the agent when reward exceeds this
    'UseParallel', false);                  % Enable or disable parallel computing

% Train the Agent
trainingStats = train(agent, env, trainingOptions);

% Save the Trained Agent
save('trainedDQNAgent.mat', 'agent');

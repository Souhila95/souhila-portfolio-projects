% Define Observation and Action Spaces
obsInfo = rlNumericSpec([6 1]); % Six inputs: pv_power, load_Power, etc.
obsInfo.Name = 'Observations';


actInfo = rlNumericSpec([1 1], 'LowerLimit', -10, 'UpperLimit', 10); % Continuous action
actInfo.Name = 'Battery_controling_current';

% Define Simulink Environment
env = rlSimulinkEnv('Full_Grid', 'Full_Grid/Controller/two', obsInfo, actInfo);
set_param('Full_Grid/Controller/two', 'Agent', 'agent');

% Define the critic network
statePath = [
    featureInputLayer(6, 'Normalization', 'none', 'Name', 'state')  % State input
    fullyConnectedLayer(120, 'Name', 'state_fc1')
    reluLayer('Name', 'state_relu1')
    fullyConnectedLayer(120, 'Name', 'state_fc2')];

actionPath = [
    featureInputLayer(1, 'Normalization', 'none', 'Name', 'action')  % Action input
    fullyConnectedLayer(120, 'Name', 'action_fc1')];

commonPath = [
    additionLayer(2, 'Name', 'add')  % Combine state and action
    reluLayer('Name', 'common_relu')
    fullyConnectedLayer(1, 'Name', 'critic_output')];  % Single output for Q-value

criticNetwork = layerGraph(statePath);
criticNetwork = addLayers(criticNetwork, actionPath);
criticNetwork = addLayers(criticNetwork, commonPath);

criticNetwork = connectLayers(criticNetwork, 'state_fc2', 'add/in1');
criticNetwork = connectLayers(criticNetwork, 'action_fc1', 'add/in2');

criticOptions = rlRepresentationOptions('LearnRate', 1e-3, 'GradientThreshold', 1);

critic = rlQValueRepresentation(criticNetwork, obsInfo, actInfo, ...
    'Observation', {'state'}, 'Action', {'action'}, criticOptions);

% Define the actor network
actorNetwork = [
    featureInputLayer(6, 'Normalization', 'none', 'Name', 'state')  % State input
    fullyConnectedLayer(120, 'Name', 'actor_fc1')
    reluLayer('Name', 'actor_relu1')
    fullyConnectedLayer(120, 'Name', 'actor_fc2')
    reluLayer('Name', 'actor_relu2')
    fullyConnectedLayer(1, 'Name', 'action')];  % Remove tanh layer for unrestricted output

% Scale the actor output to match the expected range
actorScaling = scalingLayer('Name', 'scale', 'Scale', 10); % Scale output to [-10, 10]
actorNetwork = addLayers(layerGraph(actorNetwork), actorScaling);
actorNetwork = connectLayers(actorNetwork, 'action', 'scale/in');

actorOptions = rlRepresentationOptions('LearnRate', 1e-2, 'GradientThreshold', 1);

actor = rlDeterministicActorRepresentation(actorNetwork, obsInfo, actInfo, ...
    'Observation', {'state'}, 'Action', {'scale/out'}, actorOptions);

% % Define Ornstein-Uhlenbeck noise for the agent
% noise = rl.option.OrnsteinUhlenbeckActionNoise(...
%     'Mean', 0, ...                          % Mean of the noise
%     'MeanAttractionConstant', 1, ...        % Pull towards the mean
%     'StandardDeviation', 0.2, ...           % Initial standard deviation
%     'StandardDeviationDecayRate', 1e-5, ... % Decay rate of the standard deviation
%     'StandardDeviationMin', 0.05, ...       % Minimum standard deviation
%     'SampleTime', 1);                   % Sample time for noise update

               % Enable or disable parallel computing

% Create DDPG agent options and set the noise
agentOptions = rlDDPGAgentOptions(...
    'SampleTime', 1, ...
    'DiscountFactor', 0.99, ...
    'MiniBatchSize', 64, ...
    'ExperienceBufferLength', 1e6);


agent = rlDDPGAgent(actor, critic, agentOptions);

% Define Training Options
trainingOptions = rlTrainingOptions(...
    'MaxEpisodes', 300, ...                 % Maximum number of episodes
    'MaxStepsPerEpisode', 24, ...         % Maximum steps per episode
    'StopTrainingCriteria', 'AverageReward', ... % Stopping criteria
    ' StopTrainingValue', 30, ...           % Stopping value for the average reward
    'Verbose', true, ...                    % Display progress in the Command Window
    'Plots', 'training-progress', ...       % Show training progress plot
    'SaveAgentCriteria', 'EpisodeReward', ... % Save the agent based on reward
    'SaveAgentValue', 200, ...              % Save the agent when reward exceeds this
    'UseParallel', false);                  % Enable or disable parallel computing

% Train the Agent
trainingStats = train(agent, env, trainingOptions);

% Save the Trained Agent
save('trainedAgent2.mat', 'agent');

% Create an instance of the UAEnvironment class
env = UAEnvironment();

% Define all possible actions
all_actions = 0:21;  % Assuming there are 22 possible actions (including no movement)

% Initialize array to store UAV coordinates
all_UAV_coordinates = zeros(length(all_actions), env.M * 2);

% Iterate over all actions for each UAV
for action_index = 1:length(all_actions)
    % Set actions for all UAVs
    actions = zeros(1, env.M);  % Initialize actions for all UAVs
    for uav_index = 1:env.M
        % Get the current action
        action = all_actions(action_index);
        actions(uav_index) = action;  % Set action for the current UAV
    end
    
    % Call the step method with the current actions
    [next_state, ~, ~] = env.step(actions);
    
    % Store the UAV coordinates
    all_UAV_coordinates(action_index, :) = next_state';
    
    % Calculate DistanceUAV, TimeUAV, and EnergySN for each sensor and UAV
    for i = 1:env.NSensors
        for j = 1:env.M
            % Calculate distance between sensor i and UAV j
            DistanceUAV(i, j) = sqrt((next_state(j) - env.xALL(i))^2 + (next_state(env.M + j) - env.yALL(i))^2 + (env.uavZ(j))^2);
            
            % Calculate time for UAV j to transmit data from sensor i
            RateUAV = env.B * log2(1 + env.SN_transmitPower * env.Kappa * (env.d0 / DistanceUAV(i, j))^env.alpha / env.sigma2);
            TimeUAV(i, j) = env.SizeArr(i) / RateUAV;
            
            % Calculate energy consumption for communication between sensor i and UAV j
            EnergySN(i, j) = env.SN_transmitPower * TimeUAV(i, j);
        end
    end
    
    % Display the new UAV coordinates
    disp("New UAV Coordinates:");
    disp(next_state);
    
    % Visualize the environment after each step
    env.render();
    
    % Pause for a short duration to observe the visualization
    pause(1);  % Adjust the duration as needed
end



% Display DistanceUAV, TimeUAV, and EnergySN
disp("DistanceUAV:");
disp(DistanceUAV);
disp("TimeUAV:");
disp(TimeUAV);
disp("EnergySN:");
disp(EnergySN);
%%%%%VOI and VOIi information
% Create an instance of the UAEnvironment class
environment = UAEnvironment();

% Define the number of sensors and other parameters as needed
numSensors = env.NSensors;
temperatureBoundary1 = 10;
temperatureBoundary2 = 50;
arraySize = 100; % Or any desired array size

% Call the GenerateRandDataAndTimes method for the first sensor explicitly
sensorData = cell(1, numSensors); % Initialize cell array to store sensor data
timeOfGeneration = cell(1, numSensors); % Initialize cell array to store time of generation

% Define data and time for the first sensor
sensorData{1} = [10 20 30]; % Sensor 1 data
timeOfGeneration{1} = [0 1 2]; % Time of generation for Sensor 1

% Generate random sensor data and time of generation for the rest of the sensors
for i = 2:numSensors
    % Call GenerateRandDataAndTimes for each sensor
    [DataVec, TimeVec, ~] = environment.GenerateRandDataAndTimes([], [], [], 1, temperatureBoundary1, temperatureBoundary2);
    % Assign generated data and time to the respective sensor
    sensorData{i} = DataVec{1};
    timeOfGeneration{i} = TimeVec{1};
end


% Calculate VOI for each sensor
nSensors = numel(sensorData);
VoIi = zeros(1, nSensors);
for i = 1:nSensors
    data = double(sensorData{i}); % Convert data to double
    time = timeOfGeneration{i}; % Time of generation
    n = numel(data); % Number of data points
    VoIi(i) = sum(data.^(0.1 * (0:n-1))); % Calculate VOI for sensor i
end

% Calculate total VOI across all sensors
totalVOI = sum(VoIi); % Sum up VOIi for global sensors
VoI=totalVOI;
% Display individual VOI for each sensor
disp('Individual VOI for each sensor:');
for i = 1:nSensors
    disp(['Sensor ', num2str(i), ' VOI: ', num2str(VoIi(i))]);
end

% % Display total VOI across all sensors
% disp(['Total VOI across all sensors: ', num2str(totalVOI)]);


% Display all UAV coordinates
disp("All UAV Coordinates:");
disp(all_UAV_coordinates);
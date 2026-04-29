%%%%%VOI and VOIi information
% Create an instance of the UAEnvironment class
environment = UAEnvironment();

% Define the number of sensors and other parameters as needed
numSensors = 100;
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

% Display individual VOI for each sensor
disp('Individual VOI for each sensor:');
for i = 1:nSensors
    disp(['Sensor ', num2str(i), ' VOI: ', num2str(VoIi(i))]);
end

% Display total VOI across all sensors
disp(['Total VOI across all sensors: ', num2str(totalVOI)]);
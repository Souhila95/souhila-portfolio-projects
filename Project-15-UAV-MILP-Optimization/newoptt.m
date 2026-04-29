%%%%%VOI and VOIi information
% Create an instance of the UAEnvironment class
env = UAEnvironment();
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
% % Display individual VOI for each sensor
% disp('Individual VOI for each sensor:');
% for i = 1:nSensors
%     disp(['Sensor ', num2str(i), ' VOI: ', num2str(VoIi(i))]);
% end

% % Display total VOI across all sensors
% disp(['Total VOI across all sensors: ', num2str(totalVOI)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define parameters
% Create an instance of the UAEnvironment class

N = env.NSensors;             % Total number of SNs
M = 25;             % Total number of UAVs
T = 20;             % Number of time steps
K = 5;  
B=100;

delta_x = 1;        % Discretization step for X coordinate
delta_y = 1;        % Discretization step for Y coordinate
uav_height = 10;    % Initial altitude of UAVs
sensor_height = 0;  % Sensor height (placed at ground level)
%%%%

% Define initial positions of UAVs
initial_uavX = env.uavX; % Initial X coordinates of UAVs
initial_uavY = env.uavY; % Initial Y coordinates of UAVs

% Initialize UAV positions
this.uavX = initial_uavX;
this.uavY = initial_uavY;

% Extract initial UAV positions
uavX = initial_uavX;
uavY = initial_uavY;


% Define actions for UAVs
Actions = zeros(1, 25); % Initialize actions for 25 UAVs

% Define actions for each UAV
for i = 1:numel(Actions)
    % Randomly select an action type
    action_type = randi(4);
    
    % Define movement actions based on action type
    switch action_type
        case 1 % Move right
            move_steps = randi([2, 6]);
            Actions(i) = move_steps;
        case 2 % Move left
            move_steps = randi([7, 11]);
            Actions(i) = move_steps;
        case 3 % Move up
            move_steps = randi([12, 16]);
            Actions(i) = move_steps;
        case 4 % Move down
            move_steps = randi([17, 21]);
            Actions(i) = move_steps;
    end
end

% Define delta
this.delta = 1;
                            

% Interpret actions for all UAVs simultaneously
for i = 1:numel(Actions)
    action = Actions(i);
    switch action
        case 0
            % No movement
        case 1
            % On (UAV is active)
        case 2 % 1δ Right
            uavX(i) = uavX(i) + this.delta;
        case 3 % 2δ Right
            uavX(i) = uavX(i) + 2 * this.delta;
        case 4 % 3δ Right
            uavX(i) = uavX(i) + 3 * this.delta;
        case 5 % 4δ Right
            uavX(i) = uavX(i) + 4 * this.delta;
        case 6 % 5δ Right
            uavX(i) = uavX(i) + 5 * this.delta;
        case 7 % 1δ Left
            uavX(i) = uavX(i) - this.delta;
        case 8 % 2δ Left
            uavX(i) = uavX(i) - 2 * this.delta;
        case 9 % 3δ Left
            uavX(i) = uavX(i) - 3 * this.delta;
        case 10 % 4δ Left
            uavX(i) = uavX(i) - 4 * this.delta;
        case 11 % 5δ Left
            uavX(i) = uavX(i) - 5 * this.delta;
        case 12 % 1δ Up
            uavY(i) = uavY(i) + this.delta;
        case 13 % 2δ Up
            uavY(i) = uavY(i) + 2 * this.delta;
        case 14 % 3δ Up
            uavY(i) = uavY(i) + 3 * this.delta;
        case 15 % 4δ Up
            uavY(i) = uavY(i) + 4 * this.delta;
        case 16 % 5δ Up
            uavY(i) = uavY(i) + 5 * this.delta;
        case 17 % 1δ Down
            uavY(i) = uavY(i) - this.delta;
        case 18 % 2δ Down
            uavY(i) = uavY(i) - 2 * this.delta;
        case 19 % 3δ Down
            uavY(i) = uavY(i) - 3 * this.delta;
        case 20 % 4δ Down
            uavY(i) = uavY(i) - 4 * this.delta;
        case 21 % 5δ Down
            uavY(i) = uavY(i) - 5 * this.delta;
        otherwise
            error('Invalid action!');
   
end
end
% Initialize bij as an empty symbolic variable
bij = sdpvar(N, M, 'full');
% Define optimization variables
% si = binvar(N, 1, 'full'); % Binary variable indicating whether sensor i is covered by UAV j
 si = binvar(N, M, 'full'); 
uj = binvar(M, 1); % Transpose uj to have dimensions (1, M)

% Size of each temperature measurement data point in bytes (single precision)
dataPointSizeBytes = 4;

% Number of data points collected by each sensor
arraySize = 100; % Adjust as needed based on your specific requirements

% Calculate the total size of data collected by each sensor
env.SizeArr = ones(1, env.NSensors) * dataPointSizeBytes * arraySize;


for j = 1:M
    for i = 1:N
        % Ensure the distance between sensor i and UAV j is within the coverage range
         distance = sqrt((uavX(j) - env.xALL(i))^2 + (uavY(j) - env.yALL(i))^2 + (env.uavZ(j))^2);
           
RateUAV = env.B * log2(1 + env.SN_transmitPower * env.Kappa * (env.d0 / distance)^env.alpha / env.sigma2);

            TimeUAV(i, j) = env.SizeArr(i) / RateUAV;
            
            % Calculate energy consumption for communication between sensor i and UAV j
            EnergySN(i, j) = env.SN_transmitPower * TimeUAV(i, j);


        % Constraints = [Constraints, si(i, j) * distance <= env.RangeUAV * uj(j)]; % Only enforce distance constraint if UAV j is active
    end
end
Eij=EnergySN;
Tij=TimeUAV;
dij=distance;
Ei = sum(sum(EnergySN));
% % Define objective function

 f = 0.6*sum(uj) - 0.06*sum(si) +  0.01*sum(EnergySN) -  0.01*sum(VoI);
 %f =  4.79*sum(uj) - 0.01*sum(si) +  0.01*sum(EnergySN) -  0.01*sum(VoI);

 % Define constraints

Constraints = [];

for j = 1:M
    for i = 1:N
        % Ensure the distance between sensor i and UAV j is within the coverage range
        distance = sqrt((uavX(j) - env.xALL(i))^2 + (uavY(j) - env.yALL(i))^2 + (env.uavZ(j))^2);
    
    Constraints = [Constraints, sum(si(i, j) * distance) <= env.RangeUAV * uj(j)];

        % Constraints = [Constraints, si(i, j) * distance <= env.RangeUAV * uj(j)]; % Only enforce distance constraint if UAV j is active
    end
end
for i = 1:N
    % Ensure each sensor is covered by exactly one UAV
    Constraints = [Constraints, sum(si(i, :)) == 1];
end

%%%%%%


%%%%%%

%add constraint
% constraint 2

Ii=1;
for i = 1:N
    Constraints = [Constraints, sum(EnergySN .* bij .* Ii) <= si(i)];
end
%constraint 3
  % Constraint ensuring summation of VOI for each uj considered in the reward function is equal to the VOI value for all si where bij = 1
%%%
% Reformulated constraint without quadratic equality constraint
 SN_transmitPower=0.2;
for i = 1:N
    % Initialize a variable to store the sum of products
    sum_product = 0;

    for j = 1:M
        % Add the product of Eij, bij, and Ii to the sum
        sum_product = sum_product + SN_transmitPower * Tij(i, j) * bij(i, j) * Ii; % Corrected indexing here
    end

    % Constrain the sum of products to be less than or equal to si(i)
    Constraints = [Constraints, sum_product <= si(i)];
end

% Constraint 4: Set UAV online if associated with at least one SN

total_VOI = 0; % Initialize total VOI
for i = 1:N
    % Accumulate VOI for sensor i
    total_VOI = total_VOI + exp(-B * T);
end

% Constraint 5: Set SN binary variable to 1 if SN has value to send to a UAV

for j = 1:M
    % Constraint ensuring that uj is set to 1 if there is at least one association with bij = 1
    Constraints = [Constraints, uj(j) >= sum(bij(:, j))];
end

% Constraint 6 ensuring that the total number of associated UAVs for all sensors is within the coverage area
Constraints = [Constraints, sum(bij) <= Ii];
% % Constraint 7: Ensure SN is considered successfully transmitted to UAV within delay requirement 
% 
% for i = 1:N
%     % Constraint ensuring that si is set to 1 when sensor i has data to send to at least one UAV
%     Constraints = [Constraints, sum(bij(i, :)) == si(i)];
% end

% %constraints 8 and 9
% for j = 1:M
%     % Constraint ensuring that the location (X, Y) of UAV j is within the considered hazardous area
%     Constraints = [Constraints, 0 <= X(j) <= delta_x, 0 <= Y(j) <= delta_y];
% end
%constraints 10 and 11
V=100000; 
 % Constraint 10: Ensure si >= (T - Tij) / V
% Constraint 10 and 11: 

for i = 1:N
    for j = 1:M
        % Constraint ensuring successful transmission when delay requirement is met
        Constraints = [Constraints, 1 >= (0.5 - Tij(i,j))/V, 1 <= 1 + (0.5- Tij(i,j))/V];
    end
end



%%%%%%%%%%%%% end of constraints

% Solve MILP problem
options = sdpsettings('solver', 'intlinprog', 'verbose', 1);
optimize(Constraints, f, options);

% Retrieve results
minUAVs = value(sum(uj));
% numCoveredSensors = sum(sum(value(si)));
numCoveredSensors = sum(sum(value(si) == 1));
VOI_totale=sum(VoI);

disp('Minimum number of active UAVs:');
disp(minUAVs);

disp('Number of covered sensors:');
disp(numCoveredSensors);
disp('Total value of information for covered sensors VOI:');
disp(VOI_totale)
TotalEnergy=sum(sum(EnergySN));
disp('TotalEnergy:')
disp(TotalEnergy)

% Find indices of active UAVs
active_uavs_indices = find(value(uj));

% Extract coordinates of active UAVs
optimal_uavX = value(uavX(active_uavs_indices));
optimal_uavY = value(uavY(active_uavs_indices));

% Display the coordinates of optimal UAVs
disp('Coordinates of optimal UAVs:');
disp('X coordinates:');
disp(optimal_uavX);
disp('Y coordinates:');
disp(optimal_uavY);
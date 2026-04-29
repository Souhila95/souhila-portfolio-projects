% run("UAEnvironment.m")
% run("uavmovingcoordinates.m")
%Parameters
Eij=EnergySN;
Tij=TimeUAV;
dij=DistanceUAV;
Ei = sum(sum(EnergySN));
% Define parameters
N = env.NSensors;             % Total number of SNs
M = 25;             % Total number of UAVs
T = 20;             % Number of time steps
K = 5;  
B=100;
% Number of possible movement actions for each UAV
delta_x = 1;        % Discretization step for X coordinate
delta_y = 1;        % Discretization step for Y coordinate
uav_height = 10;    % Initial altitude of UAVs
sensor_height = 0;  % Sensor height (placed at ground level)
%%%%

% Initialize bij as an empty symbolic variable
bij = sdpvar(N, M, 'full');
% Define optimization variables
si = binvar(N, M, 'full'); % Binary variable indicating whether sensor i is covered by UAV j
uj = binvar(M, 1); % Binary variable indicating whether UAV j is actively deployed
X = sdpvar(T+1, M);
Y = sdpvar(T+1, M);
Z = sdpvar(T+1, M);
% % Define objective function

f =  0.79*sum(uj) - 0.01*sum(si) +  0.01*sum(EnergySN) -  0.01*sum(VoI);
% % Define objective function: minimize the total number of active UAVs
%  f =  sum(uj) + sum(si(:)) - sum(EnergySN(:)) + sum(VoI(:));
% f = sum(uj);

% Define constraints
Constraints = [];
for i = 1:N
    % Ensure each sensor is covered by exactly one UAV
    Constraints = [Constraints, sum(si(i, :)) == 1];
end

for j = 1:M
    for i = 1:N
        % Ensure the distance between sensor i and UAV j is within the coverage range
        distance = sqrt((env.uavX(j) - env.xALL(i))^2 + (env.uavY(j) - env.yALL(i))^2 + (env.uavZ(j))^2);
        Constraints = [Constraints, si(i, j) * distance <= env.RangeUAV * uj(j)]; % Only enforce distance constraint if UAV j is active
    end
end


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

%constraints 8 and 9
for j = 1:M
    % Constraint ensuring that the location (X, Y) of UAV j is within the considered hazardous area
    Constraints = [Constraints, 0 <= X(j) <= delta_x, 0 <= Y(j) <= delta_y];
end
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



% % Constraint 12: Ensure si * dij <= Dmax
% Dmax = 15;  %UAVrange
% for i = 1:N
%     for j = 1:M
%         % Constraint ensuring that the distance between sensor i and UAV j is within the coverage limit
%         Constraints = [Constraints, si(i) * dij(i,j) <= Dmax];
%     end
% end

%%%%%%%%%%%%% end of constraints

%%%%%
% % Ensure each sensor is covered by at least one UAV
% for i = 1:N
%     Constraints = [Constraints, sum(si(i, :)) >= 1];
% end

% Solve MILP problem
options = sdpsettings('solver', 'intlinprog', 'verbose', 1);
optimize(Constraints, f, options);

% Retrieve results
minUAVs = value(sum(uj));
numCoveredSensors = sum(sum(value(si)));
VOI_totale=sum(VoI);

disp('Minimum number of active UAVs:');
disp(minUAVs);

disp('Number of covered sensors:');
disp(numCoveredSensors);
disp('Total value of information for covered sensors VOI:');
disp(VOI_totale)

% Retrieve optimal UAV positions
active_uavs_indices = find(value(uj) == 1);
chosen_uav_coordinates = zeros(length(active_uavs_indices), 2);

for uav_index = 1:length(active_uavs_indices)
    uav_idx = active_uavs_indices(uav_index);
    covered_sensors = find(value(si(:, uav_idx)) == 1);
    avg_x = mean(env.xALL(covered_sensors));
    avg_y = mean(env.yALL(covered_sensors));
    chosen_uav_coordinates(uav_index, :) = [avg_x, avg_y];
end

% Display the optimal positions of chosen UAVs
disp('Optimal positions of chosen UAVs:');
disp(chosen_uav_coordinates);


% Define constraints
Constraints = [];
% Linearize the expression for TimeUAV
% Define big constant upper bound for x_ij
U_ij = 1000; % Choose an appropriate value

% Define binary variable z_ij
z_ij = binvar(env.NSensors, env.M, 'full');

% Add constraint to enforce x_ij = 0 if z_ij = 0
Constraints = [Constraints, TimeUAV <= U_ij * z_ij];

% Linearize the logarithmic term
Constraints = [Constraints, log(1 + env.SN_transmitPower * env.Kappa * (env.d0 ./ DistanceUAV).^env.alpha / env.sigma2) <= U_ij * z_ij];

% Display linearized TimeUAV
disp('Linearized TimeUAV:');
disp(TimeUAV);

% Linearize the expression for DistanceUAV
% Define auxiliary variable w_ij
w_ij = sdpvar(env.NSensors, env.M, 'full');

% Add constraints to linearize the square root term
for i = 1:env.NSensors
    for j = 1:env.M
        Constraints = [Constraints, (next_state(j) - env.xALL(i))^2 + (next_state(env.M + j) - env.yALL(i))^2 + (env.uavZ(j))^2 >= 0];
        Constraints = [Constraints, w_ij(i, j)^2 <= (next_state(j) - env.xALL(i))^2 + (next_state(env.M + j) - env.yALL(i))^2 + (env.uavZ(j))^2];
        Constraints = [Constraints, w_ij(i, j) >= 0];
    end
end

% Use w_ij in place of DistanceUAV
DistanceUAV = w_ij;

% Display linearized DistanceUAV
disp('Linearized DistanceUAV:');
disp(DistanceUAV);

SN_transmitPower=0.2;
% Display linearized EnergySN
EnergySN=TimeUAV*SN_transmitPower;
disp('Linearized EnergySN:');
disp(EnergySN);
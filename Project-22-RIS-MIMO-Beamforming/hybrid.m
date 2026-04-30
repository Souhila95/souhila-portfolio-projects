%% Enhanced Real-Time Optimization with GA, PSO, and Hybrid GA-PSO
clear; clc; close all;

% Constants
rng(222); % Ensure reproducibility
c = 299792458; % Speed of light in m/s
frequency = 28e9; % Frequency in mmWave band (28 GHz)
wavelength = c / frequency; % Wavelength calculation

% Parameters
numUsers = 10; % Number of users
N_BS = 8; % Number of base station antennas
N_RIS = 64; % Number of RIS elements
BS_location = [0, 0, 10]; % Fixed Base Station location
RIS_location = [5, 0, 5]; % Fixed RIS location
maxBounds = [10, 10, 10]; % Space boundaries (x, y, z)
sigma2 = 1e-9; % Noise power (W)
P_BS_max = 10; % Power budget at BS (Watts)
quantization_levels = 4; % Number of RIS phase quantization levels
timeSteps = 10; % Time steps for dynamic environment simulation

% RIS Element Layout (Uniform Planar Array)
RIS_spacing = wavelength / 2; % Element spacing (half wavelength)
N_RIS_sqrt = sqrt(N_RIS); % Assume square UPA
[ris_x, ris_y] = meshgrid(0:N_RIS_sqrt-1, 0:N_RIS_sqrt-1);
ris_x = RIS_spacing * (ris_x(:) - mean(ris_x(:))); % X-coordinates
ris_y = RIS_spacing * (ris_y(:) - mean(ris_y(:))); % Y-coordinates
RIS_positions = RIS_location + [ris_x, ris_y, zeros(N_RIS, 1)]; % 3D positions of RIS elements

% User Mobility (Random Walk)
userLocations = rand(numUsers, 3) .* maxBounds; % Initial user locations
userVelocities = (rand(numUsers, 3) - 0.5) * 0.5; % User velocities

% Path Loss Function
path_loss = @(d) (wavelength / (4 * pi * d))^2;

% Generate Channels with Rician Fading
generate_channels = @(locs) deal( ...
    rand(N_RIS, N_BS) + 1j * rand(N_RIS, N_BS), ... % H_BS_RIS
    rand(numUsers, N_RIS) + 1j * rand(numUsers, N_RIS), ... % H_RIS_Users
    rand(numUsers, N_BS) + 1j * rand(numUsers, N_BS)); % H_BS_Users

% Quantize RIS Phases
quantize_phases = @(theta) (2 * pi / quantization_levels) * round(theta / (2 * pi / quantization_levels));

% Achievable Sum Rate and Energy Efficiency Functions
compute_sum_rate = @(w, theta, H_BS_RIS, H_RIS_Users, H_BS_Users) ...
    sum(log2(1 + abs(H_BS_Users * w + H_RIS_Users * diag(exp(1j * theta)) * H_BS_RIS * w).^2 / sigma2));

compute_power = @(w, theta) norm(w)^2 + sum(abs(exp(1j * theta))); % Power calculation

%% Optimization with GA, PSO, and Hybrid GA-PSO
maxGenerations = 20;
popSize = 50;
numParticles = 30;
maxIterations = 15;

% Mobility and Time-Dynamic Optimization
time_dynamic_results = struct();
for t = 1:timeSteps
    % Update user locations for mobility
    userLocations = userLocations + userVelocities; % Random walk
    userLocations = mod(userLocations, maxBounds); % Keep within bounds

    % Generate time-varying channels
    [H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations);

    % GA Optimization
    [ga_w, ga_theta, ga_fitness_log] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels);

    % PSO Optimization
    [pso_w, pso_theta, pso_fitness_log] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, numParticles, maxIterations, quantization_levels);

    % Hybrid Optimization
    [hybrid_w, hybrid_theta, hybrid_fitness_log] = optimize_hybrid(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, numParticles, maxIterations, quantization_levels);

    % Store results for this time step
    time_dynamic_results(t).ga_fitness = ga_fitness_log(end);
    time_dynamic_results(t).pso_fitness = pso_fitness_log(end);
    time_dynamic_results(t).hybrid_fitness = hybrid_fitness_log(end);

    % Energy Efficiency
    time_dynamic_results(t).ga_efficiency = ga_fitness_log(end) / compute_power(ga_w, ga_theta);
    time_dynamic_results(t).pso_efficiency = pso_fitness_log(end) / compute_power(pso_w, pso_theta);
    time_dynamic_results(t).hybrid_efficiency = hybrid_fitness_log(end) / compute_power(hybrid_w, hybrid_theta);
end

%% Plot Results

% Achievable Sum Rate Over Time
figure;
plot(1:timeSteps, [time_dynamic_results.ga_fitness], '-o', 'LineWidth', 2); hold on;
plot(1:timeSteps, [time_dynamic_results.pso_fitness], '-s', 'LineWidth', 2);
plot(1:timeSteps, [time_dynamic_results.hybrid_fitness], '-x', 'LineWidth', 2);
grid on;
legend('GA', 'PSO', 'Hybrid GA-PSO');
xlabel('Time Step');
ylabel('Achievable Sum Rate (bps/Hz)');
title('Dynamic Achievable Sum Rate over Time');

% Energy Efficiency Over Time
figure;
plot(1:timeSteps, [time_dynamic_results.ga_efficiency], '-o', 'LineWidth', 2); hold on;
plot(1:timeSteps, [time_dynamic_results.pso_efficiency], '-s', 'LineWidth', 2);
plot(1:timeSteps, [time_dynamic_results.hybrid_efficiency], '-x', 'LineWidth', 2);
grid on;
legend('GA', 'PSO', 'Hybrid GA-PSO');
xlabel('Time Step');
ylabel('Energy Efficiency (bps/Hz/W)');
title('Energy Efficiency over Time');

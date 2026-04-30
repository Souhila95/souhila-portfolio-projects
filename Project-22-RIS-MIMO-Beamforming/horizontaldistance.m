%% Real-Time Optimization with GA, PSO, and Hybrid GA-PSO
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

% RIS Element Layout (Uniform Planar Array)
RIS_spacing = wavelength / 2; % Element spacing (half wavelength)
N_RIS_sqrt = sqrt(N_RIS); % Assume square UPA
[ris_x, ris_y] = meshgrid(0:N_RIS_sqrt-1, 0:N_RIS_sqrt-1);
ris_x = RIS_spacing * (ris_x(:) - mean(ris_x(:))); % X-coordinates
ris_y = RIS_spacing * (ris_y(:) - mean(ris_y(:))); % Y-coordinates
RIS_positions = RIS_location + [ris_x, ris_y, zeros(N_RIS, 1)]; % 3D positions of RIS elements

% User Locations and Mobility
userLocations = rand(numUsers, 3) .* maxBounds; % Initial user locations
userVelocities = (rand(numUsers, 3) - 0.5) * 0.2; % Random velocities

%% Functions
% Path Loss
function PL = path_loss(d, wavelength)
    PL = (wavelength / (4 * pi * d))^2; % Linear scale
end

% Generate Channels with Rician Fading
function [H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations, RIS_positions, BS_location, N_BS, N_RIS, numUsers, wavelength, K_factor)
    LOS_component = 1; % Line-of-sight
    NLOS_component = sqrt(1 / (1 + K_factor));

    H_BS_RIS = zeros(N_RIS, N_BS);
    H_RIS_Users = zeros(numUsers, N_RIS);
    H_BS_Users = zeros(numUsers, N_BS);

    % BS ↔ RIS channel
    for i = 1:N_RIS
        d_BS_RIS = norm(RIS_positions(i, :) - BS_location);
        PL_BS_RIS = path_loss(d_BS_RIS, wavelength);
        H_BS_RIS(i, :) = sqrt(PL_BS_RIS) * (LOS_component + NLOS_component * (randn(1, N_BS) + 1j * randn(1, N_BS))) / sqrt(2);
    end

    % RIS ↔ Users channel
    for k = 1:numUsers
        for i = 1:N_RIS
            d_RIS_User = norm(userLocations(k, :) - RIS_positions(i, :));
            PL_RIS_User = path_loss(d_RIS_User, wavelength);
            H_RIS_Users(k, i) = sqrt(PL_RIS_User) * (LOS_component + NLOS_component * (randn + 1j * randn)) / sqrt(2);
        end
    end

    % BS ↔ Users channel
    for k = 1:numUsers
        d_BS_User = norm(userLocations(k, :) - BS_location);
        PL_BS_User = path_loss(d_BS_User, wavelength);
        H_BS_Users(k, :) = sqrt(PL_BS_User) * (LOS_component + NLOS_component * (randn(1, N_BS) + randn(1, N_BS) * 1j)) / sqrt(2);
    end
end

% Achievable Sum Rate
function R = compute_sum_rate(w, theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2)
    numUsers = size(H_RIS_Users, 1);
    R = 0;
    for k = 1:numUsers
        h_eff = H_BS_Users(k, :) * w + H_RIS_Users(k, :) * diag(exp(1j * theta)) * H_BS_RIS * w;
        signal_power = abs(h_eff)^2;
        SINR = signal_power / sigma2;
        R = R + log2(1 + SINR);
    end
end

% Quantize RIS Phases
function quantized_theta = quantize_phases(theta, quantization_levels)
    step_size = 2 * pi / quantization_levels;
    quantized_theta = step_size * round(theta / step_size);
end

% Genetic Algorithm (GA) Optimization
function [optimized_w, optimized_theta, fitness_log] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels)
    % Initialize Population
    population_w = randn(N_BS, popSize) + 1j * randn(N_BS, popSize); % Random beamforming
    population_theta = 2 * pi * rand(N_RIS, popSize); % Random RIS phase shifts

    fitness_log = zeros(1, maxGenerations); % Track fitness per generation

    % GA Optimization Loop
    for gen = 1:maxGenerations
        % Fitness Evaluation
        fitness = zeros(1, popSize);
        for i = 1:popSize
            w = sqrt(P_BS_max) * population_w(:, i) / norm(population_w(:, i)); % Normalize power
            theta = quantize_phases(population_theta(:, i), quantization_levels); % Quantize RIS phases
            fitness(i) = compute_sum_rate(w, theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);
        end
        fitness_log(gen) = max(fitness); % Log best fitness

        % Selection: Keep the top half of the population
        [~, idx] = sort(fitness, 'descend');
        top_w = population_w(:, idx(1:popSize / 2));
        top_theta = population_theta(:, idx(1:popSize / 2));

        % Crossover and Mutation
        new_population_w = top_w;
        new_population_theta = top_theta;
        for i = 1:(popSize / 2)
            p1 = randi(size(top_w, 2));
            p2 = randi(size(top_w, 2));
            child_w = (top_w(:, p1) + top_w(:, p2)) / 2;
            child_theta = mean([top_theta(:, p1), top_theta(:, p2)], 2);
            new_population_w(:, end + 1) = child_w;
            new_population_theta(:, end + 1) = child_theta;
        end
        % Apply Mutation
        mutation_rate = 0.1; % Probability of mutation
        mutation_indices = rand(size(new_population_theta)) < mutation_rate;
        new_population_theta(mutation_indices) = 2 * pi * rand(sum(mutation_indices(:)), 1);

        population_w = new_population_w(:, 1:popSize); % Trim population
        population_theta = new_population_theta(:, 1:popSize);
    end
    [~, best_idx] = max(fitness);
    optimized_w = population_w(:, best_idx);
    optimized_theta = quantize_phases(population_theta(:, best_idx), quantization_levels);
end

% Particle Swarm Optimization (PSO) Optimization
function [optimized_w, optimized_theta] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxIterations, swarmSize, quantization_levels)
    % Initialize PSO Parameters
    w_max = 0.9; w_min = 0.4; % Inertia weights
    c1 = 2; c2 = 2; % Cognitive and social coefficients
    positions_w = randn(N_BS, swarmSize) + 1j * randn(N_BS, swarmSize); % Random positions for beamforming
    velocities_w = randn(N_BS, swarmSize) * 0.1; % Initial velocities
    positions_theta = 2 * pi * rand(N_RIS, swarmSize); % Random RIS phases
    velocities_theta = randn(N_RIS, swarmSize) * 0.1; % Initial velocities
    
    pbest_w = positions_w; % Personal best positions for beamforming
    pbest_theta = positions_theta; % Personal best for RIS phases
    pbest_fitness = zeros(1, swarmSize); % Personal best fitness
    gbest_w = zeros(N_BS, 1); % Global best position
    gbest_theta = zeros(N_RIS, 1); % Global best phase shifts
    gbest_fitness = -Inf; % Initial global best fitness
    
    % PSO Optimization Loop
    for iter = 1:maxIterations
        for i = 1:swarmSize
            w = sqrt(P_BS_max) * positions_w(:, i) / norm(positions_w(:, i)); % Normalize power
            theta = quantize_phases(positions_theta(:, i), quantization_levels); % Quantize RIS phases
            fitness = compute_sum_rate(w, theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

            % Update Personal Best
            if fitness > pbest_fitness(i)
                pbest_fitness(i) = fitness;
                pbest_w(:, i) = positions_w(:, i);
                pbest_theta(:, i) = positions_theta(:, i);
            end

            % Update Global Best
            if fitness > gbest_fitness
                gbest_fitness = fitness;
                gbest_w = positions_w(:, i);
                gbest_theta = positions_theta(:, i);
            end
        end

        % Update Velocities and Positions
        inertia_w = w_max - (w_max - w_min) * iter / maxIterations;
        for i = 1:swarmSize
            velocities_w(:, i) = inertia_w * velocities_w(:, i) + ...
                c1 * rand() * (pbest_w(:, i) - positions_w(:, i)) + ...
                c2 * rand() * (gbest_w - positions_w(:, i));
            positions_w(:, i) = positions_w(:, i) + velocities_w(:, i);
            
            velocities_theta(:, i) = inertia_w * velocities_theta(:, i) + ...
                c1 * rand() * (pbest_theta(:, i) - positions_theta(:, i)) + ...
                c2 * rand() * (gbest_theta - positions_theta(:, i));
            positions_theta(:, i) = positions_theta(:, i) + velocities_theta(:, i);
        end
    end

    optimized_w = gbest_w;
    optimized_theta = gbest_theta;
end

% Hybrid GA-PSO Optimization
function [optimized_w, optimized_theta] = optimize_ga_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels)
    % GA phase
    [ga_w, ga_theta, ~] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels);

    % PSO phase
    [pso_w, pso_theta] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels);

    % Combine results from GA and PSO
    optimized_w = (ga_w + pso_w) / 2; % Averaging both solutions
    optimized_theta = (ga_theta + pso_theta) / 2;
end

%% Main loop for horizontal distance versus sum rate
% Horizontal distances for plotting
horizontal_distances = zeros(1, numUsers); % Store horizontal distances
effective_sum_rates_ga = zeros(1, numUsers); % Store effective sum rates for GA
effective_sum_rates_pso = zeros(1, numUsers); % Store effective sum rates for PSO
effective_sum_rates_hybrid = zeros(1, numUsers); % Store effective sum rates for Hybrid

for k = 1:numUsers
    userLocations(k, 1:2) = [k, k]; % Update user location for each iteration
    horizontal_distances(k) = norm(userLocations(k, 1:2)); % Calculate horizontal distance

    % Generate channels
    [H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations, RIS_positions, BS_location, N_BS, N_RIS, numUsers, wavelength, 10);

    % GA Optimization
    [ga_w, ga_theta, ~] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, 50, 20, quantization_levels);
    effective_sum_rates_ga(k) = compute_sum_rate(ga_w, ga_theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

    % PSO Optimization
    [pso_w, pso_theta] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, 50, 20, quantization_levels);
    effective_sum_rates_pso(k) = compute_sum_rate(pso_w, pso_theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

    % Hybrid GA-PSO Optimization
    [hybrid_w, hybrid_theta] = optimize_ga_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, 50, 20, quantization_levels);
    effective_sum_rates_hybrid(k) = compute_sum_rate(hybrid_w, hybrid_theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);
end

% Plot Horizontal Distance vs Effective Sum Rate for all techniques
figure;
scatter(horizontal_distances, effective_sum_rates_ga, 'r', 'DisplayName', 'GA');
hold on;
scatter(horizontal_distances, effective_sum_rates_pso, 'g', 'DisplayName', 'PSO');
scatter(horizontal_distances, effective_sum_rates_hybrid, 'b', 'DisplayName', 'Hybrid GA-PSO');
grid on;
xlabel('Horizontal Distance (m)');
ylabel('Effective Sum Rate (bps/Hz)');
legend('show');
title('Horizontal Distance vs Effective Sum Rate for Different Optimization Techniques');

%% Complete Implementation: Real-Time Optimization with GA, PSO, and Hybrid GA-PSO
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

%% Function: Path Loss
function PL = path_loss(d, wavelength)
    % Free-space path loss
    PL = (wavelength / (4 * pi * d))^2; % Linear scale
end

%% Function: Generate Channels with Rician Fading
function [H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations, RIS_positions, BS_location, N_BS, N_RIS, numUsers, wavelength, K_factor)
    % Initialize channel matrices
    H_BS_RIS = zeros(N_RIS, N_BS);
    H_RIS_Users = zeros(numUsers, N_RIS);
    H_BS_Users = zeros(numUsers, N_BS);

    % Rician fading components
    LOS_component = 1; % Line-of-sight
    NLOS_component = sqrt(1 / (1 + K_factor));

    % BS ↔ RIS channel (static)
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
        H_BS_Users(k, :) = sqrt(PL_BS_User) * (LOS_component + NLOS_component * (randn(1, N_BS) + 1j * randn(1, N_BS))) / sqrt(2);
    end
end

%% Function: Compute Achievable Sum Rate
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

%% Genetic Algorithm (GA)
function [optimized_w, optimized_theta] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize)
    % Initialize Population
    population_w = randn(N_BS, popSize) + 1j * randn(N_BS, popSize); % Random beamforming
    population_theta = 2 * pi * rand(N_RIS, popSize); % Random RIS phase shifts

    % Fitness Evaluation
    fitness = zeros(1, popSize);
    for gen = 1:maxGenerations
        for i = 1:popSize
            % Normalize power
            w = population_w(:, i);
            w = sqrt(P_BS_max) * w / norm(w); % Ensure power constraint

            % Compute Fitness (Sum Rate)
            fitness(i) = compute_sum_rate(w, population_theta(:, i), H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);
        end

        % Selection: Choose top individuals
        [~, idx] = sort(fitness, 'descend');
        top_w = population_w(:, idx(1:popSize / 2));
        top_theta = population_theta(:, idx(1:popSize / 2));

        % Crossover and Mutation
        new_population_w = top_w;
        new_population_theta = top_theta;
        for i = 1:2:popSize / 2 - 1
            crossover_point = randi([1 N_BS]);
            child_w1 = [top_w(1:crossover_point, i); top_w(crossover_point + 1:end, i + 1)];
            child_w2 = [top_w(1:crossover_point, i + 1); top_w(crossover_point + 1:end, i)];
            new_population_w(:, end + 1:end + 2) = [child_w1, child_w2];

            child_theta = mean([top_theta(:, i), top_theta(:, i + 1)], 2);
            new_population_theta(:, end + 1:end + 2) = [child_theta, child_theta];
        end

        % Mutation
        mutation_idx = randi(size(new_population_theta, 2));
        new_population_theta(:, mutation_idx) = 2 * pi * rand(N_RIS, 1);

        % Update Population
        population_w = new_population_w(:, 1:popSize);
        population_theta = new_population_theta(:, 1:popSize);
    end

    % Return Best Solution
    [~, best_idx] = max(fitness);
    optimized_w = population_w(:, best_idx);
    optimized_theta = population_theta(:, best_idx);
end
%%%Simulation
% Initialize arrays for storing sum rates
sumRateGA = zeros(1, timeSteps); % For GA sum rate history
sumRatePSO = zeros(1, timeSteps); % For PSO sum rate history

for t = 1:timeSteps
    % Update User Locations
    userLocations = userLocations + userVelocities;
    for u = 1:numUsers
        for dim = 1:3
            if userLocations(u, dim) > maxBounds(dim) || userLocations(u, dim) < 0
                userVelocities(u, dim) = -userVelocities(u, dim);
                userLocations(u, dim) = min(max(userLocations(u, dim), 0), maxBounds(dim));
            end
        end
    end

    % Generate Channels
    [H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations, RIS_positions, BS_location, N_BS, N_RIS, numUsers, wavelength, K_factor);

    % Use GA to optimize beamforming and RIS phase shifts
    [beamformingVectorsGA, risPhaseShiftsGA] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, 50, 20);
    % Compute Sum Rate for GA
    sumRateGA(t) = compute_sum_rate(beamformingVectorsGA, risPhaseShiftsGA, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

    % Use PSO to optimize beamforming and RIS phase shifts
    [beamformingVectorsPSO, risPhaseShiftsPSO] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, 50, 20);
    % Compute Sum Rate for PSO
    sumRatePSO(t) = compute_sum_rate(beamformingVectorsPSO, risPhaseShiftsPSO, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

    % Visualization (optional)
    figure(1);
    scatter3(userLocations(:, 1), userLocations(:, 2), userLocations(:, 3), 'filled', 'DisplayName', 'Users');
    hold on;
    scatter3(BS_location(1), BS_location(2), BS_location(3), 100, 'r', 'filled', 'DisplayName', 'Base Station');
    scatter3(RIS_location(1), RIS_location(2), RIS_location(3), 100, 'b', 'filled', 'DisplayName', 'RIS');
    title(['User Mobility at Timestep ', num2str(t)]);
    xlabel('X-axis (m)');
    ylabel('Y-axis (m)');
    zlabel('Z-axis (m)');
    legend('Location', 'northeastoutside'); % Add a legend
    grid on;
    hold off;
end

%% Plot Results
figure;
hold on;
plot(1:timeSteps, sumRateGA, 'LineWidth', 2, 'DisplayName', 'GA Sum Rate');
plot(1:timeSteps, sumRatePSO, 'LineWidth', 2, 'DisplayName', 'PSO Sum Rate');
xlabel('Time Step');
ylabel('Achievable Sum Rate (bps/Hz)');
title('Comparison of Sum Rates with GA and PSO');
legend('Location', 'northeastoutside');
grid on;
hold off;

%% Plot Results
figure;
plot(1:timeSteps, sumRateHistory, 'LineWidth', 2);
xlabel('Time Step');
ylabel('Achievable Sum Rate (bps/Hz)');
title('Sum Rate Over Time with Genetic Algorithm');
grid on;

%% Particle Swarm Optimization (PSO)
function [optimized_w, optimized_theta, sumRateHistory] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, numParticles, maxIterations)
    % Initialize Particles
    particles_w = randn(N_BS, numParticles) + 1j * randn(N_BS, numParticles); % Initial beamforming vectors
    particles_theta = 2 * pi * rand(N_RIS, numParticles); % Initial RIS phase shifts

    % Initialize Velocities
    velocities_w = randn(N_BS, numParticles); % Initial velocities for beamforming
    velocities_theta = randn(N_RIS, numParticles); % Initial velocities for RIS phase shifts

    % Personal Bests
    pbest_w = particles_w;
    pbest_theta = particles_theta;
    pbest_fitness = zeros(1, numParticles); % Fitness values for personal bests

    % Global Best
    [gbest_fitness, gbest_idx] = max(pbest_fitness);
    gbest_w = pbest_w(:, gbest_idx);
    gbest_theta = pbest_theta(:, gbest_idx);

    % PSO Parameters
    w_inertia = 0.7; % Inertia weight
    c1 = 1.5; % Personal best weight
    c2 = 1.5; % Global best weight

    % Initialize sum rate history for plotting
    sumRateHistory = zeros(1, maxIterations);

    % Fitness Evaluation
    for iter = 1:maxIterations
        for i = 1:numParticles
            % Normalize power for the beamforming vectors (w)
            w = particles_w(:, i);
            w = sqrt(P_BS_max) * w / norm(w); % Ensure power constraint

            % Compute Fitness (Sum Rate)
            fitness = compute_sum_rate(w, particles_theta(:, i), H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

            % Update Personal Best
            if fitness > pbest_fitness(i)
                pbest_fitness(i) = fitness;
                pbest_w(:, i) = particles_w(:, i);
                pbest_theta(:, i) = particles_theta(:, i);
            end
        end

        % Update Global Best
        [max_fitness, idx] = max(pbest_fitness);
        if max_fitness > gbest_fitness
            gbest_fitness = max_fitness;
            gbest_w = pbest_w(:, idx);
            gbest_theta = pbest_theta(:, idx);
        end

        % Store the global best fitness (sum rate) for this iteration
        sumRateHistory(iter) = gbest_fitness;

        % Update Velocities and Positions
        for i = 1:numParticles
            % Update Velocity for Beamforming Vectors (w)
            velocities_w(:, i) = w_inertia * velocities_w(:, i) + c1 * rand * (pbest_w(:, i) - particles_w(:, i)) + c2 * rand * (gbest_w - particles_w(:, i));
            particles_w(:, i) = particles_w(:, i) + velocities_w(:, i);

            % Update Velocity for RIS Phase Shifts (theta)
            velocities_theta(:, i) = w_inertia * velocities_theta(:, i) + c1 * rand * (pbest_theta(:, i) - particles_theta(:, i)) + c2 * rand * (gbest_theta - particles_theta(:, i));
            particles_theta(:, i) = particles_theta(:, i) + velocities_theta(:, i);
        end

        % Optionally: Print the fitness at each iteration (for monitoring)
        disp(['Iteration: ', num2str(iter), ', Best Fitness: ', num2str(gbest_fitness)]);
    end

    % Return Best Solution
    optimized_w = gbest_w;
    optimized_theta = gbest_theta;
end


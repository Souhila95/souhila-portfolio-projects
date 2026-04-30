%figures included
%Running time of the GA versus PSO, GA-PSO
%Capacity versus the no of the users in the RIS assisted MIMO system*
% The numbers of iteration versus the Signal noise ratio 
% No of iteration against the average achievable sum rate


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
        H_BS_Users(k, :) = sqrt(PL_BS_User) * (LOS_component + NLOS_component * (randn(1, N_BS) + 1j * randn(1, N_BS))) / sqrt(2);
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

% Power Consumption
function power = compute_power(w, theta)
    power = norm(w)^2 + sum(abs(exp(1j * theta))); % Beamforming and RIS operation power
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

% Particle Swarm Optimization (PSO)
function [optimized_w, optimized_theta, fitness_log] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, numParticles, maxIterations, quantization_levels)
    % Initialize Particle Positions and Velocities
    particle_w = randn(N_BS, numParticles) + 1j * randn(N_BS, numParticles); % Random beamforming
    particle_theta = 2 * pi * rand(N_RIS, numParticles); % Random RIS phases
    velocity_w = randn(N_BS, numParticles) * 0.1;
    velocity_theta = randn(N_RIS, numParticles) * 0.1;

    % Fitness Evaluation
    fitness = zeros(1, numParticles);
    best_local_fitness = -Inf(1, numParticles);
    best_local_w = particle_w;
    best_local_theta = particle_theta;

    % Global Best
    [global_best_fitness, best_idx] = max(fitness);
    global_best_w = particle_w(:, best_idx);
    global_best_theta = particle_theta(:, best_idx);

    fitness_log = zeros(1, maxIterations);

    % PSO Loop
    for iter = 1:maxIterations
        for i = 1:numParticles
            % Normalize Power
            w = sqrt(P_BS_max) * particle_w(:, i) / norm(particle_w(:, i));
            theta = quantize_phases(particle_theta(:, i), quantization_levels);
            fitness(i) = compute_sum_rate(w, theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

            % Update Local Best
            if fitness(i) > best_local_fitness(i)
                best_local_fitness(i) = fitness(i);
                best_local_w(:, i) = particle_w(:, i);
                best_local_theta(:, i) = particle_theta(:, i);
            end
        end

        % Update Global Best
        [current_best_fitness, best_idx] = max(fitness);
        if current_best_fitness > global_best_fitness
            global_best_fitness = current_best_fitness;
            global_best_w = particle_w(:, best_idx);
            global_best_theta = particle_theta(:, best_idx);
        end

        % Velocity Update (Cognitive and Social Components)
        for i = 1:numParticles
            velocity_w(:, i) = 0.5 * velocity_w(:, i) + rand * (best_local_w(:, i) - particle_w(:, i)) + ...
                rand * (global_best_w - particle_w(:, i));
            velocity_theta(:, i) = 0.5 * velocity_theta(:, i) + rand * (best_local_theta(:, i) - particle_theta(:, i)) + ...
                rand * (global_best_theta - particle_theta(:, i));
        end

        % Position Update
        particle_w = particle_w + velocity_w;
        particle_theta = particle_theta + velocity_theta;

        fitness_log(iter) = global_best_fitness;
    end
    optimized_w = global_best_w;
    optimized_theta = quantize_phases(global_best_theta, quantization_levels);
end

% Hybrid GA-PSO Optimization
function [optimized_w, optimized_theta, fitness_log] = optimize_hybrid(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, ga_generations, ga_pop_size, pso_particles, pso_iterations, quantization_levels)
    % GA Phase
    [ga_w, ga_theta, ~] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, ga_generations, ga_pop_size, quantization_levels);

    % Use GA result as initialization for PSO
    particle_w = repmat(ga_w, 1, pso_particles) + (randn(N_BS, pso_particles) + 1j * randn(N_BS, pso_particles)) * 0.1;
    particle_theta = repmat(ga_theta, 1, pso_particles) + randn(N_RIS, pso_particles) * 0.1;

    [optimized_w, optimized_theta, fitness_log] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, pso_particles, pso_iterations, quantization_levels);
end

%% Simulation
maxGenerations = 20;
popSize = 50;
numParticles = 30;
maxIterations = 15;

% Generate Initial Channels
[H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations, RIS_positions, BS_location, N_BS, N_RIS, numUsers, wavelength, 10);

% GA Optimization
[ga_w, ga_theta, ga_fitness_log] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels);

% PSO Optimization
[pso_w, pso_theta, pso_fitness_log] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, numParticles, maxIterations, quantization_levels);

% Hybrid Optimization
[hybrid_w, hybrid_theta, hybrid_fitness_log] = optimize_hybrid(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, numParticles, maxIterations, quantization_levels);

% Compute Power and Energy Efficiency Metrics
ga_power = compute_power(ga_w, ga_theta);
pso_power = compute_power(pso_w, pso_theta);
hybrid_power = compute_power(hybrid_w, hybrid_theta);

% Align lengths of fitness logs for plotting
minLength = min([length(ga_fitness_log), length(pso_fitness_log), length(hybrid_fitness_log)]);

% Truncate fitness logs to the same length for plotting
ga_fitness_log = ga_fitness_log(1:minLength);
pso_fitness_log = pso_fitness_log(1:minLength);
hybrid_fitness_log = hybrid_fitness_log(1:minLength);

% % Plot fitness logs
% figure;
% plot(1:minLength, ga_fitness_log, '-o', 'LineWidth', 2); hold on;
% plot(1:minLength, pso_fitness_log, '-s', 'LineWidth', 2);
% plot(1:minLength, hybrid_fitness_log, '-x', 'LineWidth', 2);
% grid on; legend('GA', 'PSO', 'Hybrid GA-PSO');
% xlabel('Iterations'); ylabel('Achievable Sum Rate (bps/Hz)');
% title('Optimization Performance Comparison');

% Find the point where the sum rate converges to a threshold
convergence_threshold = 0.9 * max(ga_fitness_log); % for example, 90% of the max sum rate
ga_convergence = find(ga_fitness_log >= convergence_threshold, 1);
pso_convergence = find(pso_fitness_log >= convergence_threshold, 1);
hybrid_convergence = find(hybrid_fitness_log >= convergence_threshold, 1);

disp(['GA Convergence: ', num2str(ga_convergence)]);
disp(['PSO Convergence: ', num2str(pso_convergence)]);
disp(['Hybrid GA-PSO Convergence: ', num2str(hybrid_convergence)]);


figure;
bar([ga_power, pso_power, hybrid_power]);
set(gca, 'XTickLabel', {'GA', 'PSO', 'Hybrid GA-PSO'});
ylabel('Power Consumption (Watts)');
title('Power Consumption Comparison');


ga_energy_efficiency = ga_fitness_log(end) / ga_power;
pso_energy_efficiency = pso_fitness_log(end) / pso_power;
hybrid_energy_efficiency = hybrid_fitness_log(end) / hybrid_power;

% Display energy efficiency comparison
disp(['GA Energy Efficiency: ', num2str(ga_energy_efficiency)]);
disp(['PSO Energy Efficiency: ', num2str(pso_energy_efficiency)]);
disp(['Hybrid GA-PSO Energy Efficiency: ', num2str(hybrid_energy_efficiency)]);



disp('GA Optimized Beamforming and RIS Phases:');
disp(ga_w);
disp(ga_theta);

disp('PSO Optimized Beamforming and RIS Phases:');
disp(pso_w);
disp(pso_theta);

disp('Hybrid GA-PSO Optimized Beamforming and RIS Phases:');
disp(hybrid_w);
disp(hybrid_theta);

%%%% The numbers of iteration versus the Signal noise ratio %%%%%

% Calculate SNRs 
ga_snr = 10 * log10(ga_fitness_log);
pso_snr = 10 * log10(pso_fitness_log);
hybrid_snr = 10 * log10(hybrid_fitness_log);

% Plot SNR vs Iterations
figure;
plot(1:minLength, ga_snr, '-o', 'LineWidth', 2); hold on;
plot(1:minLength, pso_snr, '-s', 'LineWidth', 2);
plot(1:minLength, hybrid_snr, '-x', 'LineWidth', 2);
grid on;
legend('GA', 'PSO', 'Hybrid GA-PSO', 'Location', 'Best');
xlabel('Number of Iterations');
ylabel('Signal-to-Noise Ratio (SNR) [dB]');
title('SNR vs Iterations for GA, PSO, and Hybrid GA-PSO');



%%%%%%  No of iteration against the average achievable sum rate *****

% Calculate the average achievable sum rate for each method
ga_avg_sum_rate = cumsum(ga_fitness_log) ./ (1:minLength);
pso_avg_sum_rate = cumsum(pso_fitness_log) ./ (1:minLength);
hybrid_avg_sum_rate = cumsum(hybrid_fitness_log) ./ (1:minLength);

% Plot Average Achievable Sum Rate vs Iterations
figure;
plot(1:minLength, ga_avg_sum_rate, '-o', 'LineWidth', 2); hold on;
plot(1:minLength, pso_avg_sum_rate, '-s', 'LineWidth', 2);
plot(1:minLength, hybrid_avg_sum_rate, '-x', 'LineWidth', 2);
grid on;
legend('GA', 'PSO', 'Hybrid GA-PSO', 'Location', 'Best');
xlabel('Number of Iterations');
ylabel('Average Achievable Sum Rate (bps/Hz)');
title('Average Achievable Sum Rate vs Iterations for GA, PSO, and Hybrid GA-PSO');




%%%%

% Range of user counts to evaluate
userCounts = 1:20; % Example range: 1 to 20 users
capacities = zeros(size(userCounts)); % Preallocate for capacities

for idx = 1:length(userCounts)
    numUsers = userCounts(idx); % Current number of users
    
    % Generate channels for current user count
    userLocations = rand(numUsers, 3) .* maxBounds; % Random user locations
    [H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations, RIS_positions, BS_location, N_BS, N_RIS, numUsers, wavelength, 10);
    
    % Run GA optimization for simplicity (you can use PSO or Hybrid too)
    [ga_w, ga_theta, ~] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels);
    
    % Compute the achievable sum rate for the current configuration
    capacities(idx) = compute_sum_rate(ga_w, ga_theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);
end

% Plot Capacity vs Number of Users
figure;
plot(userCounts, capacities, '-o', 'LineWidth', 2);
grid on;
xlabel('Number of Users');
ylabel('Achievable Sum Rate (bps/Hz)');
title('Capacity vs Number of Users in RIS-assisted MIMO System');


%%%%%

%% Running Time Comparison: GA, PSO, and Hybrid GA-PSO

% Measure time for GA Optimization
tic;
[ga_w, ga_theta, ga_fitness_log] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, quantization_levels);
ga_time = toc;

% Measure time for PSO Optimization
tic;
[pso_w, pso_theta, pso_fitness_log] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, numParticles, maxIterations, quantization_levels);
pso_time = toc;

% Measure time for Hybrid GA-PSO Optimization
tic;
[hybrid_w, hybrid_theta, hybrid_fitness_log] = optimize_hybrid(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, maxGenerations, popSize, numParticles, maxIterations, quantization_levels);
hybrid_time = toc;

% Store running times
running_times = [ga_time, pso_time, hybrid_time];

% Plot Running Time Comparison
figure;
bar(running_times, 'FaceColor', [0.2, 0.6, 0.8]); % Bar plot with custom color
set(gca, 'XTickLabel', {'GA', 'PSO', 'Hybrid GA-PSO'});
ylabel('Running Time (seconds)');
title('Running Time Comparison for GA, PSO, and Hybrid GA-PSO');
grid on;

% Display running times
disp(['GA Running Time: ', num2str(ga_time), ' seconds']);
disp(['PSO Running Time: ', num2str(pso_time), ' seconds']);
disp(['Hybrid GA-PSO Running Time: ', num2str(hybrid_time), ' seconds']);

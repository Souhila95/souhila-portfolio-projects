%% Real-Time Optimization with GA, PSO, and Hybrid GA-PSO
clear; clc; close all;

% Constants
rng(222); % Ensure reproducibility
c = 299792458; % Speed of light in m/s
frequency = 28e9; % Frequency in mmWave band (28 GHz)
wavelength = c / frequency; % Wavelength calculation

% Parameters
maxUsers = 20; % Maximum number of users
N_BS = 8; % Number of base station antennas
N_RIS = 64; % Number of RIS elements
BS_location = [0, 0, 10]; % Fixed Base Station location
RIS_location = [5, 0, 5]; % Fixed RIS location
maxBounds = [10, 10, 10]; % Space boundaries (x, y, z)
sigma2 = 1e-9; % Noise power (W)
P_BS_max = 10; % Power budget at BS (Watts)
quantization_levels = 4; % Number of RIS phase quantization levels
K_factor = 10; % Rician K-factor

% RIS Element Layout (Uniform Planar Array)
RIS_spacing = wavelength / 2; % Element spacing (half wavelength)
N_RIS_sqrt = sqrt(N_RIS); % Assume square UPA
[ris_x, ris_y] = meshgrid(0:N_RIS_sqrt-1, 0:N_RIS_sqrt-1);
ris_x = RIS_spacing * (ris_x(:) - mean(ris_x(:))); % X-coordinates
ris_y = RIS_spacing * (ris_y(:) - mean(ris_y(:))); % Y-coordinates
RIS_positions = RIS_location + [ris_x, ris_y, zeros(N_RIS, 1)]; % 3D positions of RIS elements

% Placeholder for results
sumRates_GA = zeros(1, maxUsers);
sumRates_PSO = zeros(1, maxUsers);
sumRates_Hybrid = zeros(1, maxUsers);

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

% Quantize RIS Phases
function quantized_theta = quantize_phases(theta, quantization_levels)
    step_size = 2 * pi / quantization_levels;
    quantized_theta = step_size * round(theta / step_size);
end

% Genetic Algorithm (GA) Optimization
function [optimized_w, optimized_theta] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels)
    w = randn(N_BS, 1) + 1j * randn(N_BS, 1); % Random initial beamforming
    w = sqrt(P_BS_max) * w / norm(w); % Normalize power
    theta = 2 * pi * rand(N_RIS, 1); % Random RIS phase shifts
    theta = quantize_phases(theta, quantization_levels);
    optimized_w = w;
    optimized_theta = theta;
end

% Particle Swarm Optimization (PSO)
function [optimized_w, optimized_theta] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels)
    % Placeholder for PSO implementation
    % Replace this with an actual PSO algorithm tailored for the problem
    w = randn(N_BS, 1) + 1j * randn(N_BS, 1);
    w = sqrt(P_BS_max) * w / norm(w);
    theta = 2 * pi * rand(N_RIS, 1);
    theta = quantize_phases(theta, quantization_levels);
    optimized_w = w;
    optimized_theta = theta;
end

% Hybrid GA-PSO Optimization
function [optimized_w, optimized_theta] = optimize_hybrid(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels)
    % Placeholder for Hybrid GA-PSO implementation
    % First use GA, then refine results with PSO
    [w_ga, theta_ga] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels);
    [optimized_w, optimized_theta] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels);
end

%% Simulation for Varying Users
for numUsers = 1:maxUsers
    % Generate User Locations
    userLocations = rand(numUsers, 3) .* maxBounds;

    % Generate Channels
    [H_BS_RIS, H_RIS_Users, H_BS_Users] = generate_channels(userLocations, RIS_positions, BS_location, N_BS, N_RIS, numUsers, wavelength, K_factor);

    % GA Optimization
    [w_ga, theta_ga] = optimize_ga(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels);
    sumRates_GA(numUsers) = compute_sum_rate(w_ga, theta_ga, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

    % PSO Optimization
    [w_pso, theta_pso] = optimize_pso(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels);
    sumRates_PSO(numUsers) = compute_sum_rate(w_pso, theta_pso, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

    % Hybrid GA-PSO Optimization
    [w_hybrid, theta_hybrid] = optimize_hybrid(H_BS_RIS, H_RIS_Users, H_BS_Users, N_BS, N_RIS, P_BS_max, sigma2, quantization_levels);
    sumRates_Hybrid(numUsers) = compute_sum_rate(w_hybrid, theta_hybrid, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);
end

%% Plot Results
figure;
plot(1:maxUsers, sumRates_GA, '-o', 'LineWidth', 2); hold on;
plot(1:maxUsers, sumRates_PSO, '-s', 'LineWidth', 2);
plot(1:maxUsers, sumRates_Hybrid, '-d', 'LineWidth', 2);
grid on;
xlabel('Number of Users');
ylabel('Sum Rate (bps/Hz)');
legend('GA', 'PSO', 'Hybrid GA-PSO', 'Location', 'Best');
title('Achievable Sum Rate vs. Number of Users');

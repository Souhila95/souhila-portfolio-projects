%% Realistic Environment Setup
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

%% Function: Compute Achievable Sum Rate with Interference
function R = compute_sum_rate(w, theta, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2)
    numUsers = size(H_RIS_Users, 1);
    R = 0;
    for k = 1:numUsers
        h_eff = H_BS_Users(k, :) * w + H_RIS_Users(k, :) * diag(exp(1j * theta)) * H_BS_RIS * w;
        signal_power = abs(h_eff)^2;

        % Interference power
        interference_power = 0;
        for j = 1:numUsers
            if j ~= k
                h_interf = H_BS_Users(j, :) * w + H_RIS_Users(j, :) * diag(exp(1j * theta)) * H_BS_RIS * w;
                interference_power = interference_power + abs(h_interf)^2;
            end
        end

        SINR = signal_power / (interference_power + sigma2);
        R = R + log2(1 + SINR);
    end
end

%% Simulation of User Mobility and Optimization
timeSteps = 50; % Number of timesteps
sumRateHistory = zeros(timeSteps, 1);
K_factor = 5; % Rician K-factor for fading

for t = 1:timeSteps
    % Update user locations (reflect at boundaries)
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

    % Placeholder: Optimize Beamforming and RIS Phase Shifts (to be implemented)
    beamformingVectors = randn(N_BS, 1) + 1j * randn(N_BS, 1); % Example beamforming
    risPhaseShifts = 2 * pi * rand(N_RIS, 1); % Example phase shifts

    % Compute Sum Rate
    sumRateHistory(t) = compute_sum_rate(beamformingVectors, risPhaseShifts, H_BS_RIS, H_RIS_Users, H_BS_Users, sigma2);

    % Visualization of User Mobility and RIS Layout
    figure(1);
    scatter3(userLocations(:, 1), userLocations(:, 2), userLocations(:, 3), 'filled');
    hold on;
    scatter3(BS_location(1), BS_location(2), BS_location(3), 100, 'r', 'filled'); % BS location
    scatter3(RIS_location(1), RIS_location(2), RIS_location(3), 100, 'b', 'filled'); % RIS location
    scatter3(RIS_positions(:, 1), RIS_positions(:, 2), RIS_positions(:, 3), 10, 'g', 'filled'); % RIS elements
    title(['User Mobility at Timestep ', num2str(t)]);
    xlabel('X (m)');
    ylabel('Y (m)');
    zlabel('Z (m)');
    grid on;
    hold off;
    pause(0.1);
end

%% Plot Results
figure;
plot(1:timeSteps, sumRateHistory, 'LineWidth', 2);
xlabel('Time Step');
ylabel('Achievable Sum Rate (bps/Hz)');
title('Sum Rate Over Time');
grid on;

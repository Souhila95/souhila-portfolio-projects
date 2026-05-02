function run_network_simulation()
    % Create a UI figure for input parameters
    fig = uifigure('Name', '6G Network Simulation Parameters', 'Position', [500, 500, 400, 300]);

    % Add labels and input fields for parameters
    lbl1 = uilabel(fig, 'Position', [20, 250, 150, 20], 'Text', 'Transmission Power (dBm):');
    powerInput = uieditfield(fig, 'numeric', 'Position', [200, 250, 100, 20], 'Value', 30); % Default 30 dBm

    lbl2 = uilabel(fig, 'Position', [20, 200, 150, 20], 'Text', 'Elevation Angle (degrees):');
    elevationInput = uieditfield(fig, 'numeric', 'Position', [200, 200, 100, 20], 'Value', 45); % Default 45 degrees

    % Add a button to run the simulation
    runButton = uibutton(fig, 'push', 'Position', [150, 100, 100, 40], 'Text', 'Run Simulation');
    runButton.ButtonPushedFcn = @(btn, event) run_simulation(powerInput.Value, elevationInput.Value); 
end

function run_simulation(transmissionPower, elevationAngle)
    % Close the GUI once the simulation starts
    close(findall(0, 'Type', 'figure', 'Name', '6G Network Simulation Parameters'));

    % Define Parameters
    area_length = 110; % Length of the area (km)
    area_width = 50; % Width of the area (km)
    spot_beam_diameter = 50 / cosd(elevationAngle); % Adjust NTN spot beam diameter based on elevation
    tn_base_station_radius = 5; % Radius of TN base station cells (km)
    num_ues_per_base_station = 25; % Number of UEs per base station

    % Bandwidth and Noise Power
    bandwidth = 50e6; % 50 MHz
    noise_power_dbm = -174 + 10 * log10(bandwidth); % Thermal noise power in dBm

    % Create Figure
    figure;
    hold on;
    axis([0 area_length 0 area_width]);
    xlabel('Distance (km)');
    ylabel('Distance (km)');
    title('6G Network: Satellite and Terrestrial Network Coverage with UE Journey');
    grid on;

    % Plot NTN Spot Beams
    spot_beam_centers = [30, 25; 80, 25]; % positions of NTN spot beams
    theta = linspace(0, 2*pi, 100);
    x = spot_beam_diameter / 2 * cos(theta);
    y = spot_beam_diameter / 2 * sin(theta);

    for i = 1:size(spot_beam_centers, 1)
        fill(spot_beam_centers(i, 1) + x, spot_beam_centers(i, 2) + y, 'b', 'FaceAlpha', 0.3);
        text(spot_beam_centers(i, 1), spot_beam_centers(i, 2), sprintf('NTN %d', i), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'Color', 'blue');
    end

    % Plot TN Base Stations
    tn_base_stations = [10, 25; 40, 25; 70, 25; 100, 25]; % positions of TN base stations
    for i = 1:size(tn_base_stations, 1)
        rectangle('Position', [tn_base_stations(i, 1) - tn_base_station_radius, tn_base_stations(i, 2) - tn_base_station_radius, 2*tn_base_station_radius, 2*tn_base_station_radius], ...
                  'Curvature', [1, 1], 'FaceColor', 'g', 'FaceAlpha', 0.3);
        text(tn_base_stations(i, 1), tn_base_stations(i, 2), sprintf('TN %d', i), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'Color', 'green');
        
        % 25 UEs randomly distributed within each TN base station cell
        ue_positions = tn_base_stations(i, :) + (rand(num_ues_per_base_station, 2) - 0.5) * 2 * tn_base_station_radius;
        plot(ue_positions(:, 1), ue_positions(:, 2), 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'red');
    end

    % Simulate and Plot User Equipment (UE) Movement along the path
    rng(1); % Seed for reproducibility

    % Define user path (train route) for movement scenarios
    curvy_path_x = linspace(0, area_length, 100); % X position moves horizontally
    curvy_path_y = 25 * ones(1, 100); % Y position remains constant for straight movement

    % Add curves to simulate movement scenarios (to test where's the optimal route that covers wanted scenarios)
    curvy_path_y(20:30) = curvy_path_y(20:30) + linspace(0, 5, 11); % Slight curve up
    curvy_path_y(40:50) = curvy_path_y(40:50) - linspace(0, 5, 11); % Slight curve down
    curvy_path_y(70:80) = curvy_path_y(70:80) + linspace(0, 5, 11); % Slight curve up again

    % Plot the path of the moving UE
    plot(curvy_path_x, curvy_path_y, 'k--', 'LineWidth', 1);

    % Initial position of the moving UE on the train path
    ue_position = [curvy_path_x(1), curvy_path_y(1)];
    ue_plot = plot(ue_position(1), ue_position(2), 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'black');

    % Arrays to store SINR and distances
    sinr_ntn_vs_elev = zeros(1, 100);
    sinr_tn_vs_elev = zeros(1, 100);
    sinr_ntn_ue_vs_dist = zeros(1, 100);
    sinr_tn_ue_vs_dist = zeros(1, 100);
    
    elev_angles = linspace(0, 90, 100);
    shortest_distances = zeros(1, 100);  % For shortest distance between NTN UE and TN UEs

    % Variables to store scenario change points
    scenario_points = struct('A', [], 'B', [], 'C', [], 'D', [], 'E', []);

    % Move UE along the trail path
    for i = 1:length(curvy_path_x)
        % Update UE Position along the trail path
        ue_position(1) = curvy_path_x(i);
        ue_position(2) = curvy_path_y(i);

        set(ue_plot, 'XData', ue_position(1), 'YData', ue_position(2));

        % Determine Scenario Based on UE Position
        if ue_position(1) <= 20
            scenario = 'A';
            if isempty(scenario_points.A), scenario_points.A = i; end
            fprintf('Scenario A: UE out of TN interference range at step %d.\n', i);
        elseif ue_position(1) > 20 && ue_position(1) <= 40
            scenario = 'B';
            if isempty(scenario_points.B), scenario_points.B = i; end
            fprintf('Scenario B: UE within TN interference range at step %d.\n', i);
        elseif ue_position(1) > 40 && ue_position(1) <= 60
            scenario = 'C';
            if isempty(scenario_points.C), scenario_points.C = i; end
            fprintf('Scenario C: UE within TN coverage at step %d.\n', i);
        elseif ue_position(1) > 60 && ue_position(1) <= 80
            scenario = 'D';
            if isempty(scenario_points.D), scenario_points.D = i; end
            fprintf('Scenario D: UE out of TN coverage, within interference range at step %d.\n', i);
        else
            scenario = 'E';
            if isempty(scenario_points.E), scenario_points.E = i; end
            fprintf('Scenario E: UE out of TN interference range at step %d.\n', i);
        end

        % Compute SINR values and distances using real models
        [sinr_ntn_vs_elev(i), sinr_tn_vs_elev(i), sinr_ntn_ue_vs_dist(i), sinr_tn_ue_vs_dist(i), shortest_distances(i)] = ...
            calculate_sinr_and_distance(ue_position, spot_beam_centers, tn_base_stations, transmissionPower, noise_power_dbm, bandwidth, elev_angles(i));

        % Update Path Plot
        plot(curvy_path_x(1:i), curvy_path_y(1:i), 'k-', 'LineWidth', 1.5);
        pause(0.1); % Slow down the simulation for visualization
    end

    % Generate the requested plots
    figure;

    % Plot SINR at NTN BS vs Elevation Angle
    subplot(2, 2, 1);
    plot(elev_angles, sinr_ntn_vs_elev, 'b');
    title('SINR at NTN BS vs Elevation Angle');
    xlabel('Elevation Angle (degrees)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes(scenario_points, elev_angles, sinr_ntn_vs_elev);

    % Plot SINR at TN BS vs Elevation Angle
    subplot(2, 2, 2);
    plot(elev_angles, sinr_tn_vs_elev, 'r');
    title('SINR at TN BS vs Elevation Angle');
    xlabel('Elevation Angle (degrees)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes(scenario_points, elev_angles, sinr_tn_vs_elev);

    % Plot SINR at NTN UE vs Shortest Distance to TN UEs
    subplot(2, 2, 3);
    plot(shortest_distances, sinr_ntn_ue_vs_dist, 'g');
    title('SINR at NTN UE vs Distance to TN UEs');
    xlabel('Distance (km)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes(scenario_points, shortest_distances, sinr_ntn_ue_vs_dist);

    % Plot SINR at TN UE vs Shortest Distance to NTN UEs
    subplot(2, 2, 4);
    plot(shortest_distances, sinr_tn_ue_vs_dist, 'm');
    title('SINR at TN UE vs Distance to NTN UEs');
    xlabel('Distance (km)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes(scenario_points, shortest_distances, sinr_tn_ue_vs_dist);

    hold off;
end

% Function to calculate SINR and distance based on real models
function [sinr_ntn, sinr_tn, sinr_ntn_ue, sinr_tn_ue, shortest_distance] = calculate_sinr_and_distance(ue_position, spot_beam_centers, tn_base_stations, transmissionPower, noise_power_dbm, bandwidth, elevation_angle)
    % Calculate distances from UE to spot beams (NTN) and TN base stations
    distances_to_ntn = sqrt(sum((spot_beam_centers - ue_position).^2, 2));
    distances_to_tn = sqrt(sum((tn_base_stations - ue_position).^2, 2));

    % Shortest distance to TN base stations
    shortest_distance = min(distances_to_tn);

    % Free Space Path Loss model (FSPL)
    fspl_ntn = 20 * log10(distances_to_ntn(1)) + 20 * log10(2e9) + 32.44; % Assume 2 GHz for NTN
    fspl_tn = 20 * log10(shortest_distance) + 20 * log10(2e9) + 32.44; % Assume 2 GHz for TN

    % Received signal power at UE (in dBm)
    signal_power_ntn = transmissionPower - fspl_ntn; % NTN signal power
    signal_power_tn = transmissionPower - fspl_tn;   % TN signal power

    % Interference 
    interference_power_dbm = -110; % Assume -110 dBm interference

    % SINR Calculations
    sinr_ntn = signal_power_ntn - 10 * log10(10^(interference_power_dbm/10) + 10^(noise_power_dbm/10)); % SINR for NTN
    sinr_tn = signal_power_tn - 10 * log10(10^(interference_power_dbm/10) + 10^(noise_power_dbm/10));   % SINR for TN

    % SINR vs Distance
    sinr_ntn_ue = signal_power_ntn / shortest_distance;
    sinr_tn_ue = signal_power_tn / shortest_distance;
end

% Function to mark scenario changes on the plots
function mark_scenario_changes(scenario_points, x_values, y_values)
    % Define a structure of colors for each scenario
    scenario_colors = struct('A', 'r', 'B', 'g', 'C', 'b', 'D', 'm', 'E', 'c');

    % Mark each scenario change point
    scenarios = fieldnames(scenario_points);
    for i = 1:numel(scenarios)
        scenario = scenarios{i};
        point_idx = scenario_points.(scenario);
        if ~isempty(point_idx)
            plot(x_values(point_idx), y_values(point_idx), 'o', 'MarkerSize', 8, 'MarkerFaceColor', scenario_colors.(scenario));
            text(x_values(point_idx), y_values(point_idx), scenario, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
        end
    end
end

% Call the main function to run the GUI
run_network_simulation();

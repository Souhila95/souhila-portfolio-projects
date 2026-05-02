

function run_full_simulation()
    % Create GUI for setting parameters
    create_gui();
end

% Function to create GUI
function create_gui()
    % Create a UI figure for simulation parameters
    fig = uifigure('Name', '6G Network Simulation Parameters', 'Position', [500, 500, 400, 300]);

    % Transmission Power input field
    lbl1 = uilabel(fig, 'Position', [20, 250, 150, 20], 'Text', 'Transmission Power (dBm):');
    powerInput = uieditfield(fig, 'numeric', 'Position', [200, 250, 100, 20], 'Value', 30); % Default 30 dBm

    % Elevation Angle input field
    lbl2 = uilabel(fig, 'Position', [20, 200, 150, 20], 'Text', 'Elevation Angle (degrees):');
    elevationInput = uieditfield(fig, 'numeric', 'Position', [200, 200, 100, 20], 'Value', 45); % Default 45 degrees

    % Add button to run the simulation
    runButton = uibutton(fig, 'push', 'Position', [150, 100, 100, 40], 'Text', 'Run Simulation');
    runButton.ButtonPushedFcn = @(btn, event) run_simulation(powerInput.Value, elevationInput.Value);
end

% Function to run the simulation
function run_simulation(transmissionPower, elevationAngle)
    % Close the GUI once the simulation starts
    close(findall(0, 'Type', 'figure', 'Name', '6G Network Simulation Parameters'));

    % Define Parameters
    train_speed = 250; % Train speed in km/h
    area_length = 110; % Length of the area (km)
    area_width = 50; % Width of the area (km)
    spot_beam_diameter = 50 / cosd(elevationAngle); % NTN spot beam diameter based on elevation
    tn_base_station_radius = 5; % Radius of TN base station cells (km)

    % Operating Bandwidth and Frequency
    bandwidth = 50e6; % 50 MHz
    noise_power_dbm = -174 + 10 * log10(bandwidth); % Thermal noise power in dBm
    ntn_uplink_power = transmissionPower; % Using the transmission power set in the GUI

    % Create Figure for the simulation
    figure;
    hold on;
    axis([0 area_length 0 area_width]);
    xlabel('Distance (km)');
    ylabel('Distance (km)');
    title('6G Network with Spectrum Sensing: NTN UE on Moving Train');
    grid on;

    % Plot NTN and TN Cells
    ntn_cells = [10, 25; 90, 25]; % NTN cells 1 and 2
    tn_cells = [20, 25; 40, 25; 60, 25; 80, 25];  % TN base stations

    % Plot NTN Spot Beams (Cell 1 and Cell 2)
    theta = linspace(0, 2*pi, 100);
    x = spot_beam_diameter / 2 * cos(theta);
    y = spot_beam_diameter / 2 * sin(theta);

    for i = 1:size(ntn_cells, 1)
        fill(ntn_cells(i, 1) + x, ntn_cells(i, 2) + y, 'b', 'FaceAlpha', 0.3);
        text(ntn_cells(i, 1), ntn_cells(i, 2), sprintf('NTN %d', i), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'Color', 'blue');
    end

    % Plot TN Base Stations and Users
    for i = 1:size(tn_cells, 1)
        rectangle('Position', [tn_cells(i, 1) - tn_base_station_radius, tn_cells(i, 2) - tn_base_station_radius, 2*tn_base_station_radius, 2*tn_base_station_radius], ...
                  'Curvature', [1, 1], 'FaceColor', 'g', 'FaceAlpha', 0.3);
        text(tn_cells(i, 1), tn_cells(i, 2), sprintf('TN %d', i), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'Color', 'green');
        % Generate 25 users around each base station within the radius
        users = tn_cells(i, :) + tn_base_station_radius * (rand(25, 2) - 0.5); % Randomly distribute 25 users around each BS
        plot(users(:, 1), users(:, 2), 'ro', 'MarkerSize', 4, 'MarkerFaceColor', 'red');
    end

    % Plot the rail route where the UE moves
    train_path_x = linspace(0, 100, 100); % Train moves from 0 to 100 on x-axis
    train_path_y = 25 * ones(1, 100);     % Train stays at y = 25 
    plot(train_path_x, train_path_y, 'k--', 'LineWidth', 1.5); % Plot the rail route

    % Simulate Train Movement and Visualize UE
    [sinr_ntn_vs_elev, sinr_tn_vs_elev, shortest_distances, sinr_ntn_ue_vs_dist, sinr_tn_ue_vs_dist, scenario_change_points] = simulate_train_movement(ntn_cells, tn_cells, transmissionPower, noise_power_dbm, train_path_x, train_path_y, train_speed);
    
    % Plot SINR vs Elevation Angle
    figure;
    
    subplot(2, 2, 1);
    plot(0:90, sinr_ntn_vs_elev, 'b');
    title('SINR at NTN BS vs Elevation Angle');
    xlabel('Elevation Angle (degrees)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes_on_plot(scenario_change_points, 0:90, sinr_ntn_vs_elev);

    subplot(2, 2, 2);
    plot(0:90, sinr_tn_vs_elev, 'r');
    title('SINR at TN BS vs Elevation Angle');
    xlabel('Elevation Angle (degrees)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes_on_plot(scenario_change_points, 0:90, sinr_tn_vs_elev);
    
    % Plot SINR vs Shortest Distance
    subplot(2, 2, 3);
    plot(shortest_distances, sinr_ntn_ue_vs_dist, 'g');
    title('SINR at NTN UE vs Distance to TN UEs');
    xlabel('Distance (km)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes_on_plot(scenario_change_points, shortest_distances, sinr_ntn_ue_vs_dist);
    
    subplot(2, 2, 4);
    plot(shortest_distances, sinr_tn_ue_vs_dist, 'm');
    title('SINR at TN UE vs Distance to NTN UEs');
    xlabel('Distance (km)');
    ylabel('SINR (dB)');
    hold on;
    mark_scenario_changes_on_plot(scenario_change_points, shortest_distances, sinr_tn_ue_vs_dist);
    
    % Display spectrum sensing results
    disp('=== Spectrum Sensing Results ===');
    for i = 1:length(train_path_x)
        if scenario_change_points.A == i
            disp('Scenario A: Spectrum sharing allowed.');
        elseif scenario_change_points.B == i
            disp('Scenario B: Spectrum sharing NOT allowed due to interference detection.');
        elseif scenario_change_points.C == i
            disp('Scenario C: Handover to TN, spectrum sharing allowed if no other NTN UL signals detected.');
        elseif scenario_change_points.D == i
            disp('Scenario D: Handover to TN, spectrum sharing NOT allowed.');
        elseif scenario_change_points.E == i
            disp('Scenario E: Spectrum sharing allowed.');
        end
    end
end

% Function to simulate the train movement and handovers
function [sinr_ntn_vs_elev, sinr_tn_vs_elev, shortest_distances, sinr_ntn_ue_vs_dist, sinr_tn_ue_vs_dist, scenario_change_points] = simulate_train_movement(ntn_cells, tn_cells, transmissionPower, noise_power_dbm, train_path_x, train_path_y, train_speed)
    % Plot train (UE) position
    ue_plot = plot(train_path_x(1), train_path_y(1), 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'black');
    
    % Variables for SINR and distances
    sinr_ntn_vs_elev = zeros(1, 91);
    sinr_tn_vs_elev = zeros(1, 91);
    sinr_ntn_ue_vs_dist = zeros(1, 100);
    sinr_tn_ue_vs_dist = zeros(1, 100);
    shortest_distances = zeros(1, 100);
    
    elev_angles = linspace(0, 90, 100);

    scenario_change_points = struct('A', [], 'B', [], 'C', [], 'D', [], 'E', []);

    for i = 1:length(train_path_x)
        ue_position = [train_path_x(i), train_path_y(i)];
        set(ue_plot, 'XData', ue_position(1), 'YData', ue_position(2)); % Update UE position

        % Scenario logic and marking the points of change
        if ue_position(1) <= 20
            % Scenario A
            interference_power = -Inf; % No interference in Scenario A
            if isempty(scenario_change_points.A), scenario_change_points.A = i; end
            disp('Scenario A: UE out of TN interference range. NTN UL transmissions cannot interfere with TN DL.');
        elseif ue_position(1) > 20 && ue_position(1) <= 40
            % Scenario B
            interference_power = -110; % interference for Scenario B
            if isempty(scenario_change_points.B), scenario_change_points.B = i; end
            disp('Scenario B: UE within TN interference range. NTN UL transmissions can interfere with TN DL.');
        elseif ue_position(1) > 40 && ue_position(1) <= 60
            % Scenario C
            interference_power = 0; % Handed over to TN, no interference if no other NTN UL signals detected
            if isempty(scenario_change_points.C), scenario_change_points.C = i; end
            disp('Scenario C: UE handed over to TN cell 1. TN is allowed to share if no NTN UL signals are detected.');
        elseif ue_position(1) > 60 && ue_position(1) <= 80
            % Scenario D
            interference_power = -110; % Simplified constant interference for Scenario D
            if isempty(scenario_change_points.D), scenario_change_points.D = i; end
            disp('Scenario D: UE handed over to TN cell 2. TN is NOT allowed to share.');
        else
            % Scenario E
            interference_power = -Inf; % No interference in Scenario E
            if isempty(scenario_change_points.E), scenario_change_points.E = i; end
            disp('Scenario E: UE out of TN interference range. NTN UL transmissions cannot interfere with TN DL.');
        end

        % Calculate SINR for each elevation angle
        for j = 1:91
            sinr_ntn_vs_elev(j) = calculate_sinr(transmissionPower, elev_angles(j), noise_power_dbm, interference_power);
            sinr_tn_vs_elev(j) = calculate_sinr(transmissionPower, elev_angles(j), noise_power_dbm, interference_power);
        end
        
        % Calculate SINR based on distance
        shortest_distances(i) = abs(train_path_x(i) - tn_cells(1, 1)); % Example distance calculation to nearest TN
        sinr_ntn_ue_vs_dist(i) = transmissionPower / shortest_distances(i);
        sinr_tn_ue_vs_dist(i) = transmissionPower / shortest_distances(i);

        % Simulate real-time movement
        pause(0.1);
    end
end

% Function to mark scenario change points on the SINR plots
function mark_scenario_changes_on_plot(scenario_points, x_values, y_values)
    % Define scenario colors for marking
    scenario_colors = struct('A', 'r', 'B', 'g', 'C', 'b', 'D', 'm', 'E', 'c');
    
    % Plot scenario changes
    scenarios = fieldnames(scenario_points);
    for i = 1:numel(scenarios)
        scenario = scenarios{i};
        point_idx = scenario_points.(scenario);
        if ~isempty(point_idx)
            hold on;
            plot(x_values(point_idx), y_values(point_idx), 'o', 'MarkerSize', 8, 'MarkerFaceColor', scenario_colors.(scenario));
            text(x_values(point_idx), y_values(point_idx), scenario, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
            hold off;
        end
    end
end

% Function to calculate SINR with interference
function sinr = calculate_sinr(transmissionPower, elevationAngle, noise_power_dbm, interference_power)
    % Free Space Path Loss model (FSPL) based on distance and elevation angle
    path_loss = 20 * log10(1 / cosd(elevationAngle)); % Path loss based on elevation
    signal_power = transmissionPower - path_loss; % Signal power calculation
    sinr = signal_power - 10 * log10(10^(interference_power/10) + 10^(noise_power_dbm/10)); % SINR calculation
end

% Call the main function to run the full simulation
run_full_simulation();


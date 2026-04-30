function [nextState, reward, isDone] = batteryEnvironment(state, action)
    % Declare global variables
    global pv_power_data load_power_data;

    % Declare persistent variable for simulation step
    persistent simStep;
    if isempty(simStep)
        simStep = 1; % Initialize simulation step
    end

    % Ensure we don't exceed the data size
    if simStep > length(pv_power_data) || simStep > length(load_power_data)
        error('Simulation step exceeds available data.');
    end

    % Get current PV power and load power
    pv_power = pv_power_data(simStep);
    load_Power = load_power_data(simStep);

    % Extract state variables
    Bat_soc = state(3);        % Battery state of charge
    bat_voltage = state(4);    % Battery voltage

    % Constants
    SOC_min = 20;              % Minimum SOC
    SOC_max = 90;              % Maximum SOC
    battery_capacity = 100;    % Battery capacity in kWh
    step_time = 1;             % Time step in hours

    % Update battery SOC
    current = action;  % Current (A) determined by the agent
    energyChange = current * bat_voltage * step_time / 1000; % Energy change in kWh
    Bat_soc = Bat_soc + energyChange / battery_capacity * 100;

    % Reward logic
    if pv_power > load_Power
        if Bat_soc >= SOC_max
            reward = 10;  % Reward for correctly not charging the battery
        else
            reward = 5;  % Reward for charging the battery
        end
    else
        if Bat_soc > SOC_min
            reward = 5;  % Reward for discharging the battery
        else
            reward = -10; % Penalty for importing from the grid
        end
    end

    % Terminal condition
    isDone = (Bat_soc < SOC_min || Bat_soc > SOC_max);

    % Next state
    nextState = [pv_power, load_Power, Bat_soc, bat_voltage];

    % Increment simulation step
    simStep = simStep + 1;
    if simStep > length(pv_power_data) || simStep > length(load_power_data)
        isDone = true; % End simulation if data runs out
    end
end

% Create Fuzzy Inference System
fis = mamfis('Name','Fuzzy_MPPTT');

% Define Input: Change in Power (dP)
fis = addInput(fis,[-1 1],'Name','dP');
fis = addMF(fis,'dP','trimf',[-1 -0.5 0],'Name','Negative');
fis = addMF(fis,'dP','trimf',[-0.5 0 0.5],'Name','Zero');
fis = addMF(fis,'dP','trimf',[0 0.5 1],'Name','Positive');

% Define Input: Change in Voltage (dV)
fis = addInput(fis,[-1 1],'Name','dV');
fis = addMF(fis,'dV','trimf',[-1 -0.5 0],'Name','Negative');
fis = addMF(fis,'dV','trimf',[-0.5 0 0.5],'Name','Zero');
fis = addMF(fis,'dV','trimf',[0 0.5 1],'Name','Positive');

% Define Output: Change in Duty Cycle (dD)
fis = addOutput(fis,[-0.05 0.05],'Name','dD');
fis = addMF(fis,'dD','trimf',[-0.05 -0.025 0],'Name','Decrease');
fis = addMF(fis,'dD','trimf',[-0.025 0 0.025],'Name','Zero');
fis = addMF(fis,'dD','trimf',[0 0.025 0.05],'Name','Increase');

% Define Rule Base
rules = [...
    "IF dP is Positive AND dV is Positive THEN dD is Decrease";
    "IF dP is Positive AND dV is Negative THEN dD is Increase";
    "IF dP is Negative AND dV is Positive THEN dD is Increase";
    "IF dP is Negative AND dV is Negative THEN dD is Decrease";
    "IF dP is Zero THEN dD is Zero"];
fis = addRule(fis, rules);

% Convert FIS for Simulink Code Generation
fisCodeGenData = getFISCodeGenerationData(fis);

% Save to a .mat file for use in Simulink
save('Fuzzy_MPPT_CG.mat', 'fisCodeGenData');

disp('FIS saved successfully for Simulink compatibility.');

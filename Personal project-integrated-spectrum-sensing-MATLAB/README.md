Integrated TN/NTN Spectrum Sharing Simulation
Spectrum Sensing-Enabled Reverse Pairing | MATLAB | Personal Research Project 2024

Overview
This project implements a conceptual simulation of spectrum sensing-enabled reverse pairing between a LEO satellite Non-Terrestrial Network (NTN) segment and a terrestrial 5G network (TN), exploring the coexistence challenge central to 6G system design under 3GPP Release 17/18.
The simulation models coordinated spectrum sharing in a shared frequency band, where TN downlink and NTN uplink operate in opposite directions (reverse pairing), and spectrum sensing nodes at TN base stations dynamically manage interference.
System Architecture
Network Setup:

Geographic area: 110 km × 50 km
NTN segment: 2 quasi-earth-fixed LEO spot beams (50 km diameter, elevation-angle-dependent)
TN segment: 4 base stations (5 km radius, 25 UEs each)
Mobile UE: High-speed train (250 km/h) on defined rail route
Shared frequency band: Band n1 (NTN uplink 1920–1980 MHz / TN downlink uses NTN uplink band)
Bandwidth: 50 MHz

Five Test Scenarios (A–E):
ScenarioConditionSpectrum SharingAUE out of TN interference rangeAllowedBUE within TN interference rangeBlockedCUE handed over to TNConditionalDUE out of coverage, within interference rangeBlockedEUE out of TN interference rangeAllowed

Implementation Steps
Baseline Version (Baseline.m):

Step 1: Integrated TN/NTN network construction with rail route and mobility simulation
Step 2: Baseline reverse pairing with GUI, RSRP-based handover, SINR performance evaluation

Proposed Version (proposed.m):

Step 3: Spectrum sensing nodes added to each TN base station (receiver-only nodes)
Step 4: Energy detection-based sensing with periodic sensing schedule and spectrum management
Step 5: Performance comparison baseline vs proposed — SINR analysis across all scenarios


Performance Metrics

SINR at NTN BS vs elevation angle of TN BS
SINR at TN BS vs elevation angle of TN BS
SINR at NTN UE vs shortest distance to TN UEs
SINR at TN UE vs shortest distance to NTN UEs
Spectrum sensing decisions per scenario (sharing allowed / blocked)


How to Run
Requirements: MATLAB (R2021a or later recommended)
Steps:

Clone or download the repository
Open MATLAB and navigate to the project folder
Ensure all class files are in the same directory as the main scripts
Run Baseline.m for the baseline simulation
Run proposed.m for the proposed spectrum sensing-enabled simulation
A GUI will launch — set Transmission Power (dBm) and Elevation Angle (degrees), then click Run Simulation

Scope & Limitations
This is a conceptual-level simulation implementing reverse pairing logic, spectrum sensing decisions, and SINR analysis from first principles using custom MATLAB classes and a Free-Space Path Loss (FSPL) model.
It does not use MATLAB's 5G Toolbox, Satellite Communications Toolbox, or Wireless Network Simulation Library. A full 3GPP-compliant system-level implementation would require these toolboxes for accurate PHY-layer modelling, true system-level handover, and standard-compliant channel models.

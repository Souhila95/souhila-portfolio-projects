# Project 15: UAV Network Optimization — MILP + Greedy

Domain: Optimization / UAV Systems / MATLAB

Files:
- UAEnvironment.m — UAV-Sensor environment with 20-action 
  discretized movement system (step method)
- milpfinalcode.m — MILP optimization (YALMIP/intlinprog) 
  with binary variables si, bij, uj
- uavmovingcoordinates.m — UAV trajectory and parameter 
  calculation (Tij, Eij, dij)
- linearization.m — Taylor series linearization of 
  distance, time and energy
- newopt.m — Final optimized version with coordinate output

Requirements: MATLAB R2022a, YALMIP toolbox, 
Optimization Toolbox (intlinprog)

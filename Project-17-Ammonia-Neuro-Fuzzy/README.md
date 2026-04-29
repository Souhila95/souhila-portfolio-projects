# Project 17: Advanced Hybrid Control System for Ammonia Synthesis

Domain: Industrial Control / Neuro-Fuzzy / MATLAB / TIA Portal

Files:
- ammoniaprocesspro.m — Ammonia process differential equations,
  state-space and transfer function modeling
- processfinal.m — Main training code: ANFIS + neural network
  controller + combined neuro-fuzzy control loop
- statevariablesplots.m — State variable visualization
- temperaturechanges.m — Temperature control signal plotting
- ammoniawithfuzzynew.slx — Simulink model integrating
  full hybrid control system

Usage: Run ammoniaprocesspro.m first to generate process data,
then processfinal.m for model training and control simulation.

Requirements: MATLAB R2021a or later, Fuzzy Logic Toolbox,
Neural Network Toolbox, Simulink

Note: TIA Portal HMI/SCADA project files available on request.

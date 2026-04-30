# Project 23: ANN-Based MPPT — P&O vs Fuzzy vs ANN

Domain: Solar Energy / MPPT / MATLAB Simulink

Files:
- mpptfinal.slx — Main Simulink model (3 switchable controllers)
- systemdesigncode2.m — Run first to set parameters
- ANNtrainingcode.m — ANN training script
- fuzzy.m — Fuzzy logic FIS builder

Usage: Run systemdesigncode2.m first, open vaultofmymppt.mat
and Fuzzy_MPPT_CG.mat, then run mpptfinal.slx.
Uncomment desired controller to switch between methods.

Requirements: MATLAB R2023b+, Simulink, Fuzzy Logic Toolbox,
Deep Learning Toolbox

# Project 24: ANN Horse Claim Predictor — MATLAB

Domain: Machine Learning / Classification / MATLAB

Files:
- ANNmodeldeployment.asv — Main ANN deployment and 
  prediction script (feedforward backpropagation)
- goodnetmodel.mat — Best trained ANN model 
  (87-89% accuracy, full dataset)
- 200kmodeldata.mat — Training data batch (200K rows,
  13 input features)
- trainingdata5000.mat — Initial small batch training 
  data (5K rows, used for early trials)
- trainingplustestdata.mat — Combined training and 
  testing dataset for model validation

Usage:
1. Open MATLAB and add all files to path
2. Load preferred model: load('goodnetmodel.mat')
3. Run ANNmodeldeployment.asv to perform predictions
   on new input data

Network Architecture:
- Type: Feedforward Backpropagation ANN
- Inputs: 13 features per horse record
- Output: Binary classification (claimed / not claimed)
- Training: Multiple sessions across batch sizes
  5K → 26K → 200K+ rows
- Best accuracy: 87-89% on full dataset

Note: Excel VBA workbook deliverables and proprietary 
client data are not included in this repository.

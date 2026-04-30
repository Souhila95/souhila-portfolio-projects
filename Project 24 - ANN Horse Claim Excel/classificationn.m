%%%%
% Define possible threshold values
thresholds = linspace(0, 1, 100); % 100 values between 0 and 1
best_F1 = 0;
best_MCC = 0;
best_thresh_F1 = 0;
best_thresh_MCC = 0;

for t = thresholds
    % Convert probabilities to binary classification
    predicted_labels = estimebp >= t;

    % Compute Confusion Matrix Components
    TP = sum((predicted_labels == 1) & (newtarget == 1)); % True Positives
    TN = sum((predicted_labels == 0) & (newtarget == 0)); % True Negatives
    FP = sum((predicted_labels == 1) & (newtarget == 0)); % False Positives
    FN = sum((predicted_labels == 0) & (newtarget == 1)); % False Negatives

    % Precision and Recall
    precision = TP / (TP + FP);
    recall = TP / (TP + FN);

    % F1 Score
    F1_score = 2 * (precision * recall) / (precision + recall);

    % Matthews Correlation Coefficient (MCC)
    MCC = ((TP * TN) - (FP * FN)) / sqrt((TP + FP) * (TP + FN) * (TN + FP) * (TN + FN));

    % Track best thresholds
    if F1_score > best_F1
        best_F1 = F1_score;
        best_thresh_F1 = t;
    end
    if MCC > best_MCC
        best_MCC = MCC;
        best_thresh_MCC = t;
    end
end

% Display Results
fprintf('Best Threshold (F1-score): %.4f (F1 = %.4f)\n', best_thresh_F1, best_F1);
fprintf('Best Threshold (MCC): %.4f (MCC = %.4f)\n', best_thresh_MCC, best_MCC);


%%%
% Calculate the accuracy
pctErrorbp = mean(abs(estimebp - newtarget)); % error rate
accuracy = (1 - pctErrorbp) * 100; % accuracy percentage
disp(['Global Accuracy: ', num2str(accuracy), '%']);

% Calculate the average error 
error = abs(estimebp - newtarget); % absolute error for each data point
avgError = mean(error(:)); % mean of all errors

% Calculate the average accuracy
accuracy = (1 - avgError) * 100; % accuracy percentage

% Display average error and accuracy
disp(['Average Error: ', num2str(avgError)]);
disp(['Average Accuracy: ', num2str(accuracy), '%']);

%%%%%ASSESS performace
 MAE = mean(abs(estimebp - newtarget));
fprintf('Mean Absolute Error (MAE): %.4f\n', MAE);
 MSE = mean((estimebp - newtarget).^2);
fprintf('Mean Squared Error (MSE): %.4f\n', MSE);
 RMSE = sqrt(MSE);
fprintf('Root Mean Squared Error (RMSE): %.4f\n', RMSE);
R = corrcoef(estimebp, newtarget);
fprintf('Correlation Coefficient (R-value): %.4f\n', R(1,2));
 figure;
plotconfusion(newtarget, estimebp);
title('Confusion Matrix for Neural Network Predictions');
%threshold = best_thresh_F1;
threshold = 0.22;
predicted_labels = estimebp >= threshold;  % Convert to binary (1 or 0)
correct_predictions = sum(predicted_labels == newtarget);
accuracy = (correct_predictions / length(newtarget)) * 100;
fprintf('Classification Accuracy: %.2f%%\n', accuracy);

% Compute estimated probabilities for claiming a horse
probability_claimed = estimebp * 100;  % Convert to percentage
%threshold = best_thresh_F1;  % Decision threshold

% Convert probabilities to binary classifications (1 = Claimed, 0 = Not Claimed)
predicted_classes = estimebp >= threshold;

% Compute classification accuracy
classification_accuracy = mean(predicted_classes == newtarget) * 100;

% Count the number of correctly predicted "Claimed" (1s)
true_positives = sum((predicted_classes == 1) & (newtarget == 1));

% Display classification accuracy
fprintf('Classification Accuracy: %.2f%%\n', classification_accuracy);

% Display True Positives count
fprintf('Correctly Predicted "Claimed" Cases (True Positives): %d\n', true_positives);
%%%

%%% Classification metrics
% Define threshold for classification
%threshold = best_thresh_F1; % Standard threshold for binary classification
predicted_labels = estimebp >= threshold; % Convert predictions to binary values

% Compute Confusion Matrix Components
TP = sum((predicted_labels == 1) & (newtarget == 1)); % True Positives
TN = sum((predicted_labels == 0) & (newtarget == 0)); % True Negatives
FP = sum((predicted_labels == 1) & (newtarget == 0)); % False Positives
FN = sum((predicted_labels == 0) & (newtarget == 1)); % False Negatives

% Display Confusion Matrix Values
fprintf('True Positives (TP): %d\n', TP);
fprintf('True Negatives (TN): %d\n', TN);
fprintf('False Positives (FP): %d\n', FP);
fprintf('False Negatives (FN): %d\n', FN);

%%%%

% Precision (Positive Predictive Value)
precision = TP / (TP + FP);
fprintf('Precision: %.4f\n', precision);

% Recall (Sensitivity or True Positive Rate)
recall = TP / (TP + FN);
fprintf('Recall: %.4f\n', recall);

% Specificity (True Negative Rate)
specificity = TN / (TN + FP);
fprintf('Specificity: %.4f\n', specificity);

% F1 Score (Harmonic mean of precision and recall)
F1_score = 2 * (precision * recall) / (precision + recall);
fprintf('F1 Score: %.4f\n', F1_score);

% Accuracy (Overall classification performance)
accuracy = (TP + TN) / (TP + TN + FP + FN);
fprintf('Accuracy: %.4f\n', accuracy * 100);
%%%

MCC = ((TP * TN) - (FP * FN)) / sqrt((TP + FP) * (TP + FN) * (TN + FP) * (TN + FN));
fprintf('Matthews Correlation Coefficient (MCC): %.4f\n', MCC);
%%%%
[X, Y, T, AUC] = perfcurve(newtarget, estimebp, 1);
figure;
plot(X, Y);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title(sprintf('ROC Curve (AUC = %.4f)', AUC));
grid on;
fprintf('AUC (Area Under ROC Curve): %.4f\n', AUC);
%%%

[prec, rec, ~] = perfcurve(newtarget, estimebp, 1, 'xCrit', 'reca', 'yCrit', 'prec');
figure;
plot(rec, prec);
xlabel('Recall');
ylabel('Precision');
title('Precision-Recall Curve');
grid on;
%%%
cm = [TP, FN; FP, TN];
heatmap({'Positive', 'Negative'}, {'Positive', 'Negative'}, cm, 'Title', 'Confusion Matrix');

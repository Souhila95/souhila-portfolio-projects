%%%Probability percentage

% Compute estimated probabilities for claiming a horse
probability_claimed = estimebp * 100;  % Convert to percentage
threshold = 0.3;  % Decision threshold

% Convert probabilities to binary classifications (1 = Claimed, 0 = Not Claimed)
predicted_classes = estimebp >= threshold;

% Display sample estimated probabilities (First 100)
fprintf('Sample Estimated Probabilities of Claiming a Horse (First 100 Samples):\n');
disp(probability_claimed(1:100)');

% Compute and display classification accuracy
classification_accuracy = mean(predicted_classes == outputs) * 100;
fprintf('Classification Accuracy: %.2f%%\n', classification_accuracy);

% Display classification results for the first 100 samples
fprintf('Classification Results (First 100 Samples):\n');
for i = 1:100
    status = "Not Claimed";
    if predicted_classes(i) == 1
        status = "Claimed";
    end
    fprintf('Horse %d: %s (%.2f%%)\n', i, status, probability_claimed(i));
end

% Compute estimated probabilities for claiming a horse
%probability_claimed = estimebp * 100;  % Convert to percentage
%threshold = 0.5;  % Decision threshold

% Convert probabilities to binary classifications (1 = Claimed, 0 = Not Claimed)
predicted_classes = estimebp >= threshold;

% Compute classification accuracy
classification_accuracy = mean(predicted_classes == outputs) * 100;

% Count True Positives (Correctly predicted "Claimed" cases)
true_positives = sum((predicted_classes == 1) & (outputs == 1));

% Count False Positives (Predicted as "Claimed" but actually "Not Claimed")
false_positives = sum((predicted_classes == 1) & (outputs == 0));

% Count False Negatives (Predicted as "Not Claimed" but actually "Claimed")
false_negatives = sum((predicted_classes == 0) & (outputs == 1));

% Compute Precision: TP / (TP + FP)
if (true_positives + false_positives) == 0
    precision = 0; % Avoid division by zero
else
    precision = (true_positives / (true_positives + false_positives)) * 100;
end

% Compute Recall: TP / (TP + FN)
if (true_positives + false_negatives) == 0
    recall = 0;
else
    recall = (true_positives / (true_positives + false_negatives)) * 100;
end

% Compute F1-score: 2 * (Precision * Recall) / (Precision + Recall)
if (precision + recall) == 0
    f1_score = 0;
else
    f1_score = (2 * (precision * recall) / (precision + recall));
end

% Display classification metrics
fprintf('Classification Accuracy: %.2f%%\n', classification_accuracy);
fprintf('Correctly Predicted "Claimed" Cases (True Positives): %d\n', true_positives);
fprintf('Precision (Correct "Claimed" Predictions): %.2f%%\n', precision);
fprintf('Recall (Correctly Identified Claimed Horses): %.2f%%\n', recall);
fprintf('F1-score (Balanced Precision & Recall): %.2f%%\n', f1_score);



%%%%% PROBABILITY for testing 

% Get network output for the test set
estimetest = net(inputtest);

% Display estimated probabilities
fprintf('Horse Claiming Probabilities for Test Set:\n');
disp(estimetest');

% Convert outputs to binary using threshold
%threshold = 0.5;
predicted_labels_test = estimetest >= threshold;  % 1 if above threshold, 0 otherwise

% Display claiming decision
for i = 1:length(estimetest)
    if predicted_labels_test(i) == 1
        fprintf('Sample %d: %.2f%% - Horse Claimed\n', i, estimetest(i) * 100);
    else
        fprintf('Sample %d: %.2f%% - Horse Not Claimed\n', i, estimetest(i) * 100);
    end
end

% Plot real vs estimated values
figure;
plot(targettest, 'o');
hold on;
plot(estimetest, 'ro');
legend('Real value of test', 'Estimated value of test');
title('Test Set Predictions vs Actual');

% Compute test set accuracy
correct_predictions_test = sum(predicted_labels_test == targettest);
accuracy_test = (correct_predictions_test / length(targettest)) * 100;
fprintf('Test Set Classification Accuracy: %.2f%%\n', accuracy_test);

% Calculate mean absolute error for test set
MAE_test = mean(abs(estimetest - targettest));
%fprintf('Test Set Mean Absolute Error (MAE): %.4f\n', MAE_test);
%%%%%


% Compute True Positives, False Positives, False Negatives for Test Set
true_positives_test = sum((predicted_labels_test == 1) & (targettest == 1));
false_positives_test = sum((predicted_labels_test == 1) & (targettest == 0));
false_negatives_test = sum((predicted_labels_test == 0) & (targettest == 1));

% Compute Precision for Test Set
if (true_positives_test + false_positives_test) == 0
    precision_test = 0;
else
    precision_test = (true_positives_test / (true_positives_test + false_positives_test)) * 100;
end

% Compute Recall for Test Set
if (true_positives_test + false_negatives_test) == 0
    recall_test = 0;
else
    recall_test = (true_positives_test / (true_positives_test + false_negatives_test)) * 100;
end

% Compute F1-score for Test Set
if (precision_test + recall_test) == 0
    f1_score_test = 0;
else
    f1_score_test = (2 * (precision_test * recall_test) / (precision_test + recall_test));
end

% Display performance metrics for Test Set
fprintf('Test Set Precision (Correct "Claimed" Predictions): %.2f%%\n', precision_test);
fprintf('Test Set Recall (Correctly Identified Claimed Horses): %.2f%%\n', recall_test);
fprintf('Test Set F1-score (Balanced Precision & Recall): %.2f%%\n', f1_score_test);

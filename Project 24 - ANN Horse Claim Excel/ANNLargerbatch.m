% 
% % y = [1;1;0;0]';
% % f1 = [0;1;0;1]';
% % f2 = [1;1;0;0]';
% % 
% % inputs = [f1;f2]; % input vector 
% % outputs = [x;y];  % corresponding target output vector
% % input=input';
% % output=output';
% %outputs = targets;  % corresponding target output vector
% % inputs=inputs';
% % outputs=outputs';
% net = newff(minmax(newinput),[60,1],{'logsig','purelin','trainbr'}); %training functions
% 
% net.trainParam.epochs = 500;
% net.trainParam.goal = 1e-6;
% net.trainParam.lr = 0.01;
% 
% net = train(net, newinput, newtarget); %training dataset
% estimebp=net(newinput); % estimated outputs using neural network model
% figure
% plot(newtarget,'o')
% hold on
% plot(estimebp,'ro')
% legend('real value','estimated value')
% pctErrorbp = mean(abs(estimebp-newtarget)); %accuracy ( error rate)
% display(pctErrorbp);
% figure;
% plotconfusion(newtarget, estimebp);
% title('Confusion Matrix for Neural Network Predictions');

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
threshold = 0.22;
predicted_labels = estimebp >= threshold;  % Convert to binary (1 or 0)
correct_predictions = sum(predicted_labels == newtarget);
accuracy = (correct_predictions / length(newtarget)) * 100;
fprintf('Classification Accuracy: %.2f%%\n', accuracy);

%%%%
% Compute estimated probabilities for claiming a horse
probability_claimed = estimebp * 100;  % Convert to percentage
threshold = 0.22;  % Decision threshold

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
% gensim(net);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%TEST%%%%%%%%%%% dataset samples for testing the network
% estimetest=net(inputtest);
% figure
% plot(targettest,'o')
% hold on
% plot(estimetest,'ro')
% legend('real value of test','estimated value of test')
% pctErrortest = mean(abs(estimetest-targettest));
% display(pctErrortest);
% 
% %%% ADDING DATA for training batch
% %%addinputdata
% %Define filename
% filename = 'Meziane0326x.csv';
% 
% % Read the entire numeric data from the CSV file
% fullData = readmatrix(filename);
% 
% % Define row and column indices
% rowRange = 36192:301307;   % Rows from 36192 to 301307
% colIndices = [1, 3:14];   % Columns: A (1), C to N (3 to 14), excluding B (2)
% 
% % Extract the required data
% dataplus = fullData(rowRange, colIndices);
% dataplus = dataplus';
% newinput = [inputs, dataplus];
% 
% %Check the new size
% size(newinput)
% %%% add target data
% %Define column name
% column_name = 'Clm_';  % column name 
% 
% % Extract the required range of rows (36192 to 301307)
% data_test = T.(column_name)(36192:301307);  
% 
% % Convert data to string and trim spaces to avoid formatting issues
% data_test = strtrim(string(data_test));  
% 
% % Convert 'c' to 1 and everything else (including empty cells) to 0
% targetplus = double(data_test == "c");  % 'c' → 1, other → 0
% 
% % Store 'targetplus' in the workspace
% assignin('base', 'targetplus', targetplus);
% 
% % Display confirmation message
% disp('Variable "targetplus" created in workspace with processed data.');
% 
% newtarget = [outputs, targetplus'];
% 
% %Check the new size
% size(newtarget)
 num_ones = sum(newtarget(:)); % Count the number of ones
 disp(num_ones);

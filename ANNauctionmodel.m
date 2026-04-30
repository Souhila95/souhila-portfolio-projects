
% y = [1;1;0;0]';
% f1 = [0;1;0;1]';
% f2 = [1;1;0;0]';
% 
% inputs = [f1;f2]; % input vector 
% outputs = [x;y];  % corresponding target output vector
% input=input';
% output=output';
%outputs = targets;  % corresponding target output vector
% inputs=inputs';
% outputs=outputs';
net = newff(minmax(inputs),[40,1],{'logsig','logsig','trainlm'}); %training functions

net.trainParam.epochs = 1000;
net.trainParam.goal = 1e-25;
net.trainParam.lr = 0.01;

net = train(net, inputs, outputs); %training dataset
estimebp=net(inputs); % estimated outputs using neural network model
figure
plot(outputs,'o')
hold on
plot(estimebp,'ro')
legend('real value','estimated value')
pctErrorbp = mean(abs(estimebp-outputs)); %accuracy ( error rate)
display(pctErrorbp);
figure;
plotconfusion(outputs, estimebp);
title('Confusion Matrix for Neural Network Predictions');

% Calculate the accuracy
pctErrorbp = mean(abs(estimebp - outputs)); % error rate
accuracy = (1 - pctErrorbp) * 100; % accuracy percentage
disp(['Global Accuracy: ', num2str(accuracy), '%']);

% Calculate the average error 
error = abs(estimebp - outputs); % absolute error for each data point
avgError = mean(error(:)); % mean of all errors

% Calculate the average accuracy
accuracy = (1 - avgError) * 100; % accuracy percentage

% Display average error and accuracy
disp(['Average Error: ', num2str(avgError)]);
disp(['Average Accuracy: ', num2str(accuracy), '%']);


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


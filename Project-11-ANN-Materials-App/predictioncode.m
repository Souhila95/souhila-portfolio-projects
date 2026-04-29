
%%%%%%NORMALIZATION OF EACH COLUMN%%%%%%%%%%
% Input1 = normalize(Input1);
% Input2 = normalize(Input2);
% Input3 = normalize(Input3);
% Input4 = normalize(Input4);
% Input5 = normalize(Input5);
% Input6 = normalize(Input6);
% Input7 = normalize(Input7);
% Input8 = normalize(Input8);
% Input9 = normalize(Input9);
% Input10 = normalize(Input10);
% Input11 = normalize(Input11);
% Input12 = normalize(Input12);
% Input13 = normalize(Input13);

%%%%% NORMALIZATION OF THE WHOLE MATRIX ARRAY AT ONCE%%%%%%%%
% inputs = [Input1';Input2';Input3';Input4';Input5';Input6';Input7';Input8';Input9';Input10';Input11';Input12';Input13']; % input vector 

%%Transpose variables
% target=target';
% inputs=inputs';

%%%% atribut the normalized data to there input output files
% inputs=normalize(inputs);
%  target=normalize(target);
inputs = inputs'; % corresponding input vector
target = target'; % corresponding target output vector
 
estimebp=net(inputs); % estimated outputs using neural network model
% figure
% plot(target,'o') % plot original outputs ( original temperature values)
% hold on
% plot(estimebp,'r*') %plot new estimated temperature data
% legend('real value','estimated value')
% pctErrorbp = mean(abs(estimebp-target)); % Calculate accuracy ( error rate)
% display(pctErrorbp); % show accuracy rate value
% gensim(net); % generate a ANN simulink model
finalestimation=estimebp*1000; % getting the final temperature values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%TEST%%%%%%%%%%% dataset samples for testing the network
% estimetest=net(sample1);
% figure
% plot(sampleop1)
% hold on
% plot(estimetest,'ro')
% legend('real value of test','estimated value of test')
% pctErrortest = mean(abs(estimetest-sampleop1));
% display(pctErrortest);

% 


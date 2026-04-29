close all
% y = [1;1;0;0]';
% f1 = [0;1;0;1]';
% f2 = [1;1;0;0]';
% 
% inputs = [f1;f2]; % input vector 
% outputs = [x;y];  % corresponding target output vector
% input=input';
% output=output';
net = newff(minmax(norinput),[80,1],{'logsig','purelin','trainlm'}); %training functions

net.trainParam.epochs = 5000;
net.trainParam.goal = 1e-25;
net.trainParam.lr = 0.01;

net = train(net, norinput, nortarget); %training dataset
norestimebp=net(norinput); % estimated outputs using neural network model
figure
plot(nortarget)
hold on
plot(norestimebp,'r')
legend('real value','estimated value')
pctErrorbp = mean(abs(norestimebp-nortarget)); %accuracy ( error rate)
display(pctErrorbp);
% gensim(net);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%TEST%%%%%%%%%%% dataset samples for testing the network
estimetest=net(nortestinput);
figure
plot(nortesttarget)
hold on
plot(estimetest,'r')
legend('real value of test','estimated value of test')
pctErrortest = mean(abs(estimetest-sampleop1));
display(pctErrortest);



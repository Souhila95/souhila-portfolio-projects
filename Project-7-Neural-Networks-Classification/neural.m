clear all; close all; clc;
x = [0;1;0;1]';
y = [1;1;0;0]';
f1 = [0;1;0;1]';
f2 = [1;1;0;0]';

inputs = [f1;f2]; % input vector 
outputs = [x;y];  % corresponding target output vector

net = newff(minmax(inputs),[40,2],{'logsig','purelin','trainlm'});

net.trainParam.epochs = 800;
net.trainParam.goal = 1e-25;
net.trainParam.lr = 0.01;

net = train(net, inputs, outputs);


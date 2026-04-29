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
% Input14 = normalize(Input14);
% Input15 = normalize(Input15);
% Input16 = normalize(Input16);
% 
% 
% Test = [Input1';Input2';Input3';Input4';Input5';Input6';Input7';Input8';Input9';Input10';Input11';Input12';Input13';Input14';Input15';Input16']; % input vector 
% Test = normalize(Test);
Test=Testdata;
Test=Test';
%  Classification = Classification';
estime=net(Test); % estimated outputs using neural network model

% figure
% plot(Classification)
% hold on
% plot(estime,'r')
% legend('real value','estimated value')
% pctErrorbp = mean(abs(estime-Classification)); %accuracy ( error rate)
% display(pctErrorbp);
estime=estime'
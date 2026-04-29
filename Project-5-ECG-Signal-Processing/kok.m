load mydataset %Loading our program 
figure
% plot(time,ECGsignals) %plot ECG signals vs time

% plot(time,ECGsignals,'b')
hold on

% plot(time,F,'r','linewidth',2)
% % plot(time,abs(ECGsignals).^2,'g')
plot(time(EXann),ECGsignals(EXann),'mo','markerfacecolor',[1 0 0])%plot time vs ECG signals with annotations 
set(gca,'xlim',[10.2 12])% returns the handle to the current axis
windowSize = 5; 
b = (1/windowSize)*ones(1,windowSize);
a = 1;
y = filter(b,a,ECGsignals)

% plot(time,ECGsignals)
hold on
plot(time,y)
% legend('Input Data','Filtered Data')

xlabel('time(s)')
ylabel('voltage(mv)')
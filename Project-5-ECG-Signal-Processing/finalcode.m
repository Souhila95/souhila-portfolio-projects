load mydataset %Loading our program 
figure
plot(time,ECGsignals) %plot ECG signals vs time
hold on
plot(time(EXann),ECGsignals(EXann),'r*')% plot ECG signals with expert annotations
qrsEx = ECGsignals(4560:4810); % range of the QRS complex of(ECG) signal
[mpdict,~,~,longs] = wmpdictionary(numel(qrsEx),'lstcpt',{{'sym4',3}});%extract QRS complex with dilated wavelet 'sym4'  
xlabel('time(s)')
ylabel('voltage(mv)') 
figure
plot(qrsEx)%plot QRS detection results
hold on
plot(2*circshift(mpdict(:,11),[-2 0]),'r')% compare different extracted QRS complex 
axis tight
wt = modwt(ECGsignals,5);%Enhancing the R peaks in the ECG waveform with modwt
wtrec = zeros(size(wt)); %covers the passband shown to maximize QRS energy 
wtrec(4:5,:) = wt(4:5,:);%%create wavelet coefficients at scales 4 and 5. 
F = imodwt(wtrec,'sym4');%maximize QRS energy by decomposing the ECG waveform down 
F = abs(F).^2;
[qrspeaks,locs] = findpeaks(F,time,'MinPeakHeight',0.35,...% finding minimal height peacks
    'MinPeakDistance',0.150);
xlabel('time(s)')
ylabel('voltage(mv)') 
figure
plot(time,F)
hold on
plot(locs,qrspeaks,'r*')% R-peak waveform obtained with the wavelet transform annotation 
plot(time(EXann),F(EXann),'k*') %R peaks Localized by Wavelet Transform with Expert Annotations
xlabel('time(s)')
ylabel('voltage(mv)') 
figure
plot(time,ECGsignals,'m--')
hold on
plot(time,F,'r','linewidth',2)
plot(time,abs(ECGsignals).^2,'g')
plot(time(EXann),ECGsignals(EXann),'r*','markerfacecolor',[1 0 0])%plot time vs ECG signals with annotations 
set(gca,'xlim',[10.2 12])% returns the handle to the current axis
xlabel('time(s)')
ylabel('voltage(mv)') 

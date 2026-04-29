load mit200 %Loading our program 
figure
plot(tm,ecgsig)
hold on
plot(tm(ann),ecgsig(ann),'ro')
qrsEx = ecgsig(4560:4810);
[mpdict,~,~,longs] = wmpdictionary(numel(qrsEx),'lstcpt',{{'sym4',3}});
xlabel('time(s)')
ylabel('voltage(mv)') 
figure
plot(qrsEx)
hold on
plot(2*circshift(mpdict(:,11),[-2 0]),'r')
axis tight
wt = modwt(ecgsig,5);
wtrec = zeros(size(wt));
wtrec(4:5,:) = wt(4:5,:);
y = imodwt(wtrec,'sym4');
y = abs(y).^2;
[qrspeaks,locs] = findpeaks(y,tm,'MinPeakHeight',0.35,...
    'MinPeakDistance',0.150);
xlabel('time(s)')
ylabel('voltage(mv)') 
figure
plot(tm,y)
hold on
plot(locs,qrspeaks,'ro')
plot(tm(ann),y(ann),'k*')
xlabel('time(s)')
ylabel('voltage(mv)') 
figure
plot(tm,ecgsig,'k--')
hold on
plot(tm,y,'r','linewidth',1.5)
plot(tm,abs(ecgsig).^2,'b')
plot(tm(ann),ecgsig(ann),'ro','markerfacecolor',[1 0 0])
set(gca,'xlim',[10.2 12])
xlabel('time(s)')
ylabel('voltage(mv)') 

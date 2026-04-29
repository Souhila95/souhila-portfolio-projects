clear all;
clc;
t_on=0.5
M=20;
C=20;
N_c=15;  
beta=1;
bst=5;
T_s=0.01;
%---------------------------------------------
Q=4;
CWmin=1;
CWmax=1023;
delta=0;
DIFS=0.05;
T_rts=0.01455;
SIFS=0.01;
T_cts=0.01018;
T_ack=0.01455;
P_f=0;   % insert pf
%--------------------------------------------
theta1=1;   % insert theat 
%---------------------------------------------
    %T_n=f_T_b0(Q,CWmin,CWmax,delta,15)+DIFS+SIFS+T_rts+T_cts
    T_n=f_T_b0(Q,CWmin,CWmax,delta)+DIFS+SIFS+T_rts+T_cts
    To=T_n+DIFS+SIFS+T_ack
    t_on
    toff=0.2
    p_on=t_on/(t_on +0.2)
    P_on=1-power((1-p_on),M/C)
    P_off=(1-P_on)
    
% i=0;
      y=zeros(10,1);
      T_f=zeros(10,1);
      T=zeros(10,1);
for i=1:10
    T_f(i)=i/10
    T(i)=T_f(i)+T_s+To
    Rs(i)=(P_off-P_f)* (T_f(i)/T(i))*bst
    y(i)=exp((-theta1*(T(i)*C)/(t_on*M)))*Rs(i) %+ (1-exp((-theta1*T(index) *C/(t_on*M))))*Rf(index)
end
figure
%plot(T_f,y,'-ob');
plot(T_f,y,'-o');
xlabel('Frame Period Tf (sec)');
ylabel('Bandwidth (Mbps)');  



t_on
toff=0.4
    p_on=t_on/(t_on +0.4)
    P_on=1-power((1-p_on),M/C)
    P_off=(1-P_on);
% i=0;
       y=zeros(10,1);
      T_f=zeros(10,1);
      T=zeros(10,1);
for i=1:10
    T_f(i)=i/10
    T(i)=T_f(i)+T_s+To
    Rs(i)=(P_off-P_f)* (T_f(i)/T(i))*bst
    y(i)=exp((-theta1*(T(i)*C)/(t_on*M)))*Rs(i) %+ (1-exp((-theta1*T(index) *C/(t_on*M))))*Rf(index)

end
hold on
%plot(T_f,y,':*r');
plot(T_f,y,':*');
    toff=0.6
    p_on=t_on/(t_on +0.6)
    P_on=1-power((1-p_on),M/C)
    P_off=(1-P_on);
   
% i=0;
     y=zeros(10,1);
      T_f=zeros(10,1);   
      T=zeros(10,1);
for i=1:10
    T_f(i)=i/10;
    T(i)=T_f(i)+T_s+To
    Rs(i)=(P_off-P_f)* (T_f(i)/T(i))*bst
    y(i)=exp((-theta1*(T(i)*C)/(t_on*M)))*Rs(i) %+ (1-exp((-theta1*T(index) *C/(t_on*M))))*Rf(index)
end
hold on
%plot(T_f,y,'--*y');
plot(T_f,y,'--*');
    toff=0.8
    p_on=t_on/(t_on +0.8)
    P_on=1-power((1-p_on),M/C)
    P_off=(1-P_on)
% i=0;
    y=zeros(10,1);
      T_f=zeros(10,1);
      T=zeros(10,1);
for i=1:10
    T_f(i)=i/10
    T(i)=T_f(i)+T_s+To
    Rs(i)=(P_off-P_f)* (T_f(i)/T(i))*bst
    y(i)=exp((-theta1*(T(i)*C)/(t_on*M)))*Rs(i) %+ (1-exp((-theta1*T(index) *C/(t_on*M))))*Rf(index)
end
hold on

%plot(T_f,y,'-*g');
plot(T_f,y,'-*');

%     i=i+1;
% Rt=y(i)
% plot(T_f,y,'-*')
% plot(T_f,Rt,'-*')
         legend('tidle=0.2','tidle=0.4','tidle=0.6','idle=0.8')
         xlabel('Frame period (Tfrm)')
         ylabel('Bandwidth(Mbps)')

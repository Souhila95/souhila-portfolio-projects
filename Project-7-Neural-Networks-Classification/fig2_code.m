function fig5_new()
clear all;
clc;


M=20;
C=20;
N_c=10;
%T_f=0.5
teta2=1;
Q=4;
CWmin=1;
CWmax=1023;
%T_s=0.01;  
DIFS=0.05;
T_rts=0.01455;
SIFS=0.01;
T_cts=0.01018;
T_ack=0.01455;
delta=0;
       Tb=f_T_b0(Q,CWmin,CWmax,delta)
       T_n=f_T_b0(Q,CWmin,CWmax,delta)+DIFS+SIFS+T_rts+T_cts
       T_0=T_n+DIFS+SIFS+T_ack
     

       i=1
       R_pl=zeros(10,1);
       
    for T_f=0.1:0.1:1 %0.5:0.1:1%          0.01:0.01:0.040
   
    T=T_f+T_0
    pn=1- (T_n/(DIFS+T_f+SIFS+T_ack))        
       if i ==11;
          i=1;
         end 
        su=0;
        
            R=func_R(T_f,T)
        for n=1:1:(N_c/2)
           n
        %   su=su+R
            su=su+R*pn
            
        end

        su;
        R_pl(i)=su;
        i=i+1;
         
      
    end
    R_pl
   T_f=0.1:0.1:1
    figure
    plot(T_f,R_pl,'-o')
      xlabel('Frame period T_frm of SU')
         ylabel('Bandwidth(Mbps)')
      
    hold on;
end
% 
% 
% 
% 
% 
% %%%%%%%%%%%%%%%% function R that will be used for calculate R+
% 
function R=func_R(T_f,T)

    M=20;
    C=20;
    N_c=10%15;
    beta=1;
    %----------------------------------------------
    %bst=beta*log2(1+Sn);
    bst=5;

    theta1=1;   % insert theat
   
        R=(T_f/T)*bst
    
end



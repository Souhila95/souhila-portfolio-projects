%%%%%%%%%%%%%Compilation code%%%%%%%%%%%
%%%%%% load FRANCE_9_17_18
%%%%%% load NET23
clc
y=5;

     while true
  prompt = "Enter your input values"; 
    
x=input(prompt);
  y=net(x);
  disp(y)
     
if true 
    N=input(prompt);
    N=y;
       
       break
end

  end
%   if x==y
%       break
%   end
  
      
%       prompt = "Enter your input values";
%       x=input(prompt);
%       y=x;
% %       disp('Loop stopped by user');
%       break       
  
     
  if   prompt == "Enter your input values"
           txt=input(prompt,'s');
           if isempty(txt)
               txt='Y'; 
         
           end 
  end 
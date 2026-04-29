function [ X,f ] = my_luminous( mu, sigma_b, min_x, max_x, n)
%UNTITLED14 Summary of this function goes here
%   Detailed explanation goes here
 f = zeros(n, 1);
 X = zeros(n, 1);
x = min_x;
dx = (max_x - min_x) / n;
I =1;
for i=1:n
    
X(i)= x;
f(i) = I.*exp( -(x - mu)^2 /(sigma_b)^2);
x = x + dx;
end

end 
 
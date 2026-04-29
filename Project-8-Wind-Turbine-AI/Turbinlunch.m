%  load mine
J=0.21;
f=0.0001;
R=3;
G=6;
ro=1.22;
S=pi*R^2;
% myGeneratedwindspeeddata=myGeneratedwindspeeddata';
% mygenerateturbinpower1=mygenerateturbinpower1';

if (true)
   
    % Generate a Simulink diagram for simulation or deployment with.
    % Simulink Coder tools.
   open_system('mysimmodel');
 % most basic way to simulate with command script.
 sim('mysimmodel',30)
myGeneratedwindspeeddata=myGeneratedwindspeeddata';
mygenerateturbinpower1=mygenerateturbinpower1';

send=[time;Temperature;myGeneratedwindspeeddata;Direction;Density;mygenerateturbinpower1]';

end
% time=time';
% Generatedwindspeeddata=Generatedwindspeeddata';
% generateturbinpower1=generateturbinpower1';
% send=[time;Temperature;Generatedwindspeeddata;Direction;Density;generateturbinpower1];

% send(:,1)=time;
% send=Temperature(:,2);
% Generatedwindspeeddata=Generatedwindspeeddata';
% send=Generatedwindspeeddata(:,3);
% send=Direction(:,4);
% send=Density(:,5);
% generateturbinpower1=generateturbinpower1';
% send=generateturbinpower1(:,6);



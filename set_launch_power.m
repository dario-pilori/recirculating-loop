function n=set_launch_power(a1,a2,Ptx)
%SET_LAUNCH_POWER     Set Keopsys amplifer launch power
%
%   2018 - Dario Pilori <dario.pilori@polito.it>

% Set amplifier 1 to constant power
fopen(a1);
fprintf(a1,'REM');
query(a1,['CPU=',num2str(round(Ptx*10),'%03d')]);
pause(2);
n1 = query(a1,'PUS?');
n1 = strsplit(n1,'=');
n1 = str2double(n1{2})/100;
fprintf(a1,'GTL');
fclose(a1);

% Set amplifier 2 to constant power
fopen(a2);
fprintf(a2,'REM');
query(a2,['CPU=',num2str(round(Ptx*10),'%03d')]);
pause(2);
n2 = query(a2,'PUS?');
n2 = strsplit(n2,'=');
n2 = str2double(n2{2})/100;
fprintf(a2,'GTL');
fclose(a2);

n = mean([n1 n2]);

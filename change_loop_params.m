function change_loop_params(addr1,addr2,tloop,n_loops)
% This function changes the loop number to n_loops
%% Parameters
% addr1 -> GPIB address of first DG535 (loop+fill switch)
% addr2 -> GPIB address of second DG535 (trigger)
% tloop -> Propagation delay of loop (c/neff*L, seconds )
% n_loops -> Number of loops to propagate

%% Calculate parameters
tfill = 1.5*tloop; % time to fill the loop
f_trig = 1/(tfill+n_loops*tloop); % trigger time

%% Set up first
g = gpib('ni',0,addr1);
fopen(g);

% Set trigger
fprintf(g,['TR 0,',num2str(f_trig,'%f')]); % set trigger frequency

% Set delays
fprintf(g,['DT 3,2,',num2str(tfill,'%E')]);

fclose(g);

%% Set up second
g = gpib('ni',0,addr2);
fopen(g);

% Set delays
fprintf(g,['DT 2,1,',num2str(tfill+(n_loops-1)*tloop+0.05,'%E')]);
fprintf(g,['DT 3,2,',num2str(tloop*0.9,'%E')]);

fclose(g);
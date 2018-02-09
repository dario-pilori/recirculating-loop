function select_loop(addr,tloop,n_loops)
% This function selects the wanted loop in the trigger
%% Parameters
% addr1 -> GPIB address of first DG535 (loop+fill switch)
% addr2 -> GPIB address of second DG535 (trigger)
% tloop -> Propagation delay of loop (c/neff*L, seconds )
% n_loops -> Number of loops to propagate

%% Calculate parameters
tfill = 1.5*tloop; % time to fill the loop

%% Set up second
g = gpib('ni',0,addr);
fopen(g);

% Set delays
fprintf(g,['DT 2,1,',num2str(tfill+(n_loops-1+0.05)*tloop,'%E')]);
fprintf(g,['DT 3,2,',num2str(tloop*0.90,'%E')]);

fclose(g);
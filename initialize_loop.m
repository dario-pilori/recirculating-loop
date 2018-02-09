function initialize_loop(addr1,addr2,tloop,n_loops)
% This function initializes the SRS DG535 to operate in the loop.
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

fprintf(g,'CL'); % clear instrument

% Set to high-impedance load
fprintf(g,'TZ 1,1');
fprintf(g,'TZ 4,1');
fprintf(g,'TZ 7,1');

% Set TTL output
fprintf(g,'OM 1,0');
fprintf(g,'OM 4,0');
fprintf(g,'OM 7,0');

% Set trigger
fprintf(g,'TM 0'); % internal trigger
fprintf(g,['TR 0,',num2str(f_trig,'%f')]); % set trigger frequency

% Set delays
fprintf(g,'DT 2,1,0');
fprintf(g,['DT 3,2,',num2str(tfill,'%E')]);
fprintf(g,'DT 5,2,0');
fprintf(g,'DT 6,3,0');

fclose(g);

%% Set up second
g = gpib('ni',0,addr2);
fopen(g);

fprintf(g,'CL'); % clear instrument

% Set to high-impedance load
fprintf(g,'TZ 1,1');
fprintf(g,'TZ 4,1');

% Set TTL output
fprintf(g,'OM 1,0');
fprintf(g,'OM 4,0');

% Set trigger
fprintf(g,'TM 1'); % Set external trigger
fprintf(g,'TZ 0,1'); % set trigger impedance

% Set delays
fprintf(g,['DT 2,1,',num2str(tfill+(n_loops-1+0.05)*tloop,'%E')]);
fprintf(g,['DT 3,2,',num2str(tloop*0.9,'%E')]);
fclose(g);
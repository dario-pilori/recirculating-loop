function set_amplifiers
% Settings
addrs = [11;15;17];
amps = cell(size(addrs));

% Set up GPIB connection
for i = 1:size(addrs,1)
    amps{i} = gpib('ni',0,addrs(i)); %#ok<TNMLP>
end

% Set amplifier 1 to constant power
fopen(amps{1});
fprintf(amps{1},'REM');
query(amps{1},'CPU=010');
fprintf(amps{1},'GTL');
fclose(amps{1});

% Set amplifier 2 to constant gain
fopen(amps{2});
fprintf(amps{2},'REM');
query(amps{2},'CGA=156');
fprintf(amps{2},'GTL');
fclose(amps{2});

% Set amplifier 3 to constant gain
fopen(amps{3});
fprintf(amps{3},'REM');
query(amps{3},'CPU=030');
fprintf(amps{3},'GTL');
fclose(amps{3});

% Close everything
for i = 1:size(addrs,1)
    delete(amps{i});
end
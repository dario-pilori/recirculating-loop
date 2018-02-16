function set_amplifiers(Ptx,G1,Pout)
%SET_AMPLIFIERS     Set Keopsys amplifiers working points
%   Use this function to set the working points of the Keopsys EDFAs in the
%   recirculating loop. The first and last amplifiers are in constant-power
%   mode, while the "internal" amplifiers are in constant-gain mode. Powers
%   are in dBm, while gains are in dB.
%
%   2018 - Dario Pilori <dario.pilori@polito.it>

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
query(amps{1},['CPU=',num2str(round(Ptx*10),'%03d')]);
fprintf(amps{1},'GTL');
fclose(amps{1});

% Set amplifier 2 to constant gain
fopen(amps{2});
fprintf(amps{2},'REM');
query(amps{2},['CGA=',num2str(round(G1*10),'%03d')]);
fprintf(amps{2},'GTL');
fclose(amps{2});

% Set amplifier 3 to constant gain
fopen(amps{3});
fprintf(amps{3},'REM');
query(amps{3},['CPU=',num2str(round(Pout*10),'%03d')]);
fprintf(amps{3},'GTL');
fclose(amps{3});

% Delete objects
for i = 1:size(addrs,1)
    delete(amps{i});
end
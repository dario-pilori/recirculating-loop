% Use this script to set up from zero the recirculating loop
clear
close all
clc

global att l o

%% Set up recirculating loop
tloop = 1.4682/299792458*25260*6;
l = RecirculatingLoop(9,8,tloop,5);
l.Initialize;
l.SelectLoop(0);
l.SetScramblerDelay(1e-6);

%% Set up OSA
o = OSA(23);

%% Set up attenuator
att = Attenuator('TCPIP0::ipq-sl-voa101::inst0::INSTR');
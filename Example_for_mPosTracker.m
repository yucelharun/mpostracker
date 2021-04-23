close all;
clear all;

vid_patName='ExpData/';
vid_Name='1.avi';

Tra = mPosTracker();
Tra.addVideo(vid_patName, vid_Name);


Tra.th = 220;

Tra.StepLength = 15;


Tra.CalcMethod = 1;

Tra.panel_l = 1;

Tra.show_HamData = 1;
Tra.show_Num=1;
Tra.show_borders = 1;

% Tra.show_ident_trac = 1;
% Tra.show_mask = 1;

Tra.start();

Tra.tursay = 2;
Tra.turpar = 1;
Tra.distributions();
figure, plot(Tra.centers, Tra.nelements);

Tra.limits = [20, 60; 100, 180];
Tra.Classify();

Tra.show_trajectories = 1;
figure, Tra.Show_Results();

% Tra.saveClassData('SavedData/SavedData_3.mat')







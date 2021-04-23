close all;
clear all;



im = imread('ExpData/test_im.png');

im = double(im);

Pos = PosFinder(im, 110, 40, 2, 0);

Pos.show_panel();

disp(Pos.dCent);




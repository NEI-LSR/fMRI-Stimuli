%% Estimate RGB Colors

targXYZFile = 'target_xyz.csv';
measurementPath = 'C:\Users\Admin\Documents\GitHub\fMRI-Stimuli\Templates\ColorCalibration\measurements\24-Mar-2022_RIGB\';
measurementFileName = '24-Mar-2022_RIGB.mat';
outfile = 'target_rgb.csv'


load([measurementPath measurementFileName]);
targXYZ = csvread(targXYZFile);

xr = LumValues.red(end).xyYcie(1);
yr = LumValues.red(end).xyYcie(2);
xg = LumValues.green(end).xyYcie(1);
yg = LumValues.green(end).xyYcie(2);
xb = LumValues.blue(end).xyYcie(1);
yb = LumValues.blue(end).xyYcie(2);
xw = LumValues.white(end).xyYcie(1);
yw = LumValues.white(end).xyYcie(2);

M = XYZToRGBMatrix(xr,yr,xg,yg,xb,yb,xw,yw);

targRGB = (M*targXYZ')';

csvwrite(outfile,targRGB);

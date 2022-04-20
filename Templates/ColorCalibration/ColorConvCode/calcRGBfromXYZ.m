%% Estimate RGB Colors

targXYZFile = 'target_xyz.csv';
measurementPath = 'C:\Users\Admin\Documents\GitHub\fMRI-Stimuli\Templates\ColorCalibration\measurements\19-Apr-2022_RigB\';
measurementFileName = '19-Apr-2022_RigB';
outfile = 'target_rgb.csv'


load([measurementPath measurementFileName]);
load([measurementPath measurementFileName '_LUT'])
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

targRGB = round((M*targXYZ'))';
roundedRGB = targRGB;
roundedRGB(roundedRGB > 256) = 256;
roundedRGB = roundedRGB';


targRGB_LUT = horzcat(LUT(roundedRGB(1,:),1),LUT(roundedRGB(2,:),2),LUT(roundedRGB(3,:),3));


csvwrite(outfile,targRGB_LUT);

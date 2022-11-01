%% Estimate RGB Colors

targXYZFile = 'target_xyz.csv';
whiteXYZ = [255.00	270.00	315.00];
measurementPath = 'C:\Users\duffieldsj\Documents\GitHub\fMRI-Stimuli\Templates\ColorCalibration\measurements\19-Apr-2022_RigB\';
measurementFileName = '19-Apr-2022_RigB';
outfile = 'target_rgb.csv'


load([measurementPath measurementFileName]);
load([measurementPath measurementFileName '_LUT'])
targXYZ = csvread(targXYZFile);
xg = LumValues.white(end).xyYcie(1);
yg = LumValues.white(end).xyYcie(2);
Yg = LumValues.white(end).xyYcie(3)/2;
xyYgray = [xg yg Yg];
XYZgrayTarget = xyYToXYZ(xyYgray');

% Convert to LUV
targLUV = XYZToLuv(targXYZ',whiteXYZ');
targXYZ_edited = LuvToXYZ(targLUV,XYZgrayTarget);
targXYZ_edited(targXYZ_edited < 0) = 0;

xr = LumValues.red(end).xyYcie(1);
yr = LumValues.red(end).xyYcie(2);
xg = LumValues.green(end).xyYcie(1);
yg = LumValues.green(end).xyYcie(2);
xb = LumValues.blue(end).xyYcie(1);
yb = LumValues.blue(end).xyYcie(2);
xw = LumValues.white(end).xyYcie(1);
yw = LumValues.white(end).xyYcie(2);

M = XYZToRGBMatrix(xr,yr,xg,yg,xb,yb,xw,yw);

targRGB = round((M*targXYZ_edited))';
roundedRGB = targRGB;
roundedRGB(roundedRGB > 256) = 256;
roundedRGB(roundedRGB < 1) = 1;

roundedRGB = roundedRGB';


targRGB_LUT = horzcat(LUT(roundedRGB(1,:),1),LUT(roundedRGB(2,:),2),LUT(roundedRGB(3,:),3));


csvwrite(outfile,targRGB_LUT);

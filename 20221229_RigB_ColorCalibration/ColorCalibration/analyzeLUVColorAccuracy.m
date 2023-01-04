curdir = pwd;
load(fullfile(curdir,'measurements','29-Dec-2022_RigBMacMonitor/','29-Dec-2022_RigBMacMonitor.mat'));
load(fullfile(curdir,'automaticMeasurements',"29-Dec-2022_17_00_54.mat"));

finalxyY = reshape(extractfield(finalmeasurements,'xyYJudd'),3,[])';
gamutxyY = [LumValues.red(end).xyYJudd; LumValues.blue(end).xyYJudd; LumValues.green(end).xyYJudd];
gamutXYZ = xyYToXYZ(gamutxyY');
LUVvals = load(fullfile(curdir,'targetvalues','LUV_Colors_MTurk1.csv'))';

% we used white 12, gunval 187
whitepoint = xyYToXYZ(LumValues.white(12).xyYJudd')

targXYZ = LuvToXYZ(LUVvals,whitepoint);
%targXYZ = LuvToXYZ(LUVvals,[80;80;80]);
targxyY = XYZToxyY(targXYZ);

DrawChromaticity
hold on;
scatter(finalxyY(:,1),finalxyY(:,2))
plot([gamutxyY(:,1); gamutxyY(1,1)],[gamutxyY(:,2); gamutxyY(1,2)]);
scatter(targxyY(1,:),targxyY(2,:),'x');
hold off;

finalLUV = XYZToLuv(xyYToXYZ(finalxyY'),whitepoint);

figure();
scatter(finalLUV(2,:),finalLUV(3,:));
hold on;
scatter(LUVvals(2,:),LUVvals(3,:),'x');

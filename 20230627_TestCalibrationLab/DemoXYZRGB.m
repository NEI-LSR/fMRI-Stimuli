%% Test XYZ to RGB
curDir = pwd;
measuredir = fullfile(curDir,'measurements');
calibName = '21-Jun-2023_OfficeMonitor2'; % What is the name of the files that stores the calibration information?
calibpath = fullfile(measuredir,calibName); % Where is this path?
measuresFilename = [calibName '.mat']; % Load the values of the spectra recorded
lutFilename = [calibName '_LUT.mat']; % Load the lookup table
bxy = LumValues.blue(end).xyYJudd;
gxy = LumValues.green(end).xyYJudd;
rxy = LumValues.red(end).xyYJudd;
wxy = LumValues.white(end).xyYJudd;

DrawChromaticity;
hold on;
allxy = [rxy(1:2); gxy(1:2); bxy(1:2)];
scatter(allxy(:,1),allxy(:,2));

bXYZ = spectra2XYZ(LumValues.blue(end).Spectrum,'Judd');
gXYZ = spectra2XYZ(LumValues.green(end).Spectrum,'Judd');
rXYZ = spectra2XYZ(LumValues.red(end).Spectrum,'Judd');
disp(rXYZ);
disp(gXYZ);
disp(bXYZ);

%%
targetXYZ = [73 99 27];
M_XYZ2RGB = XYZToRGBMatrix(rxy(1),rxy(2),gxy(1),gxy(2),bxy(1),bxy(2),wxy(1),wxy(2));
targetRGB = round(M_XYZ2RGB*targetXYZ');
actualRGB = [LUT(targetRGB(1),1) LUT(targetRGB(2),2) LUT(targetRGB(3),3)];

KbName('UnifyKeyNames');
Screen('OpenWindow',2,[255 255 255])
while true
    [keyIsDown,secs, keyCode] = KbCheck;

    if keyCode(KbName('a'))
        sca;
        break
    end
end
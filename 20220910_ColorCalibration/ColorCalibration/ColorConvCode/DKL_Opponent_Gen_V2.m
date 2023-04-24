%% LMS/DKL
clear 
close all
curDir = pwd;
saveDir = [curDir '\targetvalues'];
if ~isfolder(saveDir)
    mkdir(saveDir)
end
extension = 'DKL8ColorBiasedRegionLocalizerColors';
targetLMSF = [saveDir '\' extension '.mat'];
LMSgray = [0.4506 0.3763 0.2380]; % insert the LMS value of the gray you measured
graypointRGB = [128 128 128]; % What is the value of the isoluminant RGB that you want? 
scalingFs = [0.9,0.9,0.9,0.9,0.9,0.9,0.9,0.9]; % How far along the gamut of the direction with the least gamut range do you want to extend?
angles = [0, 45, 90, 135, 180, 225, 270,315]; % What angles in DKL space do you want to compute your colors around
lumAngles = [0, 0, 0, 0, 0, 0, 0, 0]; % What angle along the LMS axis do you want to calculate around?
angles = deg2rad(angles); % Convert to radians
lumAngles = deg2rad(lumAngles); % Convert to radians
graypoint = graypointRGB/256; % Convert RGB graypoint into decimal
bgLMS = LMSgray'; % Transpose for the background LMS value


calibName = '10-Sep-2022_NIFWideScreen20220910'; % What is the name of the files that stores the calibration information?
calibpath = 'C:\Users\duffieldsj\Documents\GitHub\fMRI-Stimuli\20220910_ColorCalibration\ColorCalibration\measurements\10-Sep-2022_NIFWideScreen20220910\'; % Where is this path?
measuresFilename = [calibName '.mat']; % Load the values of the spectra recorded
lutFilename = [calibName '_LUT.mat']; % Load the lookup table
varname = who('-file', [calibpath filesep measuresFilename]); %
load([calibpath filesep measuresFilename]); % LumValues
load([calibpath filesep lutFilename]); % LUT

%whiteGuns = extractfield(LumValues.white,'gunValue');
whitexyY = reshape(extractfield(LumValues.white,'xyYJudd'),3,[])';
redxyY = reshape(extractfield(LumValues.red,'xyYJudd'),3,[])';
greenxyY = reshape(extractfield(LumValues.green,'xyYJudd'),3,[])';
bluexyY = reshape(extractfield(LumValues.blue,'xyYJudd'),3,[])';

%whiteY = whitexyY(3:3:end);
%whiteLUT = makeLUTperGun(whiteGuns,whiteY,'black');

spectrum = [LumValues.red(end).Spectrum(:,1), LumValues.red(end).Spectrum(:,2),...
    LumValues.green(end).Spectrum(:,2), LumValues.blue(end).Spectrum(:,2)];
xyzJuddVosCMF = textread('ciexyz_juddvos.csv', '', 'delimiter', ',');  % Judd/Vos CMF 2deg from CVRL website
rellumeffJuddVos = textread('lumefficiency_juddvos.csv', '', 'delimiter', ',');
conefundsSP = textread('conefund_smithpokorny.csv', '', 'delimiter', ',');

% Below changed by SL to fix matrix broadcasting. Assumed each col should
% be scaled independently 20220415
temp = 10.^conefundsSP(:, 2:4);
con_sens_ax1 = conefundsSP(:, 1);
trans_temp = repmat(1./max(temp), 90, 1);
conesensitivities = [con_sens_ax1, temp.*trans_temp];


allSampling = 380:1:780; % for all distributions (cones fundamentals, CMF, spectrum etc.)
% be careful, range affects matrix multiplication/understand integral

xyYwhite = LumValues.white(end).xyYJudd;
LumRGB = [LumValues.red(end).xyYJudd(3), LumValues.green(end).xyYJudd(3),...
    LumValues.blue(end).xyYJudd(3)];
xyYwhite = [xyYwhite(1:2) 1]; % set Y = 1
XYZwhite = xyYToXYZ(xyYwhite');

xyzJuddVosCMFi = interp1(xyzJuddVosCMF(:,1), xyzJuddVosCMF(:,2:4),allSampling,'spline'); % 'linear','extrap'
rellumeffJuddVosi = interp1(rellumeffJuddVos(:,1), rellumeffJuddVos(:,2),allSampling,'spline');
conesensitivitiesI = interp1(conesensitivities(:,1), conesensitivities(:,2:4),allSampling,'spline');
spectrumI = interp1(spectrum(:,1), spectrum(:,2:4),allSampling,'spline');
lumeffJuddVosi = 683.008*rellumeffJuddVosi; %lm/W



% RGB to LMS
RGB2LMS_Matrix = conesensitivitiesI'*spectrumI;
LMS2RGB_Matrix = inv(RGB2LMS_Matrix);

% then to DKL
bgLMS = RGB2LMS_Matrix*graypoint';

M_ConeIncToDKL = ComputeDKL_M(bgLMS',conesensitivitiesI',lumeffJuddVosi);
M_DKLToConeInc = inv(M_ConeIncToDKL);




bgPrimary = LMS2RGB_Matrix*bgLMS;

% Now find incremental cone directions corresponding
% to DKL isoluminant directions.
LMConeIncPlus = M_DKLToConeInc*[0 1 0]';
LMConeIncMinus = M_DKLToConeInc*[0 -1 0]';
SConeIncPlus = M_DKLToConeInc*[0 0 1]';
SConeIncMinus = M_DKLToConeInc*[0 0 -1]';
LUMConeIncPlus = M_DKLToConeInc*[1 0 0]';
LUMConeIncMinus = M_DKLToConeInc*[-1 0 0]';
% We need to find the maximum gamut excursions for these so we can define
% the DKL units and get a 'spherical' colorspace
LMPrimaryIncPlus = LMS2RGB_Matrix*(LMConeIncPlus+bgLMS)-bgPrimary;
LMPrimaryIncMinus = LMS2RGB_Matrix*(LMConeIncMinus+bgLMS)-bgPrimary;
SPrimaryIncPlus = LMS2RGB_Matrix*(SConeIncPlus+bgLMS)-bgPrimary;
SPrimaryIncMinus = LMS2RGB_Matrix*(SConeIncMinus+bgLMS)-bgPrimary;
LUMPrimaryIncPlus = LMS2RGB_Matrix*(LUMConeIncPlus+bgLMS)-bgPrimary;
LUMPrimaryIncMinus = LMS2RGB_Matrix*(LUMConeIncMinus+bgLMS)-bgPrimary;
% Now find the scales
LMPlusScale = MaximizeGamutContrast(LMPrimaryIncPlus,bgPrimary);
LMMinusScale = MaximizeGamutContrast(LMPrimaryIncMinus,bgPrimary);
SPlusScale = MaximizeGamutContrast(SPrimaryIncPlus,bgPrimary);
SMinusScale = MaximizeGamutContrast(SPrimaryIncMinus,bgPrimary);
LUMPlusScale = MaximizeGamutContrast(LUMPrimaryIncPlus,bgPrimary);
LUMMinusScale = MaximizeGamutContrast(LUMPrimaryIncMinus,bgPrimary);

LMScale = min(LMPlusScale,LMMinusScale);
SScale = min(SPlusScale,SMinusScale);
LUMScale = min(LUMPlusScale,LUMMinusScale);




coneIncs = [];
cosAngles = cos(angles); % Get the cosine values of angles
sinAngles = sin(angles); % Get the sine values of angles
sinLumAngles = sin(lumAngles); % Get the 'height' by which we find the point
cosLumAngles = cos(lumAngles); % Get the 'sign' of the luminance angle
for i = 1:length(angles)
    coneIncs(:,i) = M_DKLToConeInc*[LUMScale*sinLumAngles(i) LMScale*cosLumAngles(i)*cosAngles(i) SScale*cosLumAngles(i)*sinAngles(i)]';
end


% These directions are not scaled in an interesting way,
% need to scale them.  Here we'll find units so that 
% a unit excursion in the two directions brings us to
% the edge of the monitor gamut, with a little headroom.

primaryIncs = [];
scales = [];

for i = 1:length(angles)
    % Different options for determining the scales
    % 1: Each different direction maximizes the gamut
    % primaryIncs(:,i) = LMS2RGB_Matrix*(coneIncs(:,i)+bgLMS)-bgPrimary;
    % testscales(i) = MaximizeGamutContrast(primaryIncs(:,i),bgPrimary);
    % 2: Compute the scale as a function of the maximum gamut directions of
    % the DKL cardinal directions
    % scales(i) = hypot(cosLumAngles(i)*hypot(cosAngles(i)*LMScale,sinAngles(i)*SScale),sinLumAngles(i)*LUMScale);
end

% scale = min(scales); % Find smallest gamut excursion to include all directions
maxConeIncs = [];
scaledConeIncs = [];
for i = 1:length(angles)
    % maxConeIncs(:,i) = scales(i)*primaryIncs(:,i);
    % scaledConeIncs(:,i) = scales(i)*scalingFs(i)*coneIncs(:,i);
    scaledConeIncs(:,i) = coneIncs(:,i)*scalingFs(i);
end


% Compute the cone increases when combined with the background
LMS = [];
for i = 1:length(angles)
    LMS(:,i) = scaledConeIncs(:,i)+bgLMS;
end

DKL = M_ConeIncToDKL*scaledConeIncs;
est_RGB = round(LMS2RGB_Matrix*LMS*255);
est_RGB_Lookup = horzcat(LUT(est_RGB(1,:)+1,1),LUT(est_RGB(2,:)+1,2),LUT(est_RGB(3,:)+1,3))';

disp('Actual LMS Values')
disp(LMS)
disp('Calculated RGB Values (no lookup)')
disp(est_RGB)
disp('Calculated RGB Values (with Lookup)')
disp(est_RGB_Lookup)
save(targetLMSF); % Save all variables for now
csvwrite([saveDir '\' extension '_LMS.csv'],LMS');
csvwrite([saveDir '\' extension '_RGB.csv'],est_RGB_Lookup');


M_XYZ2RGB = XYZToRGBMatrix(redxyY(end,1),redxyY(end,2),greenxyY(end,1),greenxyY(end,2),bluexyY(end,1),bluexyY(end,2),whitexyY(end,1),whitexyY(end,2));
M_RGB2XYZ = inv(M_XYZ2RGB);

XYZ = M_RGB2XYZ*est_RGB_Lookup;
xyY = thXYZToxyY(XYZ)';
XYZgray = M_RGB2XYZ*graypoint';
xyYGray = thXYZToxyY(XYZgray)';

monitorgamut = [redxyY(end,:); bluexyY(end,:); greenxyY(end,:); redxyY(end,:)];

figure
DrawChromaticity
hold on
scatter(xyY(:,1),xyY(:,2),'x','r');
scatter(xyYGray(1),xyYGray(2),'o','filled','k');
plot(monitorgamut(:,1),monitorgamut(:,2));
legend('Target Values','Equiluminant Gray','Monitor Gamut');
title('Chroamticity Coordinates of Calculated and Measured Values (Judd)');
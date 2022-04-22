%% LMS/DKL
clear 
close all
LMSgray = [0.54529 0.44988 0.26871]; % insert the LMS value of the gray you measured
graypointRGB = [128 128 128]; % What is the value of the isoluminant RGB that you want? 
whiteJumps = 0.2*256; % Not sure what this does yet
scalingF = .9; % How far along the gamut of the direction with the least gamut range do you want to extend?
angles = [0, 45, 90, 135, 180, 225, 270, 315, 0, 0]; % What angles in DKL space do you want to compute your colors around
lumAngles = [0, 0, 0, 0, 0, 0, 0, 0, 90, -90]; % What angle along the LMS axis do you want to calculate around?
angles = deg2rad(angles); % Convert to radians
lumAngles = deg2rad(lumAngles); % Convert to radians
graypoint = graypointRGB/256; % Convert RGB graypoint into decimal
bgLMS = LMSgray'; % Transpose for the background LMS value


calibName = '26-Jan-2022_PROPIXSmallNoFilter'; % What is the name of the files that stores the calibration information?
calibpath = pwd; % Where is this path?
measuresFilename = [calibName '.mat']; % Load the values of the spectra recorded
lutFilename = [calibName '_LUT.mat']; % Load the lookup table
varname = who('-file', [calibpath filesep measuresFilename]); %
load([calibpath filesep measuresFilename]); % LumValues
load([calibpath filesep lutFilename]); % LUT

%whiteGuns = extractfield(LumValues.white,'gunValue');
%whitexyY = extractfield(LumValues.white,'xyYJudd');
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
%bgLMS = RGB2LMS_Matrix*graypoint';

M_ConeIncToDKL = ComputeDKL_M(bgLMS,conesensitivitiesI',lumeffJuddVosi);
M_DKLToConeInc = inv(M_ConeIncToDKL);

% Now find incremental cone directions corresponding
% to DKL isoluminant directions.
coneIncs = [];
cosAngles = cos(angles); % Get the cosine values of angles
sinAngles = sin(angles); % Get the sine values of angles
sinLumAngles = sin(lumAngles); % Get the 'height' by which we find the point
cosLumAngles = cos(lumAngles); % Get the 'sign' of the luminance angle
for i = 1:length(angles)
    coneIncs(:,i) = M_DKLToConeInc*[sinLumAngles(i) cosLumAngles(i)*cosAngles(i) cosLumAngles(i)*sinAngles(i)]';
end


% These directions are not scaled in an interesting way,
% need to scale them.  Here we'll find units so that 
% a unit excursion in the two directions brings us to
% the edge of the monitor gamut, with a little headroom.

primaryIncs = [];
scales = [];

bgPrimary = LMS2RGB_Matrix*bgLMS;
for i = 1:length(angles)
    primaryIncs(:,i) = LMS2RGB_Matrix*(coneIncs(:,i)+bgLMS)-bgPrimary;
    scales(i) = MaximizeGamutContrast(primaryIncs(:,i),bgPrimary);
end

scale = min(scales); % Find smallest gamut excursion to include all directions
maxConeIncs = [];
scaledConeIncs = [];
for i = 1:length(angles)
    maxConeIncs(:,i) = scale*primaryIncs(:,i);
    scaledConeIncs(:,i) = scale*scalingF*coneIncs(:,i);
end


% Compute the cone increases when combined with the background
LMS = [];
for i = 1:length(angles)
    LMS(:,i) = scaledConeIncs(:,i)+bgLMS;
end

DKL = M_ConeIncToDKL*scaledConeIncs;
est_RGB = round(LMS2RGB_Matrix*LMS*255);
est_RGB_Lookup = horzcat(LUT(est_RGB(1,:),1),LUT(est_RGB(2,:),2),LUT(est_RGB(3,:),3))';

disp('Actual LMS Values')
disp(LMS)
disp('Calculated RGB Values (no lookup)')
disp(est_RGB)
disp('Calculated RGB Values (with Lookup)')
disp(est_RGB_Lookup)



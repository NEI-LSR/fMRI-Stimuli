%% LMS/DKL

clear 
%close all
LMSgray = [0.55461 0.45616 0.27202] % insert the LMS value of the gray you measured
graypointRGB = [128 128 128]; % What is the value of the isoluminant RGB that you want? This isn't really necessary\
whiteJumps = 0.2*256;
scalingF = 0.9;
graypoint = graypointRGB/256; 
bgLMS = LMSgray';


calibName = '26-Jan-2022_PROPIXSmallNoFilter'; % What is the name of the files that stores the calibration information?
calibpath = pwd; % Where is this path?
measuresFilename = [calibName '.mat']; % Load the values of the spectra recorded
lutFilename = [calibName '_LUT.mat']; % Load the lookup table
varname = who('-file', [calibpath filesep measuresFilename]); %
load([calibpath filesep measuresFilename]); % LumValues
load([calibpath filesep lutFilename]); % LUT

whiteGuns = extractfield(LumValues.white,'gunValue');
whitexyY = extractfield(LumValues.white,'xyYJudd');
whiteY = whitexyY(3:3:end);
whiteLUT = makeLUTperGun(whiteGuns,whiteY,'black');

spectrum = [LumValues.red(end).Spectrum(:,1), LumValues.red(end).Spectrum(:,2),...
    LumValues.green(end).Spectrum(:,2), LumValues.blue(end).Spectrum(:,2)];
xyzJuddVosCMF = textread('ciexyz_juddvos.csv', '', 'delimiter', ',');  % Judd/Vos CMF 2deg from CVRL website
rellumeffJuddVos = textread('lumefficiency_juddvos.csv', '', 'delimiter', ',');
conefundsSP = textread('conefund_smithpokorny.csv', '', 'delimiter', ',');
temp = 10.^conefundsSP(:, 2:4);
conesensitivities = [conefundsSP(:, 1), 1./max(temp).*temp];


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
rgConeInc = M_DKLToConeInc*[0 1 0]';
sConeInc = M_DKLToConeInc*[0 0 1]';

% These directions are not scaled in an interesting way,
% need to scale them.  Here we'll find units so that 
% a unit excursion in the two directions brings us to
% the edge of the monitor gamut, with a little headroom.

bgPrimary = LMS2RGB_Matrix*bgLMS;
rgPrimaryInc = LMS2RGB_Matrix*(rgConeInc+bgLMS)-bgPrimary;
sPrimaryInc = LMS2RGB_Matrix*(sConeInc+bgLMS)-bgPrimary;
rgScale = MaximizeGamutContrast(rgPrimaryInc,bgPrimary);
sScale = MaximizeGamutContrast(sPrimaryInc,bgPrimary);
maxRGconeInc = rgScale*rgConeInc;
maxSconeInc = sScale*sConeInc;
rgConeInc = scalingF*rgScale*rgConeInc;
sConeInc = scalingF*sScale*sConeInc;

% If we find the RGB values corresponding to unit excursions
% in rg and s directions, we should find a) that the luminance
% of each is the same and b) that they are all within gamut.
% In gamut means that the primary coordinates are all bounded
% within [0,1].
rgPlusLMS = bgLMS+rgConeInc;
rgMinusLMS = bgLMS-rgConeInc;
sPlusLMS = bgLMS+sConeInc;
sMinusLMS = bgLMS-sConeInc;
%rgPlusPrimary = SensorToPrimary(calLMS,rgPlusLMS);
rgPlusPrimary = LMS2RGB_Matrix*rgPlusLMS;
%rgMinusPrimary = SensorToPrimary(calLMS,rgMinusLMS);
rgMinusPrimary = LMS2RGB_Matrix*rgMinusLMS;
%sPlusPrimary = SensorToPrimary(calLMS,sPlusLMS);
sPlusPrimary = LMS2RGB_Matrix*sPlusLMS;
%sMinusPrimary = SensorToPrimary(calLMS,sMinusLMS);
sMinusPrimary =  LMS2RGB_Matrix*sMinusLMS;

maxRGConeIncDKL = M_ConeIncToDKL*maxRGconeInc; %Lum/LM/S
[~, ~, maxRadRG] = cart2sph(maxRGConeIncDKL(2), maxRGConeIncDKL(3), maxRGConeIncDKL(1)); %LM/S/Lum
maxSConeIncDKL = M_ConeIncToDKL*maxSconeInc; %Lum/LM/S
[~, ~, maxRadS] = cart2sph(maxSConeIncDKL(2), maxSConeIncDKL(3), maxSConeIncDKL(1)); %LM/S/Lum


if (any([rgPlusPrimary(:) ; rgMinusPrimary(:) ; ...
		sPlusPrimary(:) ; sMinusPrimary(:)] < 0))
	fprintf('Something out of gamut low that shouldn''t be.\n');
end
if (any([rgPlusPrimary(:) ; rgMinusPrimary(:) ; ...
		sPlusPrimary(:) ; sMinusPrimary(:)] > 1))
	fprintf('Something out of gamut high that shouldn''t be.\n');
end
%bgLum = PrimaryToSensor(calLum,bgPrimary);
RGB2LUM = lumeffJuddVosi*spectrumI;
bgLum = RGB2LUM*bgPrimary;
%rgPlusLum = PrimaryToSensor(calLum,rgPlusPrimary);
rgPlusLum = RGB2LUM*rgPlusPrimary;
%rgMinusLum = PrimaryToSensor(calLum,rgMinusPrimary);
rgMinusLum = RGB2LUM*rgMinusPrimary;
%sPlusLum = PrimaryToSensor(calLum,sPlusPrimary);
sPlusLum = RGB2LUM*sPlusPrimary;
%sMinusLum = PrimaryToSensor(calLum,sMinusPrimary);
sMinusLum = RGB2LUM*sMinusPrimary;

lums = sort([bgLum rgPlusLum rgMinusLum sPlusLum sMinusLum]);
fprintf('Luminance range in isoluminant plane is %0.2f to %0.2f\n',...
	lums(1), lums(end));




bgRGB = LMS2RGB_Matrix*bgLMS;


nb_color_angles = 8;
color_angles = 0:360/nb_color_angles:360;
dkl_vals_cart = zeros(nb_color_angles, 3);
rgb01_dkl = zeros(nb_color_angles, 3);
lms_nums = zeros(nb_color_angles, 3);
cart_coords = zeros(nb_color_angles, 2);
for i=1:nb_color_angles
    theta = deg2rad(color_angles(i));
    [x, y] = pol2cart(theta,1);
    cart_coords(i, :) = [x, y];
    dkl_lm_inc_chrom = x*maxRadRG*scalingF;
    dkl_s_inc_chrom = y*maxRadS*scalingF;
    dkl_vals_cart(i, :) = [0, dkl_lm_inc_chrom, dkl_s_inc_chrom]; % cart Lum/RG/S
    diffcone_coords = M_DKLToConeInc*dkl_vals_cart(i, :)';
    lms = diffcone_coords+bgLMS;
    lms_nums(i,:) = lms;
    rgb01_dkl(i,:) = LMS2RGB_Matrix*lms;
end
figure;
scatter(cart_coords(:,1),cart_coords(:,2), 200, rgb01_dkl, 'filled')
axis square
xlabel('LM')
ylabel('S')
title('8 equally spaced DKL')

rgb_monitor = [round(LUT(floor(rgb01_dkl(:,1)*256)+1,1)),...
    round(LUT(floor(rgb01_dkl(:,2)*256)+1,1)),...
    round(LUT(floor(rgb01_dkl(:,3)*256)+1,1))];

% Now the white jumps
gray = graypointRGB(1);
grays= [(gray-2*round(whiteJumps)) (gray-1*round(whiteJumps)) gray (gray+1*round(whiteJumps)) (gray+2*round(whiteJumps))]
grays_monitor = whiteLUT(grays)


%% Plot DKL
measurementDir = 'manualMeasurements\'
measurementFile = '03-Feb-2022_17_31_26.mat'
precisionFile = '03-Feb-2022_19_16_22.mat'
load([measurementDir precisionFile]);
precisions = measurements;
load([measurementDir measurementFile]);

mNums_09 = [16 34 49 60 72 100 111 117];
mNums_05 = [122 133 147 155 167 182 195 215];


LMS_09_targ = load('lms_0.9.mat');
LMS_05_targ = load('lms_0.5.mat');
LMS_09_targ = LMS_09_targ.lms_nums;
LMS_05_targ = LMS_05_targ.lms_nums;

LMS = reshape(extractfield(measurements, 'LMS'),3,[]);
LMS_gray = reshape(extractfield(precisions, 'LMS'),3,[]);
LMS_09 = LMS(:,mNums_09);
LMS_05 = LMS(:,mNums_05);
DKL_09 = M_ConeIncToDKL*(LMS_09-bgLMS);
DKL_05 = M_ConeIncToDKL*(LMS_05-bgLMS);
DKL_gray = M_ConeIncToDKL*(LMS_gray-bgLMS);
DKL_09_targ = M_ConeIncToDKL*(LMS_09_targ'-bgLMS);
DKL_05_targ = M_ConeIncToDKL*(LMS_05_targ'-bgLMS);

DKL_Map = figure;
scatter(DKL_09(2,:),DKL_09(3,:),'marker','+','DisplayName','DKL 0.9 Gamut Measured','LineWidth',2)
hold on
scatter(DKL_05(2,:),DKL_05(3,:),'marker','+','DisplayName','DKL 0.5 Gamut Measured','LineWidth',2)
scatter(DKL_gray(2,:),DKL_gray(3,:),'marker','+','DisplayName','Gray Point','LineWidth',2)
scatter(DKL_05_targ(2,:),DKL_05_targ(3,:),'filled','DisplayName','DKL 0.5 Gamut Target')
scatter(DKL_09_targ(2,:),DKL_09_targ(3,:),'filled','DisplayName','DKL 0.9 Gamut Target')
xlabel('S-[L+M]')
ylabel('L-M')
title('DKL Opponent Colors Measured on the ProPixx')
legend('location','bestoutside')
hold off

Lum_Check = figure;
scatter(repmat(1,size(DKL_09,2),1),DKL_09(1,:),'DisplayName','DKL 0.9 Gamut Measured')
hold on
scatter(repmat(2,size(DKL_09,2),1),DKL_05(1,:),'DisplayName','DKL 0.5 Gamut Measured')
scatter(repmat(1.5,size(DKL_gray,2),1),DKL_gray(1,:),'DisplayName','DKL Graypoint (Repeated Measures)')
ylabel('Luminance (L+M) Values')
xlim([0,3]);
set(gca,'xticklabel',{[]})
title('Luminance (L+M)')
legend('location','bestoutside')

%saveas(DKL_Map,'DKLMap.png')
%saveas(Lum_Check,'Luminances.png')

whitexyY = reshape(extractfield(LumValues.white,'xyYJudd'),3,[])';
redxyY = reshape(extractfield(LumValues.red,'xyYJudd'),3,[])';
greenxyY = reshape(extractfield(LumValues.green,'xyYJudd'),3,[])';
bluexyY = reshape(extractfield(LumValues.blue,'xyYJudd'),3,[])';
M_XYZ2RGB = XYZToRGBMatrix(redxyY(end,1),redxyY(end,2),greenxyY(end,1),greenxyY(end,2),bluexyY(end,1),bluexyY(end,2),whitexyY(end,1),whitexyY(end,2));
M_RGB2XYZ = inv(M_XYZ2RGB);
XYZ = M_RGB2XYZ*vertcat(rgb_monitor,graypointRGB)';
xyY = thXYZToxyY(XYZ)';
figure;
DrawChromaticity
hold on
scatter(xyY(:,1),xyY(:,2))

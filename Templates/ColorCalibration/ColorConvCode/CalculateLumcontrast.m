%% Luminance Contrast
% Computes the luminance contrast colors and the estimated RGB colors
graypointRGB = [128 128 128]; % What is the point you want luminance contrast from?
LMSGray = [0.4506 0.3763 0.2380]; % What is the cone excitation coordinates of that point?
extension = ['DKL8ColorBiasedRegionLocalizerColors']; % What extension do you want everything saved as?
lumChanges = [0.05,-0.05,0.1,-0.1,0.15,-0.15,0.2,-0.2,0.25,-0.25];

curDir = pwd; % What is the working directory?
saveDir = [curDir '\targetvalues']; % What is the output directory?
if ~isfolder(saveDir) % If the output directory doesn't exits
    mkdir(saveDir) % Make it
end

% Create the RGB to LMS matrix using your calibration file
calibName = '10-Sep-2022_NIFWideScreen20220910'; % What is the name of the files that stores the calibration information?
calibpath = 'C:\Users\Admin\Documents\fMRI-Stimuli\Templates\ColorCalibration\measurements\10-Sep-2022_NIFWideScreen20220910\'; % Where is this path?
measuresFilename = [calibName '.mat']; % Load the values of the spectra recorded
lutFilename = [calibName '_LUT.mat']; % Load the lookup table
varname = who('-file', [calibpath filesep measuresFilename]); %
load([calibpath filesep measuresFilename]); % LumValues
load([calibpath filesep lutFilename]); % LUT

whitexyY = reshape(extractfield(LumValues.white,'xyYJudd'),3,[])';
redxyY = reshape(extractfield(LumValues.red,'xyYJudd'),3,[])';
greenxyY = reshape(extractfield(LumValues.green,'xyYJudd'),3,[])';
bluexyY = reshape(extractfield(LumValues.blue,'xyYJudd'),3,[])';

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

LMS = nan([3,length(lumChanges)]);
for i = 1:length(lumChanges)
    LMS(:,i) = ((LMSGray*lumChanges(i))+LMSGray);
end


est_RGB = round(LMS2RGB_Matrix*LMS*255);
est_RGB_Lookup = horzcat(LUT(est_RGB(1,:)+1,1),LUT(est_RGB(2,:)+1,2),LUT(est_RGB(3,:)+1,3))';

disp('LMS Values')
disp(LMS)
disp('Estimated RGB Values (no lookup)')
disp(est_RGB)
disp('Estimated RGB Values (lookup)')
disp(est_RGB_Lookup)

csvwrite([saveDir '\' extension '_LMS_Lumcontrast.csv'],LMS');
csvwrite([saveDir '\' extension '_RGB_Lumcontrast.csv'],est_RGB_Lookup');

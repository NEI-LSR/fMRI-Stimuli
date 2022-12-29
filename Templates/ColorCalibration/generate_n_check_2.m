clear 
close all

calibName = '26-Jan-2022_PROPIXSmallNoFilter'; % calib
calibpath = pwd;
measuresFilename = [calibName '.mat'];
lutFilename = [calibName '_LUT.mat'];
varname = who('-file', [calibpath filesep measuresFilename]); %
load([calibpath filesep measuresFilename]); % LumValues
load([calibpath filesep lutFilename]); % LUT

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
bgLMS = RGB2LMS_Matrix*[0.5 0.5 0.5]';

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
scalingF = 0.40; % in proportion of maximum gamut excursion

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

% Now we have the coordinates we desire, make a picture of the
% isoluminant plane.
imageSize = 513;

[X,Y] = meshgrid(0:imageSize-1,0:imageSize-1);
X = X-(imageSize-1)/2; Y = Y-(imageSize-1)/2;
X = X/max(abs(X(:))); Y = Y/max(abs(Y(:)));
XVec = reshape(X,1,imageSize^2); YVec = reshape(Y,1,imageSize^2);
imageLMS = bgLMS*ones(size(XVec))+rgConeInc*XVec+sConeInc*YVec;
%[imageRGB,badIndex] = SensorToSettings(calLMS,imageLMS);
imageRGB = LMS2RGB_Matrix*imageLMS; 
gamut = imageRGB;
primary = gamut;
[m,n] = size(gamut); % find values outside gamut
badIndex = zeros(1,n);
tolerance = 1e-10;

% Check lower bound by rows
for (i=1:m)
  index = find(primary(i,:) < 0);
  if (~isempty(index))
    gamut(i,index) = zeros(1,length(index));
		index = find(primary(i,:) < -tolerance);
		if (~isempty(index))
			badIndex(index) = ones(1,length(index));
		end
  end
end
% Check upper bound by rows
for (i=1:m)
  index = find(primary(i,:) > 1);
  if (~isempty(index))
    gamut(i,index) = ones(1,length(index));
		index = find(primary(i,:) > 1+tolerance);
		if (~isempty(index))
    	badIndex(index) = ones(1,length(index));
		end
  end
end

bgRGB = LMS2RGB_Matrix*bgLMS;
imageRGB(:,find(badIndex == 1)) = bgRGB(:,ones(size(find(badIndex == 1))));
rPlane = reshape(imageRGB(1,:),imageSize,imageSize);
gPlane = reshape(imageRGB(2,:),imageSize,imageSize);
bPlane = reshape(imageRGB(3,:),imageSize,imageSize);
theImage = zeros(imageSize,imageSize,3);
theImage(:,:,1) = rPlane;
theImage(:,:,2) = gPlane;
theImage(:,:,3) = bPlane;

% Show the image for illustrative purposes
figure; clf; image(theImage);
title('equiluminant plane')


nb_color_angles = 16;
color_angles = 0:360/nb_color_angles:360;
dkl_vals_cart = zeros(nb_color_angles, 3);
rgb01_dkl = zeros(nb_color_angles, 3);
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
    rgb01_dkl(i,:) = LMS2RGB_Matrix*lms;
end
figure;
scatter(cart_coords(:,1),cart_coords(:,2), 200, rgb01_dkl, 'filled')
axis square
xlabel('LM')
ylabel('S')
title('16 equally spaced DKL')

rgb_monitor = [round(LUT(floor(rgb01_dkl(:,1)*256)+1,1)),...
    round(LUT(floor(rgb01_dkl(:,2)*256)+1,1)),...
    round(LUT(floor(rgb01_dkl(:,3)*256)+1,1))];
% rgb_monitor = [round(LUT(floor(rgb01_dkl(:,1)*65535)+1,1)),...
%     round(LUT(floor(rgb01_dkl(:,2)*65535)+1,1)),...
%     round(LUT(floor(rgb01_dkl(:,3)*65535)+1,1))];

% now that we have the rgb values corresponding to the dkl ones
% lets compute the corresponding LUV we'd expect
rxyY = LumValues.red(end).xyYJudd; 
rx=rxyY(1); ry=rxyY(2); rz=1-rx-ry;
gxyY = LumValues.green(end).xyYJudd; 
gx=gxyY(1); gy=gxyY(2); gz=1-gx-gy;
bxyY = LumValues.blue(end).xyYJudd; 
bx=bxyY(1); by=bxyY(2); bz=1-bx-by;

%XYZwhite % normed Y=1
rgb2xyz_M = ...
    [rx, gx, bx;
    ry, gy, by;
    rz, gz, bz];
xyz2XYZ_s = inv(rgb2xyz_M)*XYZwhite;
xyz2XYZ_M = ...
    [xyz2XYZ_s(1), 0, 0;
    0, xyz2XYZ_s(2), 0;
    0, 0, xyz2XYZ_s(3)];
RGB2XYZ_Matrix = rgb2xyz_M*xyz2XYZ_M;
XYZ2RGB_Matrix = inv(RGB2XYZ_Matrix);

test_dkl1_XYZ = RGB2XYZ_Matrix*rgb01_dkl';
test_dkl1_xyY = XYZToxyY(test_dkl1_XYZ);
test_dkl1_uv = XYZTouv(test_dkl1_XYZ);
test_dkl1_LUV = XYZToLuv(test_dkl1_XYZ, XYZwhite);

% plot colors u'v'
figure;
scatter(test_dkl1_uv(1,:), test_dkl1_uv(2,:),...
    repmat(200, [1, length(test_dkl1_uv)]), rgb01_dkl, 'filled')
title('16 equally spaced DKL in LUV')
xlabel('u')
ylabel('v')

chroma = sqrt(test_dkl1_LUV(2,:).^2+test_dkl1_LUV(3,:).^2);
hue_angles = atan2(test_dkl1_LUV(3,:), test_dkl1_LUV(2,:));
hue_angles_deg = mod(rad2deg(hue_angles), 360);

% S.color_angles_dkl = color_angles;
% S.color_angles_luv = hue_angles_deg;
% S.rgb_vals = rgb_monitor;
% S.uv = test_dkl1_uv;
% save('13-Sep-DKL8_Sat3_to_check.mat', '-struct', 'S')


% Now generate Luv coords equally spaced chroma 41 and compute
% corresponding DKL hue angles cf Josh's code
aiLuminanceLevels = [0.0]; %[0.0]
aiChromaLevels = [0.21];%[0.41];
azimuthRad{1} = deg2rad(0:1:359); %deg2rad(0:22.5:359.9999);

graypointXYZ = RGB2XYZ_Matrix*[0.75 0.75 0.75]';%[0.5 0.5 0.5]';
graypointLUV = XYZToLuv(graypointXYZ, RGB2XYZ_Matrix*[1,1,1]');

iCoords = 1;
for iChroma = 1:numel(aiChromaLevels)
    LUVRadiusMultiplier = aiChromaLevels(iChroma);
    [aiUCoordinate, aiVCoordinate] = deal([]);
     [aiUCoordinate, aiVCoordinate, aiLCoordinate] = ...
                    sph2cart(azimuthRad{iChroma},0,100*LUVRadiusMultiplier);   

    for iCoordsIter = 1:numel(aiUCoordinate)          
        thisLUVCoord(iCoords,:) = [graypointLUV(1) + aiLuminanceLevels(iChroma),aiUCoordinate(iCoordsIter)+graypointLUV(2), aiVCoordinate(iCoordsIter)+graypointLUV(3)];
        thisLUVParam(iCoords,:) = [rad2deg(azimuthRad{iChroma}(iCoordsIter)), aiLuminanceLevels(iChroma), aiChromaLevels(iChroma)];
        targetLUV = [graypointLUV(1) + aiLuminanceLevels(iChroma),aiUCoordinate(iCoordsIter)+graypointLUV(2), aiVCoordinate(iCoordsIter)+graypointLUV(3)];
        [targetXYZCoords(iCoordsIter,:)] = LuvToXYZ(targetLUV',RGB2XYZ_Matrix*([1; 1; 1]));
        [targetuvCoords(iCoordsIter,:)] = XYZTouv(targetXYZCoords(iCoordsIter,:)');
        [targetRGB(iCoords,:)] = XYZ2RGB_Matrix*targetXYZCoords(iCoordsIter,:)';
        targetGammaCorrected(iCoords,1) = round(LUT(floor(targetRGB(iCoords,1)*256)+1,1));
        targetGammaCorrected(iCoords,2) = round(LUT(floor(targetRGB(iCoords,2)*256)+1,2));
        targetGammaCorrected(iCoords,3) = round(LUT(floor(targetRGB(iCoords,3)*256)+1,3));
%         targetGammaCorrected(iCoords,1) = round(LUT(floor(targetRGB(iCoords,1)*65535)+1,1));
%         targetGammaCorrected(iCoords,2) = round(LUT(floor(targetRGB(iCoords,2)*65535)+1,2));
%         targetGammaCorrected(iCoords,3) = round(LUT(floor(targetRGB(iCoords,3)*65535)+1,3));
        iCoords = iCoords + 1;
    end
end

figure;
scatter3(thisLUVCoord(:, 1), thisLUVCoord(:, 2), thisLUVCoord(:, 3),...
repmat(200, [1, length(thisLUVCoord)]), targetRGB, 'filled')
axis square

figure;
scatter(targetuvCoords(:, 1), targetuvCoords(:, 2),...
 repmat(200, [1, length(targetuvCoords)]), targetRGB, 'filled')
axis square

% now compute DKL angles
lms_vals = RGB2LMS_Matrix*targetRGB';
lms_inc_vals = lms_vals-bgLMS;
dkl_cart = M_ConeIncToDKL*lms_inc_vals; %Lum, RG, BY
dkl_cart = [dkl_cart(1,:); dkl_cart(2,:)/maxRadRG;dkl_cart(3,:)/maxRadS];
%     dkl_lm_inc_chrom = x*maxRadRG*scalingF;
%     dkl_s_inc_chrom = y*maxRadS*scalingF;
    
figure;
scatter3(dkl_cart(1,:), dkl_cart(2,:), dkl_cart(3,:),...
    repmat(200, [1, length(dkl_cart)]), targetRGB, 'filled')
axis square
xlabel('Lum')
ylabel('RG')
zlabel('BY')

[dkl_angles, r] = cart2pol(dkl_cart(2,:), dkl_cart(3,:));
dkl_angles_deg = mod(rad2deg(dkl_angles), 360);
figure;
polarscatter(dkl_angles, repmat(1, size(dkl_angles)),...
    repmat(200, size(dkl_angles)), targetRGB, 'filled')

S2.color_angles_luv = deg2rad(azimuthRad{1});
S2.rgb_vals = targetGammaCorrected;
S2.color_angles_dkl = dkl_angles_deg;
%save('13-Sep-LUV16_chroma41_to_check.mat', '-struct', 'S2')


%% Make circular luv 
figure;
polarscatter(azimuthRad{1}, repmat(1, size(azimuthRad{1})),...
    repmat(300, size(azimuthRad{1})), targetRGB, 'filled')
hold on
xvals = 0:deg2rad(0.5):deg2rad(360);
max = 0.9;
min = 0;
center = deg2rad(55.4746);
spread = deg2rad(8.5);
yvals = fnWrappedGaussian2([max spread center min], xvals, 'rad');
polarplot(xvals, yvals, 'k', 'LineWidth', 2)
Ax = gca; % current axes
Ax.ThetaGrid = 'on';
Ax.RGrid = 'off';
Ax.RTickLabel = []; 
Ax.ThetaTickLabel = [];
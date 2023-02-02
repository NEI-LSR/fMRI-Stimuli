function [rgb, luv, gry] = LUV_to_RGB_James_byJames(numColor, chromaVal, grayVal, calibName, dmp)
	
	
	persistent calibFileName LumValues LUT
	
	samedata = 0;
	
	% 	ncolor
	% 	sat
	% 	bright
	% calib
	
	if nargin < 1
		numColor = 36;
	end;
	
	if nargin < 2
		chromaVal = 0.55;
	end;
	
	if nargin < 3
		grayVal = 0.5;
	end;
	
	if nargin < 4
		% uiget calib name
		[f, p] = uigetfile('*.mat', 'Choose calibration file');
		
		oldCalibName = fullfile(p, f);
		
	else
		oldCalibName = fullfile(pwd, calibName);
	end;
	
	if strcmp(oldCalibName, calibFileName)
		samedata = 1;
	else
		calibFileName = oldCalibName;
	end;
	
	[fpth, froot, fext] = fileparts(calibFileName);
	calibFileRoot = fullfile(fpth, froot);
	
	curveplot = 0;
	colorplot = 0;
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Creates gamma corrected RGB values for 36 equally spaced hue angles in
	% CieLuv color space (at mid-luminance). For most conversions between color
	% spaces, I use the psychtoolbox functions (written by Brainard, the color
	% gourou), here I put them at the end of this script
	%
	% by Marianne for James, Feb 2021
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	%% Create LUT from measured values
	% also will show gamma fits and inverse for visual check
	
	% 	path = pwd;
	% 	fileroot = calibFileName; % calib
	% 	global path fileroot
	%LUT = makelutNEW_James(8, calibFileRoot, curveplot);
	LUT = makelutNEW(8, calibFileRoot);
	%%  Load the monitor calibration
	% to get the spectrum of all 3 guns & the white point
	% also to get the LookUp Table for future gamma correction
	
	if ~samedata | isempty(LumValues)
		load(calibFileName); %LumValues
	end;
	% 	lutFilename = [calibFileName '_LUT.mat']; %because bug name file creation
	% 	load(lutFilename); % LUT
	
	
	xyYwhite = LumValues.white(end).xyYJudd; % Note: use Judd corrected
	%xyYwhite = [xyYwhite(1:2) 1]; % set Y = 1 / not necessary - will use XYZ
	%in physical units coordinates
	XYZwhite = xyYToXYZ(xyYwhite');
	
	%% Need to compute a few conversion Matrices
	% the ones that depend on the monitor
	% XYZ to RGB and inverse (inverse not used here)
	
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
	xyz2XYZ_s = rgb2xyz_M\XYZwhite;
	xyz2XYZ_M = ...
		[xyz2XYZ_s(1), 0, 0;
		0, xyz2XYZ_s(2), 0;
		0, 0, xyz2XYZ_s(3)];
	RGB2XYZ_Matrix = rgb2xyz_M*xyz2XYZ_M;
	XYZ2RGB_Matrix = inv(RGB2XYZ_Matrix);
	
	%% Generate values Luv
	
	nbAngles = numColor;
	aiLuminanceLevels = [0.0];
	aiChromaLevels = [chromaVal]; % highest chroma that gives RGB in range, but could use lower if prefers!
	azimuthRad{1} = deg2rad(0:360/nbAngles:359.9999);
	
	graypointXYZ = RGB2XYZ_Matrix*[grayVal grayVal grayVal]';
	graypointLUV = XYZToLuv(graypointXYZ, RGB2XYZ_Matrix*[1,1,1]');
	
	iCoords = 1;
	for iChroma = 1:numel(aiChromaLevels)
		LUVRadiusMultiplier = aiChromaLevels(iChroma);
		% 		[aiUCoordinate, aiVCoordinate] = deal([]);
		[aiUCoordinate, aiVCoordinate, aiLCoordinate] = ...
			sph2cart(azimuthRad{iChroma},0,100*LUVRadiusMultiplier);
		
		for iCoordsIter = 1:numel(aiUCoordinate)
			thisLUVCoord(iCoords,:) = [graypointLUV(1) + aiLuminanceLevels(iChroma),aiUCoordinate(iCoordsIter)+graypointLUV(2), aiVCoordinate(iCoordsIter)+graypointLUV(3)];
			thisLUVParam(iCoords,:) = [rad2deg(azimuthRad{iChroma}(iCoordsIter)), aiLuminanceLevels(iChroma), aiChromaLevels(iChroma)];
			targetLUV =               [graypointLUV(1) + aiLuminanceLevels(iChroma),aiUCoordinate(iCoordsIter)+graypointLUV(2), aiVCoordinate(iCoordsIter)+graypointLUV(3)];
            targetLUVCoords(iCoordsIter,:) = targetLUV;
			[targetXYZCoords(iCoordsIter,:)] = LuvToXYZ(targetLUV',RGB2XYZ_Matrix*([1; 1; 1]));
			[targetuvCoords(iCoordsIter,:)] = XYZTouv(targetXYZCoords(iCoordsIter,:)');
			[targetRGB(iCoords,:)] = XYZ2RGB_Matrix*targetXYZCoords(iCoordsIter,:)';
			if sum(targetRGB(iCoords,:) < 0)+sum(targetRGB(iCoords,:) > 1.) ~= 0
				error('outside range');
				break
			else
				targetGammaCorrected(iCoords,1) = LUT(round(targetRGB(iCoords,1)*255), 1);
				targetGammaCorrected(iCoords,2) = LUT(round(targetRGB(iCoords,2)*255), 2);
				targetGammaCorrected(iCoords,3) = LUT(round(targetRGB(iCoords,3)*255), 3);
                if sum(targetRGB(iCoords,:) < 0)+sum(targetRGB(iCoords,:) > 1.) ~= 0
                end
			end
			
			iCoords = iCoords + 1;
		end
    end
	greyXYZ = LuvToXYZ(graypointLUV, RGB2XYZ_Matrix*([1; 1; 1]));
	greyuv = XYZTouv(greyXYZ);
	greyRGB = XYZ2RGB_Matrix*greyXYZ;
	correctedGrey(1) = LUT(round(greyRGB(1)*255),1);
	correctedGrey(2) = LUT(round(greyRGB(2)*255),2);
	correctedGrey(3) = LUT(round(greyRGB(3)*255),3);
	
	if colorplot
		figure;
		subplot(1,2,1);
		scatter(thisLUVCoord(:, 2), thisLUVCoord(:, 3),...
			repmat(200, [1, length(thisLUVCoord)]), targetRGB, 'filled')
		xlabel('u*')
		ylabel('v*')
		xc = thisLUVCoord(:, 2)';
		yc = thisLUVCoord(:, 3)';
		txt = num2str(round(rad2deg(azimuthRad{1}')));
		for i=1:length(xc)
			text(xc(i), yc(i), txt(i,:))
		end
		title('Colors before gamma correction')
		xlim([-55, 55]);
		ylim([-55, 55]);
		axis square
		% 		saveas(f, '36_colors_NotGammaCorrected.png', 'png')
		
		subplot(1,2,2);
		scatter(thisLUVCoord(:, 2), thisLUVCoord(:, 3),...
			repmat(200, [1, length(thisLUVCoord)]), targetGammaCorrected/255, 'filled')
		xlabel('u*')
		ylabel('v*')
		for i=1:length(xc)
			text(xc(i), yc(i), txt(i,:))
		end
		title('Colors after gamma correction')
		xlim([-55, 55]);
		ylim([-55, 55]);
		axis square;
		% 		saveas(f, '36_colors_gammaCorrected.png', 'png')
		
		suptitle(['chroma = ',num2str(chromaVal),', grey = ',num2str(grayVal)]);
	end;
	
	if nargout
		rgb = targetGammaCorrected/255;
		if nargout > 1
			luv = thisLUVCoord;
		end;
	end;
	
	%% write values to file (tab separated)
    if dmp
	    filename = fullfile([calibName, '_corrRGB.txt']);
	    fid = fopen(filename, 'wt');
	    fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'LUV_angle','correctR','correctG','correctB', 'linearR', 'linearG', 'linearB');  % header
	    fclose(fid);
	    dlmwrite(filename, [rad2deg(azimuthRad{1})', targetGammaCorrected, targetRGB],'delimiter','\t','-append');
	    
	    
 	    dumpRGB(targetGammaCorrected, correctedGrey, [calibFileRoot, '_CorrectedRGB']);
    end
	gry = correctedGrey;

    %% Write XYZ, LUV, uv, and Target RGB to file (comma separated) Stuart Duffield January 2023
    % The first target will be the gray.
    targetcentereduvCoords = [greyuv'-greyuv';greyuv'-targetuvCoords];
    if dmp
        csvwrite(fullfile([calibName, '_tRGB.csv']),[correctedGrey;targetGammaCorrected]);
        csvwrite(fullfile([calibName, '_tXYZ.csv']),[greyXYZ';targetXYZCoords]);
        csvwrite(fullfile([calibName, '_tLUV.csv']),[graypointLUV';targetLUVCoords]);
        csvwrite(fullfile([calibName, '_tuv.csv']),[greyuv';targetuvCoords]);
        csvwrite(fullfile([calibName, '_tcentereduv.csv']),targetcentereduvCoords);

    end


	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%                      FUNCTIONS USED - ALL ARE HERE                      %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	
function XYZ = xyYToXYZ(xyY)
	% XYZ = xyYToXYZ(xyY)
	%
	% Compute tristimulus coordinates from
	% chromaticity and luminance.
	%
	% 8/24/09  dhb  Look at it.
	
	[m,n] = size(xyY);
	XYZ = zeros(m,n);
	for i = 1:n
		z = 1 - xyY(1,i) - xyY(2,i);
		XYZ(1,i) = xyY(3,i)*xyY(1,i)/xyY(2,i);
		XYZ(2,i) = xyY(3,i);
		XYZ(3,i) = xyY(3,i)*z/xyY(2,i);
	end
	
function XYZ = LuvToXYZ(Luv,whiteXYZ)
	% XYZ = LuvToXYZ(Luv,whiteXYZ)
	%
	% 10/10/93    dhb   Converted from CAP C code.
	% 5/9/02      dhb   Improved help.
	
	% Get white point u and v
	uv0 = XYZTouv(whiteXYZ);
	
	% Compute Y
	Y = LxxToY(Luv,whiteXYZ);
	
	% Compute u,v from ustar and vstar
	u = (Luv(2,:) ./ (13.0 * Luv(1,:)) ) + uv0(1);
	v = (Luv(3,:) ./ (13.0 * Luv(1,:)) ) + uv0(2);
	
	% Compute XYZ from Yuv
	X = (9.0 / 4.0) * (u./v) .*  Y;
	Z = ( ((4.0 - u).*X)./(3.0*u) ) - (5.0 * Y);
	
	% Put together the answer
	XYZ = [X ; Y ; Z];
	
function uv = XYZTouv(XYZ,compute1960)
	% uv = XYZTouv(XYZ,[compute1960])
	%
	% Compute uv from XYZ.
	%
	% These are u',v' chromaticity coordinates in notation
	% used by CIE.  See CIE Colorimetry 2004 publication, or Wyszecki
	% and Stiles, 2cd, page 165.
	%
	% Note that there is an obsolete u,v chromaticity diagram that is similar
	% but uses 6 in the numerator for v rather than the 9 that is used for v'.
	% See CIE Colorimetry 2004, Appendix A, or Judd and Wyszecki, p. 296. If
	% you want this (maybe to compute correlated color temperatures), you can
	% pass this as 1.  It is 0 by default.
	%
	% 10/10/93  dhb   Created by converting CAP C code.
	% 5/06/11   dhb   More extensive comment.  Optional 1960 version.
	
	%% Handle optional arg
	if (nargin < 2 || isempty(compute1960))
		compute1960 = 0;
	end
	
	%% Find size and allocate
	[m,n] = size(XYZ);
	uv = zeros(2,n);
	
	% Compute u and v
	denom = [1.0,15.0,3.0]*XYZ;
	uv(1,:) = (4*XYZ(1,:)) ./ denom(1,:);
	if (compute1960)
		uv(2,:) = (6*XYZ(2,:)) ./ denom(1,:);
	else
		uv(2,:) = (9*XYZ(2,:)) ./ denom(1,:);
	end
	
function luv = XYZToLuv(xyz,whiteXYZ)
	% luv = XYZToLuv(xyz,whiteXYZ)
	%
	% xyz is a 3 x N matrix with xyz in columns
	% whiteXYZ is a 3 vector of the white point
	% luv is a 3 x N matrix with L*u*v* in the columns
	%
	% Formulae are taken from Wyszecki and Stiles, page 167.
	%
	% xx/xx/xx    baw  Created.
	% xx/xx/xx    dhb  Made compatible with version 3.5
	% 10/10/93    dhb  Changed name to XYZToLuv
	% 5/9/02      dhb  Improved help.
	
	% Check xyz dimensions
	[m,n] = size(xyz);
	if ( m ~= 3 )
		error('Array xyz must have three rows')
	end
	
	% Check white point dimensions
	[m,n] = size(whiteXYZ);
	if ( m ~= 3 || n ~= 1)
		error('Array white is not a three vector')
	end
	
	% Separate out the compontents
	X = xyz(1,:); Y = xyz(2,:); Z = xyz(3,:);
	Xn = whiteXYZ(1); Yn = whiteXYZ(2); Zn = whiteXYZ(3);
	
	% Compute u and v for white point
	uw = (4.0 * Xn) / (Xn + 15.0*Yn + 3.0*Zn);
	vw = (9.0 * Yn) / (Xn + 15.0*Yn + 3.0*Zn);
	
	% Allocate space
	[m,n] = size(xyz);
	luv = zeros(m,n);
	
	% Compute L
	lY = find( (Y/Yn) < 0.008856 );
	bY = find( (Y/Yn) >= 0.008856);
	if ( length(bY) ~= 0 )
		luv(1,bY) = 116*(Y(bY)/Yn).^(1/3) - 16;
	end
	if ( length(lY) ~= 0 )
		luv(1,lY) = 903.3 * (Y(lY)/Yn);
	end
	
	% Compute u and v
	uv = XYZTouv(xyz);
	
	% Compute u* and v*
	luv(2,:) = 13 * luv(1,:) .* (uv(1,:) - uw);
	luv(3,:) = 13 * luv(1,:) .* (uv(2,:) - vw);
	
function Y = LxxToY(Lxx,white)
	% Y = LxxToY(Lxx,white)
	%
	% Convert either Lab or Luv to Y, given the XYZ coordinates of
	% the white point.
	%
	% 10/10/93    dhb   Converted from CAP C code.
	
	% Get white point Y and Lstar out of arguments
	Lstar = Lxx(1,:);
	Yn = white(2);
	
	% Find size and allocate space
	[m,n] = size(Lxx);
	Y = zeros(1,n);
	
	% Compute Y by inverting conventional formula
	Y = Yn * (((Lstar + 16.0)/116.0).^ 3.0);
	
	% Check range to make sure that formula was correct.
	% Because Lstar is a monotonic function of Y/Yn, this method
	% of checking the range is OK.
	redoIndex = find( (Y/Yn) < 0.008856 );
	if (~isempty(redoIndex))
		Y(redoIndex) = Yn*(Lstar(redoIndex)/903.3);
	end
	
	
	
	
	%***********************************************************%
	%***********************************************************%
	%***********************************************************%
function dumpRGB(rgb, gry, fnm)
	
	spotfilename = [fnm,'.txt'];
	
	
	fid = fopen(spotfilename, 'w');
	
	ccmp = {'red', 'green', 'blue'};
	
	gry = round(gry);
	
	for cc = 1:length(ccmp)
		
		fprintf(fid, '%s', [ccmp{cc}, ' = [']);
		
		
		nc = size(rgb,1);
		
		for c = 1:(nc-1)
			
			val = rgb(c, cc);
			val = round(val);
			fprintf(fid, '%d, ', val);
			
		end;
		val = rgb(nc, cc);
		val = round(val);
		fprintf(fid, '%d', val);
		
		
		fprintf(fid, '%s\r\n', '];');
		
		
	end;
	fprintf(fid, 'grey = [%d, %d, %d];\r\n', gry(1), gry(2), gry(3));
	fclose(fid);
	

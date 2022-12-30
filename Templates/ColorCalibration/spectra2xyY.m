function xyY = spectra2xyY(S, color_matching_function)
%SPECTRA2XYY  Convert spectra to xy chromaticity values and luminance Y.  
%for a given spectra there will be one triplet xyY value
% Thorsten Hansen 2008-06-05

%this calls up the appropriate color matching functions
switch color_matching_function
 case {'judd' 'Judd'}
  filename =  'ciexyzj.txt'; % from http://www.cvrl.org/
 case {'cie1931' 'CIE1931'}
  filename =  'ciexyz31_1.txt'; % from http://www.cvrl.org/
 otherwise
  error(['Unknown color matching function '  ...
         color_matching_function '.'])
end

%this reads the color matching function text file
[wavelength x_bar y_bar z_bar] = ...
    textread(filename, '', 'delimiter', ',');

x1 = wavelength;
y1 = [x_bar y_bar z_bar];
wavelength_spectra = S(:,1);
spectra_measured = S(:, 2:end);

%this samples the color matching data and the spectral data at the same intervals
[wavelength_common xyz_common spectra_measured_common] = ...
    commondomain(x1, y1, wavelength_spectra, spectra_measured);

XYZ = spectra_measured_common'*xyz_common;
xyY = thXYZToxyY(XYZ')';
xyY(:,3) = xyY(:,3)*683; % radiance to candela


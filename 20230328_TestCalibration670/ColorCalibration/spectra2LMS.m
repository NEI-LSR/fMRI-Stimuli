function LMS = spectra2LMS(S, color_matching_function)
%SPECTRA2LMS

%this calls up the appropriate color matching functions
switch color_matching_function
 case {'LMS' 'lms'}
    conefundsSP = csvread('conefund_smithpokorny.csv');
    %conesensitivities = [conefundsSP(:, 1), temp];
    temp = 10.^conefundsSP(:, 2:4);
    con_sens_ax1 = conefundsSP(:, 1);
    trans_temp = repmat(1./max(temp), 90, 1);
    conesensitivities = [con_sens_ax1, temp.*trans_temp];
 otherwise
    error(['Unknown color matching function '  ...
         color_matching_function '.'])
end

%this reads the color matching function text file
wavelength = conesensitivities(:,1);
x1 = wavelength;
y1 = [conesensitivities(:,2) conesensitivities(:,3) conesensitivities(:,4)];
wavelength_spectra = S(:,1);
spectra_measured = S(:, 2:end);

%this samples the color matching data and the spectral data at the same intervals
[wavelength_common lms_common spectra_measured_common] = ...
    commondomain(x1, y1, wavelength_spectra, spectra_measured);

LMS = spectra_measured_common'*lms_common;

return 

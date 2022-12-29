function [LMS] = XYZtoLMS(XYZ)
% 05/09/2022 Stuart Duffield

[m n] = size(XYZ);

if m ~= 3
    error('XYZ values must be given as a column vector')
end

vonKriesM = [0.38971 0.68898 -0.07868;-0.22981 1.18340 0.04641; 0 0 1];

LMS = vonKriesM*XYZ;


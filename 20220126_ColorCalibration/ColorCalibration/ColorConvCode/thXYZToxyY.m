function [xyY] = thXYZToxyY(XYZ)
% 2008-05-06  Thorsten Hansen
% modified from XYZToxyY.m in the Psychotoolbox: vectorized
% implementation, error added


[m n] = size(XYZ);

if m ~= 3
  error('XYZ values must be given as column vector.')
end

X = XYZ(1,:);
Y = XYZ(2,:);
Z = XYZ(3,:);

sumXYZ = sum(XYZ);


x = X./sumXYZ;
y = Y./sumXYZ;

xyY =  [x; y; Y];

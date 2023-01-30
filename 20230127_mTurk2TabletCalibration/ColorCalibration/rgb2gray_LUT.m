function grayImage = rgb2gray_LUT(image, LumValuesPath, gammaTablePath)
% Creates an grayscale image that matches the luminance of the colored
% image according to the monitor.
% Stuart Duffield 06 2022
% Inputs:
% Image: an RGB (height x width x color) image
% LumValuesPath: the path to the lum values from the monitor calibration.
% See the script 'wrappingSomething' by Marianne Duyck ~2019 
% gammaTablePath: the path to the gamma table values from the monitor
% calibration.
%
% Outputs:
% Gray Image

load(LumValuesPath); % Load LumValues
load(gammaTablePath); % Load gamma table

RLC = LumValues.red(end).xyYJudd(end)/LumValues.white(end).xyYJudd(end);
GLC = LumValues.green(end).xyYJudd(end)/LumValues.white(end).xyYJudd(end);
BLC = LumValues.blue(end).xyYJudd(end)/LumValues.white(end).xyYJudd(end);

WLC = RLC + GLC + BLC;
RLC = RLC/WLC;
GLC = GLC/WLC;
BLC = BLC/WLC;


gammaLength = size(GammaTable,1); % Get length of gamma table

gammaTableNew = [interp1(GammaTable(:,1),linspace(0,gammaLength,256))' interp1(GammaTable(:,2),linspace(0,gammaLength,256))' interp1(GammaTable(:,3),linspace(0,gammaLength,256))'];


% New relative gamma table position times luminance contribution

grayImage = zeros(size(image,1),size(image,2),"uint8");

for i = 1:size(image,1)
    for j = 1:size(image,2)
        grayVal = round(gammaTableNew(image(i,j,1)+1,1)*255*RLC + gammaTableNew(image(i,j,2)+1,2)*255*GLC + gammaTableNew(image(i,j,3)+1,3)*255*BLC);
        grayImage(i,j) = grayVal;
    end
end


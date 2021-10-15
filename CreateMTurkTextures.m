%% Set Up Directory Structure
curDir = pwd; %also circle directory
CIRCdir = fullfile(curDir,'circle')
ACHdir = fullfile(curDir,'achromatic');
CHdir = fullfile(curDir,'chromatic');

%% Prepare images
imageNumbers = 14;
for i = 1:imageNumbers
    [imgCH{i},~,alphaCH{i}] = imread(fullfile(CHdir, [num2str(i) '.png']));
    [imgACH{i},~,alphaACH{i}] = imread(fullfile(ACHdir, [num2str(i) '.png']));
    maskCH{i} = (alphaCH{i} == 0);
    maskACH{i} = (alphaACH{i} == 0);
end

[imgCircle,~,alphaCircle] = imread(fullfile(CIRCdir, 'colorCircle.png'));
alphaCircle = 255-alphaCircle;
%% Color Params
file_colors= round(csvread('/Users/duffieldsj/Documents/GitHub/Personal-Scripts/woosterNIFRGB.csv'))
file_colors(file_colors>255) = 255;
cRED = file_colors(2:15,1)'
cGREEN = file_colors(2:15,2)'
cBLUE = file_colors(2:15,3)'
backgroundRGB = file_colors(1,:)
% cRED = [246, 142, 209, 121, 142, 81, 83, 48, 162, 93, 236, 136, 191, 110];
% cGREEN = [134, 77, 165, 96, 187, 108, 190, 109, 163, 94, 125, 73, 165, 94];
% cBLUE = [175, 97, 95, 52, 129, 71, 218, 120, 255, 153, 255, 142, 198, 109];
% backgroundRGB = [152, 132, 151];
%% Create Colored Images
background = cat(3,uint8(zeros(size(alphaCircle))+backgroundRGB(1)),uint8(zeros(size(alphaCircle))+backgroundRGB(2)),uint8(zeros(size(alphaCircle))+backgroundRGB(3)));

for i = 1:imageNumbers
    chrom(:,:,:,i) = imoverlay(imgCH{i},maskCH{i},[cRED(i),cBLUE(i),cGREEN(i)]/255);
    chromBW(:,:,:,i) = imoverlay(imgCH{i},maskCH{i},backgroundRGB/255);
    achrom(:,:,:,i) = imoverlay(imgACH{i},maskACH{i},backgroundRGB/255);
    circle = zeros(size(imgCircle));
    
    red = uint8(zeros(size(alphaCircle))+cRED(i));
    green = uint8(zeros(size(alphaCircle))+cGREEN(i));
    blue = uint8(zeros(size(alphaCircle))+cBLUE(i));
    bgd = imshow(background)
    hold on
    color = cat(3,uint8(red),uint8(green),uint8(blue));
    c = imshow(color)
    set(c,'AlphaData',alphaCircle)
    set(gca,'LooseInset',get(gca,'TightInset'));
    exportgraphics(gca, [num2str(i) 'circle.png'], 'BackgroundColor','none')
    circle_import = imread([num2str(i) 'circle.png']);
    final = circle_import(9:end-9,9:end-9,:);
    colorcircles(:,:,:,i) = final;
end


%% Save the stimuli as mat files
save('chrom.mat', 'chrom')
save('chromBW.mat', 'chromBW')
save('achrom.mat', 'achrom')
save('colorcircles.mat','colorcircles')


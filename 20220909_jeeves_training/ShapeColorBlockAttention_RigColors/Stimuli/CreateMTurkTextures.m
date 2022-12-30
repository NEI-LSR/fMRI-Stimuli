%% Set Up Directory Structure
clear;
curDir = pwd; %also circle directory
CIRCdir = fullfile(curDir,'circle')
ACHdir = fullfile(curDir,'achromatic');
CHdir = fullfile(curDir,'chromatic');

%% Prepare images
imageNumbers = 14;
for i = 1:imageNumbers
    [imgCH{i},~,alphaCH{i}] = imread(fullfile(CHdir, [num2str(i) '.png']));
    [imgACH{i},~,alphaACH{i}] = imread(fullfile(ACHdir, [num2str(i) '.png']));
    [~,~,maskCH{i}] = imread(fullfile(CHdir, [num2str(i) '_mask.png']));
    [~,~,maskACH{i}] = imread(fullfile(ACHdir, [num2str(i) '_mask.png']));
end

[imgCircle,~,alphaCircle] = imread(fullfile(CIRCdir, 'colorCircle.png'));
alphaCircle = 255-alphaCircle;
%% Color Params
allCols = [118,98,128; 201,101,124;114,61,73;167,136,0;95,79,0;98,152,24;73,95,0;58,142,181;49,88,100;124,108,243;83,73,135;191,79,223;113,61,123;150,125,157;92,79,87]
cRED = allCols(:,1)';
cGREEN = allCols(:,2)';
cBLUE = allCols(:,3)';
backgroundRGB = [150, 132, 153];


%% Create Colored Images
background = cat(3,uint8(zeros(size(alphaCircle))+backgroundRGB(1)),uint8(zeros(size(alphaCircle))+backgroundRGB(2)),uint8(zeros(size(alphaCircle))+backgroundRGB(3)));

for i = 1:imageNumbers
    

    chrom(:,:,:,i) = cat(3,imoverlay(imgCH{i},maskCH{i},[cRED(i),cGREEN(i),cBLUE(i)]/255),(alphaCH{i}+maskCH{i}));
    chromBW(:,:,:,i) = cat(3,imoverlay(imgCH{i},maskCH{i},backgroundRGB/255),alphaCH{i});
    achrom(:,:,:,i) = cat(3,imoverlay(imgACH{i},maskACH{i},backgroundRGB/255),alphaACH{i});
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
    row_extra = size(circle_import,1) - 300;
    column_extra = size(circle_import,2) - 300;
    row_cut_start = round(row_extra/2);
    row_cut_end = fix(row_extra/2);
    column_cut_start = round(column_extra/2);
    column_cut_end = fix(column_extra/2);
    final = circle_import((1+row_cut_start):end-row_cut_end,(column_cut_start+1):end-column_cut_end,:);
    final(:,:,4) = alphaCircle;
    colorcircles(:,:,:,i) = final;
end


%% Save the stimuli as mat files
save('chrom.mat', 'chrom')
save('chromBW.mat', 'chromBW')
save('achrom.mat', 'achrom')
save('colorcircles.mat','colorcircles')


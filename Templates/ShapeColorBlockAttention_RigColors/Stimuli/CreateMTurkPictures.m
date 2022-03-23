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
cRED = [235,141,202,122,141,86,86,50,157,95,227,136,186,113];
cGREEN = [139,84,166,102,186,114,188,115,163,102,133,82,166,102];
cBLUE = [167,97,90,52,123,72,205,119,254,149,240,139,187,109];
backgroundRGB = [150, 132, 153];


%% Create Colored Images
background = cat(3,uint8(zeros(size(alphaCircle))+backgroundRGB(1)),uint8(zeros(size(alphaCircle))+backgroundRGB(2)),uint8(zeros(size(alphaCircle))+backgroundRGB(3)));

for i = 1:imageNumbers
    

    chrom(:,:,:,i) = imoverlay(imoverlay(imgCH{i},maskCH{i},[cRED(i),cGREEN(i),cBLUE(i)]/255),abs(double(alphaCH{i}+maskCH{i})-double(repmat(255,size(alphaCH{i})))),backgroundRGB/255);
    imshow(chrom(:,:,:,i))
    exportgraphics(gca,[num2str(i) 'chromatic.png'])
    chromBW(:,:,:,i) = imoverlay(imoverlay(imgCH{i},maskCH{i},backgroundRGB/255),abs(double(alphaCH{i}+maskCH{i})-double(repmat(255,size(alphaCH{i})))),backgroundRGB/255);
    imshow(chromBW(:,:,:,i))
    exportgraphics(gca,[num2str(i) 'chromaticBW.png'])
    achrom(:,:,:,i) = imoverlay(imoverlay(imgACH{i},maskACH{i},backgroundRGB/255),abs(double(alphaACH{i}+maskACH{i})-double(repmat(255,size(alphaACH{i})))),backgroundRGB/255);
    imshow(achrom(:,:,:,i))
    exportgraphics(gca,[num2str(i) 'achromatic.png'])
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


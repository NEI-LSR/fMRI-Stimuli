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
cRED = [173    99   144    83    91    55    50    25   116    69   168    96   133    78];
cGREEN = [90    53   117    68   133    76   131    76   103    63    78    45   112    66];
cBLUE = [140    82    57    30    95    57   176   102   225   130   210   121   159    92];
backgroundRGB = [103    87   125];


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


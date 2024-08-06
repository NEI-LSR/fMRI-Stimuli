%% Set Up Directory Structure
clear;
curDir = pwd; %also circle directory
CHdir = fullfile(curDir,'chromatic');

%% Prepare images
imageNumbers = 12; % not using gray stimuli
for i = 1:imageNumbers
    [imgCH{i},~,alphaCH{i}] = imread(fullfile(CHdir, [num2str(i) '.png']));
    [~,~,maskCH{i}] = imread(fullfile(CHdir, [num2str(i) '_mask.png']));
end

%% Color Params
cRED = [94, 27, 72, 21, 31, 15, 13, 7, 29, 14, 78, 24];
cGREEN = [33, 12, 51, 16, 64, 22, 64, 22, 49, 18, 32, 14];
cBLUE = [56, 17, 14, 5, 26, 9, 95, 27, 165, 45, 143, 39];
cREDswap = [13, 7, 29, 14, 78, 24, 94, 27, 72, 21, 31, 15]; % incongruent stimuli, swap the last six and the first six
cGREENswap = [64, 22, 49, 18, 32, 14, 33, 12, 51, 16, 64, 22]; % incongruent stimuli
cBLUEswap = [95, 27, 165, 45, 143, 39, 56, 17, 14, 5, 26, 9]; % incongruent stimuli
backgroundRGB = [31 29 47];


%% Create Colored Images
for i = 1:imageNumbers
    chrom(:,:,:,i) = cat(3,imoverlay(imgCH{i},maskCH{i},[cRED(i),cGREEN(i),cBLUE(i)]/255),(alphaCH{i}+maskCH{i}));
    inchrom(:,:,:,i) = cat(3,imoverlay(imgCH{i},maskCH{i},[cREDswap(i),cGREENswap(i),cBLUEswap(i)]/255),(alphaCH{i}+maskCH{i})); % incongruent stimuli
end


%% Save the stimuli as mat files
save('chrom.mat', 'chrom')
save('inchrom.mat', 'inchrom')



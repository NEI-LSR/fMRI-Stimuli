function scramblevids(vidDir,varargin)
% Batch modify all images in folder to scrambled
% requires mmread due to encoding of videos originally used
% Inputs:
%   vidDir: Folder with videos
%   varargin{0}: Number of squares in each direction to scramble image
% 
% Outputs:
%   Saves converted video files to new directory in same directory as
%   vidDir appended with _scrambled

if vidDir(end) == '\'
    vidDir = vidDir(1:end-1)
end

if length(varargin) > 0
    scrambleNum = varargin{0}; % How many to scrable
else
    scrambleNum = 15;
end

% Make destination directory
[parentDir, vidDirName,~] = fileparts(vidDir);

dirName = [vidDirName '_scrambled'];
if ~isdir([parentDir '\' dirName])
    mkdir([parentDir '\' dirName]);
end

data = dir([vidDir '\*.avi']);
n={};
for i=1:length(data)
    n{end+1,1}=data(i).name;
end
data=n;

for j = 1:length(data)
    video = mmread(fullfile(vidDir,data{j}));
    disp(['Converting ' data{j}(1:end-4)])
    v = VideoWriter(fullfile(parentDir, dirName, data{j}(1:end-4)),'Uncompressed AVI');
    v.FrameRate = video.rate;
    open(v);
    permuteParameter = randperm((scrambleNum)^2); % Get random indexing parameter
    for k=1:length(video.frames)
        frameRGB = video.frames(k).cdata;
        frameScrambled = imageScramble_hb_sd(frameRGB,scrambleNum,permuteParameter,false); % Make grayscale
        writeVideo(v,frameScrambled); % Write video
    end
end


end



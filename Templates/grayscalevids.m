function grayscalevids(vidDir)
% Batch modify all images in folder to grayscale
% requires mmread due to encoding of videos originally used
% Inputs:
%   vidDir: Folder with videos
% 
% Outputs:
%   Saves converted video files to new directory in same directory as
%   vidDir appended with _BW

% Make destination directory

if vidDir(end) == '\'
    vidDir = vidDir(1:end-1)
end
[parentDir, vidDirName,~] = fileparts(vidDir);

dirName = [vidDirName '_BW'];
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
    for k=1:length(video.frames)
        frameRGB = video.frames(k).cdata;
        frameGrayscale = rgb2gray(frameRGB); % Make grayscale
        writeVideo(v,frameGrayscale); % Write video
    end
end


end



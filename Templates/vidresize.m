function vidresize(vidDir,height,width)
% Batch modify all videos in folder to be resized
% requires mmread due to encoding of videos originally used
% Inputs:
%   vidDir: Folder with videos
%   heigh of new video
%   witdh of new video
% Outputs:
%   Saves converted video files to new directory in same directory as
%   vidDir appended with _scrambled

if vidDir(end) == '\'
    vidDir = vidDir(1:end-1)
end

% Make destination directory
[parentDir, vidDirName,~] = fileparts(vidDir);

dirName = [vidDirName '_resized'];
if ~isdir([parentDir '\' dirName])
    mkdir([parentDir '\' dirName]);
end

data = dir([vidDir '\*.mov']);
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
        frameResized = imresize(frameRGB, [height width]);
        writeVideo(v,frameResized); % Write video
    end
end


end

function vidModDKL(vidDir, conType, mon, varargin)
% Batch modify all images in folder to some other angle in DKL space
%   requires mmread due to encoding of videos originally used:
%   http://www.mathworks.com/matlabcentral/fileexchange/8028-mmread
%
% Inputs:
%   vidDir = Folder with videos
%   conType = 1 (rotate colors), 2 (convert to grayscale)
%   mon = xyY to DKL lookup tables and curves for monitor
%   angle = angle at which to rotate colors
% Optional inputs:
%   'ANGLE' = type must be 2 and subsequent input must be an int of desired angle of rotation
%   'SubDirs' = convert all videos in subdirectories as well
%
% Outputs:
%   Saves converted video files to new directory in same directory as vidDir appended with _DKL[angle]
%

% debug
% vidDir='DyLoc_nat\stimuli\Objects';
% vidDir='DyLoc_nat\stimuli\Faces';
% mon='MIT_Oct15_2013';
% conType=2;
loadmon(mon) %loads the look-up tables and conversion matrices
global REDLUT
global GREENLUT
global BLUELUT

% get desired angle if it exists
angle = 180;
subDirs = 0;
resFile=0;
if (~isempty(varargin)) && conType == 2
    for c=1:length(varargin)
        switch varargin{c}
            case {'ANGLE'}
                angle=varargin{c+1};
            case {'SubDirs'}
                subDirs=1;
            case {'ResFile'}
                resFile=1;
        end
    end
end


% Make destination directory
[parentDir, vidDirName, ~] = fileparts(vidDir);
switch conType
    case 0
        dirName = [vidDirName '_DKLorig'];
    case 1
        dirName = [vidDirName '_DKL' num2str(angle)];
    case 2
        dirName = [vidDirName '_BW'];
end

mkdir(dirName)

% Load videos loop
data = dir([vidDir '\*.avi']);
n={};for i=1:length(data), n{end+1,1}=data(i).name; end; data=n; clear n; % get vid names

if resFile==1
    res = csvread([vidDir '\res.csv']);
end

for j=1:length(data)
    video = mmread(fullfile(vidDir,data{j})); % read whole movie
    % set output format and framerate
    disp(['Converting ' data{j}(1:end-4)])
    v = VideoWriter(fullfile(parentDir, dirName, data{j}(1:end-4)),'Uncompressed AVI');
    v.FrameRate = video.rate;
    %         v.Quality = 100;
    open(v);
    for k=1:length(video.frames)
        frameRGB = video.frames(k).cdata;
        if resFile==1
            for imRange = res(:,1)
                if res(imRange,1) <= k && k <= res(imRange,2)
                    height=res(imRange,4);
                    width=res(imRange,3);
                end
            end
        else
            height = 540;
            width = 720;
        end
        frameRGB = imresize(frameRGB,[height,width]);
        % convert to RGB triplet array
        frameRGB = im2double(frameRGB);
%         if conType == 2
%             frameConverted = rotateRGB(frameRGB, mon, conType);
%         else
            frameConverted = rotateRGB(frameRGB, mon, conType);
%         end


%Plots frames side by side for comparison
%         if sum(sum(sum(frameConverted == frameRGB))) > 0
% sum(sum(sum(frameConverted == frameRGB)))
%             subplot(1, 2, 1)
%             image(frameRGB)
%             subplot(1, 2, 2)
%             image(frameConverted)
%             pause
%         end

        writeVideo(v,frameConverted);
    end
    close(v);
end

end


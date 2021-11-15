function [fixGridTex, retinoTex, motionTex, rawStim] = MakePTBtextures(params, window)
    
    if ~ispc && ~ismac
        progressBar = waitbar(0, sprintf(' '));
        wax = findobj(progressBar, 'type','axes');
        tax = get(wax,'title');
        set(tax,'fontsize',24)
        waitbar(0.1, progressBar, sprintf('Loading fixation grid texture...\n'));
    else
        progressBar = waitbar(0.1, sprintf('Loading fixation grid texture...\n'));
    end
    
    % Fixation Grid Texture
    
    load([params.directory.stimuli '/' 'fixGrid.mat'], 'fixGrid');
    fixGridTex = Screen('MakeTexture', window, fixGrid);
    
    % Loading stimulus files
    waitbar(0.2, progressBar, sprintf('Loading Shape-Color stimulus textures...\n'));

    load([params.directory.stimuli '/' 'achrom.mat'], 'achrom');
    load([params.directory.stimuli '/' 'chrom.mat'], 'chrom');
    load([params.directory.stimuli '/' 'chromBW.mat'], 'chromBW');
    load([params.directory.stimuli '/' 'colorcircles.mat'], 'colorcircles');
    stimsize = size(chrom(:,:,1,1));
    gray = uint8(params.display.grayBackground*255); % Need to convert to uint8 to keep consistent with the rest of the stimuli
    grayTex = cat(3,repmat(gray(1),stimsize(1)),repmat(gray(2),stimsize(1)),repmat(gray(3),stimsize(1)));
    
    % Creating the movie 4D array
    
    waitbar(0.3, progressBar);
    
    retinoMovie = cat(4,grayTex,chromBW,chrom,achrom,colorcircles);
    
    baseTex = NaN(size(retinoMovie, ndims(retinoMovie)))
    
    for i = 1:size(retinoMovie,ndims(retinoMovie))
        baseTex(i) = Screen('MakeTexture', window, retinoMovie(:, :, :, i));
    end
    
    % Expanding index of textures
    waitbar(0.5, progressBar, sprintf('Expanding Meridian Mapper Textures...\n'));
    
    retinoTex = NaN(params.display.fps*params.run.exactDuration, 1);
    
    framesPerBlock = params.run.blocklength*params.run.TR*params.display.fps;
    framesPerStim = params.run.TR*params.display.fps;
    for i = 1:length(params.run.blockorder)
        switch params.run.blockorder(i)
            case 0 % gray
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                retinoTex(frames) = repmat(baseTex(1),1,framesPerBlock);
            case 1 % Chromatic Shapes Uncolored
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(params.run.blocklength);
                chromBWTex = baseTex(2:15)
                retinoTex(frames) = repelem(chromBWTex(order),framesPerStim);
            case 2 % Chromatic Shapes Colored
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(params.run.blocklength);
                chromTex = baseTex(16:29)
                retinoTex(frames) = repelem(chromTex(order),framesPerStim);
            case 3 % Achromatic Shapes
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(params.run.blocklength);
                AchromTex = baseTex(30:43)
                retinoTex(frames) = repelem(AchromTex(order),framesPerStim);
            case 4 % Colored Circles
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(params.run.blocklength);
                circTex = baseTex(44:57)
                retinoTex(frames) = repelem(circTex(order),framesPerStim);
        end
    end
    
    waitbar(1, progressBar, sprintf('Loading complete.\n'));
    close(progressBar);
%     
%     
%     
%     retinoMovie = repmat(grayTex,1,1,1,length(isStimOn));
%     stimOrder = []
%     for i = 1:length(params.run.blockorder)
%         switch params.run.blockorder(i)
%             case 0 % gray
%                 stimOrder = cat(2,stimOrder,zeros(1,14));
%                 % Texture should already be gray
%             case 1 % Chromatic Shapes Uncolored
%                 order = randperm(params.run.blocklength);
%                 stimOrder = cat(2,stimOrder,order);
%                 frames = (1:14)+(i-1)*14;
%                 retinoMovie(:,:,:,frames) = chromBW(:,:,:,order);
%             case 2 % Chromatic Shapes Colored
%                 order = randperm(params.run.blocklength);
%                 stimOrder = cat(2,stimOrder,order);
%                 frames = (1:14)+(i-1)*14;
%                 retinoMovie(:,:,:,frames) = chrom(:,:,:,order);
%             case 3 % Achromatic Shapes
%                 order = randperm(params.run.blocklength);
%                 stimOrder = cat(2,stimOrder,order);
%                 frames = (1:14)+(i-1)*14;
%                 retinoMovie(:,:,:,frames) = achrom(:,:,:,order);
%             case 4 % Colored Circles
%                 order = randperm(params.run.blocklength);
%                 stimOrder = cat(2,stimOrder,order);
%                 frames = (1:14)+(i-1)*14;
%                 retinoMovie(:,:,:,frames) = colorcircles(:,:,:,order);
%         end
%     end
%     waitbar(0.3, progressBar);
%     % retinoMovie(1, 1, 4, :) = 0;
%     % Applying aperture values to movie transparency layer (and creating the texture frames)
%     waitbar(0.5, progressBar, sprintf('Creating retinotopy stimulus bar apertures...\n'));
%     for idx = 1:length(isStimOn)
%         if isStimOn(idx)
%             % retinoMovie(:, :, 4, idx) = mask(:, :, idx);
%             retinoTex(idx) = Screen('MakeTexture', window, retinoMovie(:, :, :, idx));
%             waitbar(0.5 + (idx/length(isStimOn))/2, progressBar);
%         end
%     end
%     
%     % Adjusting the number of frames to the desired playback speed (60Hz -> 15Hz)
%     playbackFps = size(retinoMovie,ndims(retinoMovie)) / params.run.exactDuration;
%     retinoTex    = repelem(retinoTex, params.display.fps/playbackFps);
%     waitbar(1, progressBar, sprintf('Loading complete.\n'));
%     close(progressBar);
%     motionTex = retinoTex;
%     rawStim = retinoMovie;
end

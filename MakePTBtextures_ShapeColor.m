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
    
    % Loading stimulus files
    load([params.directory.stimuli '/' 'isStimOn.mat'], 'isStimOn');
    isStimOn = logical(ones(1,280));
    load([params.directory.stimuli '/' 'achrom.mat'], 'achrom');
    load([params.directory.stimuli '/' 'chrom.mat'], 'chrom');
    load([params.directory.stimuli '/' 'chromBW.mat'], 'chromBW');
    load([params.directory.stimuli '/' 'colorcircles.mat'], 'colorcircles');
    load([params.directory.stimuli '/' 'fixGrid.mat'], 'fixGrid');
    fixGridTex = Screen('MakeTexture', window, fixGrid);
    stimsize = size(chrom(:,:,1,1));
    gray = uint8(params.display.grayBackground*255); % Need to convert to uint8 to keep consistent with the rest of the stimuli
    grayTex = cat(3,repmat(gray(1),stimsize(1)),repmat(gray(2),stimsize(1)),repmat(gray(3),stimsize(1)));
    
    % Creating the movie 4D array
    
    retinoTex = NaN(length(isStimOn), 1);
    waitbar(0.2, progressBar, sprintf('Loading Shape-Color stimulus textures...\n'));
    retinoMovie = repmat(grayTex,1,1,1,length(isStimOn));
    stimOrder = []
    for i = 1:length(params.run.blockorder)
        switch params.run.blockorder(i)
            case 0 % gray
                stimOrder = cat(2,stimOrder,zeros(1,14));
                % Texture should already be gray
            case 1 % Chromatic Shapes Uncolored
                order = randperm(params.run.blocklength);
                stimOrder = cat(2,stimOrder,order);
                frames = (1:14)+(i-1)*14;
                retinoMovie(:,:,:,frames) = chromBW(:,:,:,order);
            case 2 % Chromatic Shapes Colored
                order = randperm(params.run.blocklength);
                stimOrder = cat(2,stimOrder,order);
                frames = (1:14)+(i-1)*14;
                retinoMovie(:,:,:,frames) = chrom(:,:,:,order);
            case 3 % Achromatic Shapes
                order = randperm(params.run.blocklength);
                stimOrder = cat(2,stimOrder,order);
                frames = (1:14)+(i-1)*14;
                retinoMovie(:,:,:,frames) = achrom(:,:,:,order);
            case 4 % Colored Circles
                order = randperm(params.run.blocklength);
                stimOrder = cat(2,stimOrder,order);
                frames = (1:14)+(i-1)*14;
                retinoMovie(:,:,:,frames) = colorcircles(:,:,:,order);
        end
    end
    waitbar(0.3, progressBar);
    % retinoMovie(1, 1, 4, :) = 0;
    % Applying aperture values to movie transparency layer (and creating the texture frames)
    waitbar(0.5, progressBar, sprintf('Creating retinotopy stimulus bar apertures...\n'));
    for idx = 1:length(isStimOn)
        if isStimOn(idx)
            % retinoMovie(:, :, 4, idx) = mask(:, :, idx);
            retinoTex(idx) = Screen('MakeTexture', window, retinoMovie(:, :, :, idx));
            waitbar(0.5 + (idx/length(isStimOn))/2, progressBar);
        end
    end
    
    % Adjusting the number of frames to the desired playback speed (60Hz -> 15Hz)
    playbackFps = size(retinoMovie,ndims(retinoMovie)) / params.run.exactDuration;
    retinoTex    = repelem(retinoTex, params.display.fps/playbackFps);
    waitbar(1, progressBar, sprintf('Loading complete.\n'));
    close(progressBar);
    motionTex = retinoTex;
    rawStim = retinoMovie;
end

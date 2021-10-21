function [fixGridTex, retinoTex] = MakePTBtextures(params, window)
    
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
    isStimOn = logical(ones(1,2304));
    load([params.directory.stimuli '/' '1hdartboard.mat'], 'image');
    horz1 = uint8(image*255);
    load([params.directory.stimuli '/' '2hdartboard.mat'], 'image');
    horz2 = uint8(image*255);
    load([params.directory.stimuli '/' '1vdartboard.mat'], 'image');
    vert1 = uint8(image*255);
    load([params.directory.stimuli '/' '2vdartboard.mat'], 'image');
    vert2 = uint8(image*255);
    load([params.directory.stimuli '/' 'fixGrid.mat'], 'fixGrid');
    fixGridTex = Screen('MakeTexture', window, fixGrid);
    stimsize = size(vert2(:,:,1));
    gray = uint8(params.display.grayBackground*255); % Need to convert to uint8 to keep consistent with the rest of the stimuli
    grayTex = cat(3,repmat(gray(1),stimsize(1),stimsize(2)),repmat(gray(2),stimsize(1),stimsize(2)),repmat(gray(3),stimsize(1),stimsize(2)));
    
    % Creating the movie 4D array
    
    retinoTex = NaN(length(isStimOn), 1);
    waitbar(0.2, progressBar, sprintf('Loading Meridian Mapper stimulus textures...\n'));
    retinoMovie = repmat(grayTex,1,1,1,length(isStimOn));
    horz_both = cat(4,horz1, horz2);
    horz_block = repmat(horz_both, [1,1,1,72]);
    vert_both = cat(4,vert1, vert2);
    vert_block = repmat(vert_both, [1,1,1,72]);
    gray_block = repmat(grayTex, [1,1,1,144]);
    
    %stimOrder = []
    for i = 1:length(params.run.blockorder)
        switch params.run.blockorder(i)
            case 0 % gray
                frames = (1:144)+(i-1)*144;
                retinoMovie(:,:,:,frames) = gray_block;
            case 1 % Horizontal
                frames = (1:144)+(i-1)*144;
                retinoMovie(:,:,:,frames) = horz_block;
            case 2 % Vertical
                frames = (1:144)+(i-1)*144;
                retinoMovie(:,:,:,frames) = vert_block;
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
    playbackFps = size(retinoMovie,ndims(retinoMovie)) / (params.run.exactDuration);
    retinoTex    = repelem(retinoTex, params.display.fps/playbackFps); 
    waitbar(1, progressBar, sprintf('Loading complete.\n'));
    close(progressBar);
  
end

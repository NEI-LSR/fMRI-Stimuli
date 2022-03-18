function PlotOverlays_ShapeColor(subject, run)
    % Shape Color Paradigm 2.2
    % Stuart J. Duffield November 2021
    % Displays the stimuli from the Monkey Turk experiments in blocks.
    % Blocks include gray, colored chromatic shapes, black and white chromatic
    % shapes, achromatic shapes, and colored blobs.

    
    % Initialize parameters
    KbName('UnifyKeyNames');
    % Initialize save paths for eyetracking, other data:
    curdir = pwd; % Current Directory
    
    stimDir = [curdir '/Stimuli']; % Change this if you move the location of the stimuli:


    dataSaveFile = ['Data/' subject '_' num2str(run) '_Data.mat']; % File to save both run data and eye data

    load(dataSaveFile);
    
    screenShots = ['Data/' subject '_' num2str(run) '_Images.mat'];

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 2; 

    % Refresh rate of monitors:
    fps = 30;
    jitterFrames = fps/2;
    ifi = 1/fps;
    
    % Other Timing Data:
    TR = 3; % TR length
    stimPerTR = 1; % 1 stimulus every TR
    
    % Gray of the background:
    gray = [31 29 47]; 

    % Load in block orders:
    blocklength = 14; % Block length is in TRs. 
    
    % Exact Duration
    runDur = length(stimulus_order)*TR;

    exactDur = 840; % Specify this to check
    
    if runDur ~= exactDur % Ya gotta check or else you waste your scan time
        error('Run duration calculated from run parameters does not match hardcoded run duration length.')
    end
    

    % Load Textures:
    load([stimDir '/' 'achrom.mat'], 'achrom'); % Achromatic Shapes
    load([stimDir '/' 'chrom.mat'], 'chrom'); % Chromatic Shapes
    load([stimDir '/' 'chromBW.mat'], 'chromBW'); % Chromatic Shapes Black and White
    load([stimDir '/' 'colorcircles.mat'], 'colorcircles'); % Colored Circles
    stimsize = size(chrom(:,:,1,1)); % What size is the simulus? In pixels
    grayTex = cat(3,repmat(gray(1),stimsize(1)),repmat(gray(2),stimsize(1)),repmat(gray(3),stimsize(1)),repmat(255,stimsize(1))); % Greates a gray texture the size of the stimulus. 
    % I do this because the way the code works right now is that it
    % requires a texture to be displayed at any given frame. Not great, but
    % allows the code to be easily modifiable, and the gray texture only
    % takes up one texture in memory.
    
    % Initialize Screens
    Screen('Preference', 'SkipSyncTests', 1); 
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    
    
    [expWindow, expRect] = Screen('OpenWindow', expscreen, gray); % Open experimenter window
    %[viewWindow, viewRect] = Screen('OpenWindow', viewscreen, gray); % Open viewing window (for subject)
    %Screen('BlendFunction', viewWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    Screen('BlendFunction', expWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    
    %[xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
    [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen
    
    pixPerAngle = 40; % Number of pixels per degree of visual angle
    stimPix = 6*pixPerAngle; % How large the stimulus rectangle will be
    jitterPix = 1*pixPerAngle; % How large the jitter will be
    fixPix = 1*pixPerAngle; % How large the fixation will be
    
    
    fixCrossDimPix = 10; % Fixation cross arm length
    lineWidthPix = 2; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    
    % Make base rectangle and centered rectangle for stimulus presentation
    baseRect = [0 0 stimPix stimPix]; % Size of the texture rect
    
    % Make base rectangle for fixation circle
    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
    
    % Load Fixation Grid and Create Texture:
    load([stimDir '/' 'fixGrid.mat'], 'fixGrid'); % Loads the .mat file with the fixation grid texture
    fixGridTex = Screen('MakeTexture', expWindow, fixGrid); % Creates the fixation grid as a texture
    
    % Create Shape-Color Textures 
    Movie = cat(4,grayTex,chromBW,chrom,achrom,colorcircles); % Array of all possible stimulus images:
    % Gray (1), Chromatic Black and White (2:15), Chromatic (16:29),
    % Achromatic (30:43), Colored Circles (44:57)
    % Stuart's note--I need to figure out which index of each texture
    % corresponds to what
    
    baseTex = NaN(size(Movie, ndims(Movie)),1); % Creates a vector of NaNs that match the length of each stimulus
    
    for i = 1:size(Movie,ndims(Movie))
        baseTex(i) = Screen('MakeTexture', expWindow, Movie(:, :, :, i)); % Initializes textures--each index corresponds to a texture
    end
    
    texture = NaN(fps*exactDur, 1); % Initialize vector of indices
        
    framesPerBlock = blocklength*TR*fps*stimPerTR; % Frames per block
    framesPerStim = TR*fps*stimPerTR; % Frames 
    
    stimulus_order(stimulus_order==0)=13;
    diff = max(stimulus_order)-max(baseTex);
    stimulus_order=stimulus_order-diff;
    texture = repelem(stimulus_order,6);
    
    [~,chromBWInds] = ismember(texture, baseTex(2:15));
    chromBWInds=find(chromBWInds>0);
    [~,chromInds] = ismember(texture, baseTex(16:29));
    chromInds=find(chromInds>0);
    [~,achromInds] = ismember(texture, baseTex(30:43));
    achromInds=find(achromInds>0);
    [~,circInds] = ismember(texture, baseTex(44:57));
    circInds=find(circInds>0);


    jitterX = jitterX(1:15:end);
    jitterY = jitterY(1:15:end);
    % Initialize randoms

    Priority(2) % topPriorityLevel?

    quitNow = false;
    
    
    % Begin actual stimulus presentation
    try
       Screen('Flip', expWindow);
        %Screen('Flip', viewWindow);
        
        
        for i = 1:length(chromBWInds)
            expStimRect = CenterRectOnPointd(baseRect, round(xCenterExp+jitterX(chromBWInds(i))), round(yCenterExp+jitterY(chromBWInds(i))));
            Screen('DrawTexture', expWindow, texture(chromBWInds(i)),[],expStimRect);  
            
        end
        Screen('Flip', expWindow, 5);
        chromBWImage = Screen('GetImage',expWindow);

        for i = 1:length(chromInds)
            expStimRect = CenterRectOnPointd(baseRect, round(xCenterExp+jitterX(chromInds(i))), round(yCenterExp+jitterY(chromInds(i))));
            Screen('DrawTexture', expWindow, texture(chromInds(i)),[],expStimRect);  
            
        end
        Screen('Flip', expWindow, 100);
        chromImage = Screen('GetImage',expWindow);

        for i = 1:length(achromInds)
            expStimRect = CenterRectOnPointd(baseRect, round(xCenterExp+jitterX(achromInds(i))), round(yCenterExp+jitterY(achromInds(i))));
            Screen('DrawTexture', expWindow, texture(achromInds(i)),[],expStimRect);  
            
        end
        Screen('Flip', expWindow, 200);
        achromImage = Screen('GetImage',expWindow);

        for i = 1:length(circInds)
            expStimRect = CenterRectOnPointd(baseRect, round(xCenterExp+jitterX(circInds(i))), round(yCenterExp+jitterY(circInds(i))));
            Screen('DrawTexture', expWindow, texture(circInds(i)),[],expStimRect);  
        end
        Screen('Flip', expWindow, 300);
        circImage = Screen('GetImage',expWindow);

    catch error
        rethrow(error)
    end % End of stim presentation
    

    sca;

    save(screenShots,"chromBWImage","circImage","achromImage","chromImage");
    imwrite(chromBWImage, ['Data/' subject '_' num2str(run) '_chromBWplot.png']);
    imwrite(circImage, ['Data/' subject '_' num2str(run) '_circplot.png']);
    imwrite(achromImage, ['Data/' subject '_' num2str(run) '_achromplot.png']);
    imwrite(chromImage, ['Data/' subject '_' num2str(run) '_chromplot.png']);

end
        
                




        


    
    
   






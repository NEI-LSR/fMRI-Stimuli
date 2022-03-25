function Replay_ShapeColor(subject, run)
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
    movSaveFile = ['Data/' subject '_' num2str(run) '_Movie.mov']; % Create Movie Filename

    load(dataSaveFile);

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 0; 
    viewscreen = 2;

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
    
    pixPerAngle = 100; % Number of pixels per degree of visual angle
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
    stimulus_order=stimulus_order-1;
    texture = repelem(stimulus_order,framesPerStim);

    % Initialize randoms

    Priority(2) % topPriorityLevel?

    quitNow = false;

    
    % Begin actual stimulus presentation
    try
        movie = Screen('CreateMovie', expWindow, movSaveFile, [],[], 10); % Initialize Movie
        Screen('DrawTexture', expWindow, fixGridTex);
        Screen('Flip', expWindow);
        %Screen('Flip', viewWindow);
        
        % Wait for TTL
        while true
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(KbName('space'))
                break;
            end
        end
        
        flips = ifi:ifi:exactDur;
        flips = flips + GetSecs;
        
        for frameIdx = 1:fps*exactDur
            % Check keys
            [keyIsDown,secs, keyCode] = KbCheck;
                
            
            % Process Keys
            if keyCode(KbName('r')) % Recenter
                xOffset = xOffset + eyePosition(frameIdx,1)-xCenterExp;
                yOffset = yOffset + eyePosition(frameIdx,2)-yCenterExp;
            elseif keyCode(KbName('j')) % Juice
                juiceOn = true;
            elseif keyCode(KbName('w')) && fixPix > pixPerAngle/2 % Increase fixation circle
                fixPix = fixPix - pixPerAngle/2; % Shrink fixPix by half a degree of visual angle
                baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
            elseif keyCode(KbName('s')) && fixPix < pixPerAngle*10
                fixPix = fixPix + pixPerAngle/2; % Increase fixPix by half a degree of visual angle
                baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
            elseif keyCode(KbName('p'))
                quitNow = true;
            end
            
            if rem(frameIdx,jitterFrames) == 1

            
                % Create rectangles for stim draw
                %viewStimRect = CenterRectOnPointd(baseRect, round(xCenter+jitterX(frameIdx)), round(yCenter+jitterY(frameIdx)));
                expStimRect = CenterRectOnPointd(baseRect, round(xCenterExp+jitterX(frameIdx)), round(yCenterExp+jitterY(frameIdx)));
            end
            
            % Draw Stimulus on Framebuffer
            %Screen('DrawTexture', viewWindow, texture(frameIdx),[],viewStimRect);
            Screen('DrawTexture', expWindow, texture(frameIdx),[],expStimRect);  
            %Screen('DrawTexture', viewWindow, texture(frameIdx)); % Needs to be sized and have jitter
            %Screen('DrawTexture', expWindow, texture(frameIdx)); % Needs to be sized and have jitter
            
            % Draw Fixation Cross on Framebuffer
            %Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
            
            % Draw fixation window on framebuffer
            Screen('FrameOval', expWindow, [255 255 255], fixRect);

            % Draw eyetrace on framebuffer
            Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            
            % Add this frame to the movie
            if rem(frameIdx,3)==1
                Screen('AddFrameToMovie',expWindow,[],[],movie);
            end

            % Flip
            %[timestamp] = Screen('Flip', viewWindow, flips(frameIdx));
            [timestamp2] = Screen('Flip', expWindow, flips(frameIdx));
                        

            if quitNow == true
                Screen('FinalizeMovie', movie);
                sca
                break;
            end
            
        end
        
        
    catch error
        rethrow(error)
    end % End of stim presentation
    
    if quitNow == false
        Screen('FinalizeMovie', movie);
    end
    sca;

        
end
        
                




        


    
    
   






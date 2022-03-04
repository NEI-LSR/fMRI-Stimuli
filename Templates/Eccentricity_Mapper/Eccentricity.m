function Eccentricity(subject, counterbalance_indx, run)
    % Eccentricity 1.0
    % Stuart J. Duffield January 2022
    % Displays dartboard cicles and rings to map eccentricity.
    

    % Initialize DAQ
    DAQ('Debug',false);
    DAQ('Init');
    xGain = 400;
    yGain = 400;
    xOffset = 0;
    yOffset = 0;
    xChannel = 2;
    yChannel = 3; % DAQ indexes starting at 1, so different than fnDAQ
    ttlChannel = 8;
    rewardDur = 0.08; % seconds
    rewardWait = 5; % seconds
    rewardPerf = .90; % 90% fixation to get reward
    
    
    
    % Initialize parameters
    KbName('UnifyKeyNames');
    % Initialize save paths for eyetracking, other data:
    curdir = pwd; % Current Directory
    
    stimDir = [curdir '/Stimuli']; % Change this if you move the location of the stimuli:

    if ~isfolder('Data') % Switch this to isfolder if matlab 2017 or later
        mkdir('Data');
    end

    runExpTime = datestr(now); % Get the time the run occured at.

    dataSaveFile = ['Data/' subject '_' num2str(run) '_Data.mat']; % File to save both run data and eye data
    movSaveFile = ['Data/' subject '_' num2str(run) '_Movie.mov']; % Create Movie Filename

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 1; 
    viewscreen = 2;

    % Refresh rate of monitors:
    fps = 30;
    jitterFrames = fps/2;
    ifi = 1/fps;
    
    % Other Timing Data:
    TR = 3; % TR length
    stimLength = 0.5; % How long each stimulus is on (checkerboard 1 or checkerboard 2
    
    % Gray of the background:
    gray = [128 128 128]; 

    % Load in block orders:
    blockorders = csvread('block_design.csv'); % This is produced from the counterbalance script @kurt braunlich wrote for me
    blockorder = (blockorders(counterbalance_indx,:)); 
    blocklength = 10; % Block length is in TRs. 
    
    % Exact Duration
    runDur = TR*blocklength*length(blockorder); % You better pray this is correct
    exactDur = 360; % Specify this to check
    
    if runDur ~= exactDur % Ya gotta check or else you waste your scan time
        error('Run duration calculated from run parameters does not match hardcoded run duration length.')
    end
    

    % Load Textures:
    % This should generally read as Gray, BW_Foveal, BW_Middle, BW_Peripheral,
    % LM_..., SLM_...
    color_conds = {'BW','LM','S'};
    ecc_conds = {'Foveal','Middle','Peripheral'};
    for i = 1:length(color_conds)
        for j = 1:length(ecc_conds)
            for k = 1:2
                if i == 1 && k == 1 && j == 1
                    img = Tiff([stimDir '/' ecc_conds{j} '_'  color_conds{i} '_' num2str(k) '.tif'], 'r');
                    stimuli_1 = read(img);
                    stimsize = size(stimuli_1); % What size is the simulus? In pixels
                    stimuli = cat(3,repmat(gray(1),stimsize(1),stimsize(2)),repmat(gray(2),stimsize(1),stimsize(2)),repmat(gray(3),stimsize(1),stimsize(2))); % Greates a gray texture the size of the stimulus. 
                    stimuli = cat(4,stimuli,stimuli_1);
                else
                    img = Tiff([stimDir '/' ecc_conds{j} '_'  color_conds{i} '_' num2str(k) '.tif'], 'r');
                    stimuli = cat(4,stimuli,read(img));
                end
            end
        end
    end
    
                
        
        
    
    
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
    [viewWindow, viewRect] = Screen('OpenWindow', viewscreen, gray); % Open viewing window (for subject)
    Screen('BlendFunction', viewWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    Screen('BlendFunction', expWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    
    [xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
    [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen
    
    pixPerAngle = 1080/(atan(28/57)*180/pi); % Number of pixels per degree of visual angle
    stimPix_Width = 1920; % How large the stimulus rectangle will be
    stimPix_Height = 1080;
    fixPix = 1*pixPerAngle; % How large the fixation will be


    fixCrossDimPix = 10; % Fixation cross arm length
    lineWidthPix = 2; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    
    % Make base rectangle and centered rectangle for stimulus presentation
    baseRect = [0 0 stimPix_Width stimPix_Height]; % Size of the texture rect
    
    % Make base rectangle for fixation circle
    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
    viewStimRect = CenterRectOnPointd(baseRect, xCenter, yCenter);
    expStimRect = CenterRectOnPointd(baseRect, xCenterExp, yCenterExp);

    % Create Shape-Color Textures 
    Movie = stimuli; % Array of all possible stimulus images:

    baseTex = NaN(size(Movie, ndims(Movie))); % Creates a vector of NaNs that match the length of each stimulus
    
    for i = 1:size(Movie,ndims(Movie))
        baseTex(i) = Screen('MakeTexture', viewWindow, Movie(:, :, :, i)); % Initializes textures--each index corresponds to a texture
    end
    
    texture = NaN(fps*exactDur, 1); % Initialize vector of indices
        
    framesPerBlock = blocklength*TR*fps; % Frames per block
    framesPerStim = stimLength*fps;
    stimPer=2;
    
    for i = 1:length(blockorder)
        switch blockorder(i)
            case 1 % gray
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(baseTex(1),1,framesPerBlock);
            case 2 % BW Foveal
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(2:3),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
            case 3 % BW Middle
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(4:5),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
            case 4 % BW Peripheral
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(6:7),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
            case 5 % gray
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(baseTex(1),1,framesPerBlock);
            case 6 % LM Foveal
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(8:9),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
            case 7 % LM Middle
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(10:11),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
            case 8 % LM Peripheral
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(12:13),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));            
            case 9 % gray
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(baseTex(1),1,framesPerBlock);
            case 10 % SLM Foveal
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(14:15),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
            case 11 % SLM Middle
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(16:17),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
            case 12 % SLM Peripheral
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(repelem(baseTex(18:19),framesPerStim),1,framesPerBlock/(framesPerStim*stimPer));
        end
    end
    eyePosition = NaN(fps*exactDur,2); % Column 1 xposition, column 2 yposition
    fixation = NaN(fps*exactDur,1); % Fixation tracker
    Priority(2) % topPriorityLevel?
    %Priority(9) % Might need to change for windows
    juiceOn = false; % Logical for juice giving
    juiceDistTime = 0; % When was the last time juice was distributed
    quitNow = false;
    timeSinceLastJuice = GetSecs-juiceDistTime;
    
    % Begin actual stimulus presentation
    try
        movie = Screen('CreateMovie', expWindow, movSaveFile, [],[], 10); % Initialize Movie
        Screen('DrawText', expWindow, 'Ready',xCenterExp,yCenterExp);
        Screen('Flip', expWindow);
        Screen('Flip', viewWindow);
        
        % Wait for TTL
        baselineVoltage = DAQ('GetAnalog',ttlChannel);
        while true
            [keyIsDown,secs, keyCode] = KbCheck;
            ttlVolt = DAQ('GetAnalog',ttlChannel);
            if keyCode(KbName('space'))
                break;
            elseif abs(ttlVolt - baselineVoltage) > 0.4
                break;
            end
        end
        
        flips = ifi:ifi:exactDur;
        flips = flips + GetSecs;
        tic;

        for frameIdx = 1:fps*exactDur
            % Check keys
            [keyIsDown,secs, keyCode] = KbCheck;
                
            
            % Collect eye position
            [eyePosition(frameIdx,1), eyePosition(frameIdx,2)] = eyeTrack(xChannel, yChannel, xGain, yGain, xOffset, yOffset);
            fixation(frameIdx,1) = isInCircle(eyePosition(frameIdx,1),eyePosition(frameIdx,2),fixRect);
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
            

            


            
            % Draw Stimulus on Framebuffer
            Screen('DrawTexture', viewWindow, texture(frameIdx),[],viewStimRect);
            Screen('DrawTexture', expWindow, texture(frameIdx),[],expStimRect);  
            %Screen('DrawTexture', viewWindow, texture(frameIdx)); % Needs to be sized and have jitter
            %Screen('DrawTexture', expWindow, texture(frameIdx)); % Needs to be sized and have jitter
            
            % Draw Fixation Cross on Framebuffer
            Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
            
            % Draw fixation window on framebuffer
            Screen('FrameOval', expWindow, [255 255 255], fixRect);

            % Draw eyetrace on framebuffer
            Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            
            % Draw Time Elapsed and Fixation Percent on framebuffer
            Screen('DrawText',expWindow, ['Time:' num2str(toc) '/' num2str(exactDur)],0,0)
            fixationPerc = mean(fixation(1:frameIdx,1))*100;
            fixationText = ['Fixation:' num2str(fixationPerc)];
            Screen('DrawText',expWindow,fixationText,0,50);

            % Add this frame to the movie
            if rem(frameIdx,3)==1
                Screen('AddFrameToMovie',expWindow,[],[],movie);
            end

            % Flip
            [timestamp] = Screen('Flip', viewWindow, flips(frameIdx));
            [timestamp2] = Screen('Flip', expWindow, flips(frameIdx));
            
            % Juice Reward
            
            if frameIdx > fps*rewardWait
                [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,fps,rewardWait,fixation,juiceDistTime,rewardPerf,rewardDur,timeSinceLastJuice);
            end
            if quitNow == true
                Screen('FinalizeMovie', movie);
                sca;
                break;
            end
            
        end
        
        
    catch error
        rethrow(error)
    end % End of stim presentation
    if quitNow == false
        Screen('FinalizeMovie', movie);
    end
    save(dataSaveFile,'blockorder','eyePosition');
    sca;
    disp(fixationPerc);
    
        
        
    function [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,fps,rewardWait,fixation,juiceDistTime, rewardPerf,rewardDur,timeSinceLastJuice)

        timeSinceLastJuice = GetSecs-juiceDistTime;
        
        if juiceOn == false && timeSinceLastJuice > rewardWait && sum(fixation(frameIdx-fps*rewardWait+1:frameIdx),"all") > rewardPerf*fps*rewardWait
            juiceOn = true;
        end
        if juiceOn == true 
            juiceOn = false;
            DAQ('SetBit',[1 1 1 1]);
            juiceDistTime = GetSecs;
            timeSinceLastJuice = GetSecs-juiceDistTime;
        end
        if timeSinceLastJuice > rewardDur % This won't have the best timing since its linked to the fliprate
            DAQ('SetBit',[0 0 0 0]);
        end
        
end
        
                

    function [xPos, yPos] = eyeTrack(xChannel, yChannel, xGain, yGain, xOffset, yOffset)
        coords = DAQ('GetAnalog',[xChannel yChannel]);
        xPos = (coords(1)*xGain)-xOffset;
        yPos = (coords(2)*yGain)-yOffset;
    end

    function inCircle = isInCircle(xPos, yPos, circle) % circle is a PTB rectangle
        radius = (circle(3) - circle(1)) / 2;
        [xCircleCenter, yCircleCenter] = RectCenter(circle);
        xDiff = xPos-xCircleCenter;
        yDiff = yPos-yCircleCenter;
        dist = hypot(xDiff,yDiff);
        inCircle = radius>dist;
    end


        
end


    
    
   






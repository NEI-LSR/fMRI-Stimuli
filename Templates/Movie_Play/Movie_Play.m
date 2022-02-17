function Movie_Play(subject, run)
    % Play Movie 1.0
    % Stuart J. Duffield January 2022
    % Plays a movie over and over
    
    movieName = 'Growth_noSound_clipped.mp4';

    % Initialize DAQ
    DAQ('Debug',true);
    xGain = 400;
    yGain = 400;
    xOffset = 0;
    yOffset = 0;
    xChannel = 2;
    yChannel = 3; % DAQ indexes starting at 1, so different than fnDAQ
    ttlChannel = 8;
    rewardDur = 0.1; % seconds
    rewardWait = 5; % seconds
    rewardPerf = .90; % 90% fixation to get reward
    
    
    
    % Initialize parameters
    KbName('UnifyKeyNames');
    % Initialize save paths for eyetracking, other data:
    curdir = pwd; % Current Directory
    
    stimDir = [curdir]; % Change this if you move the location of the stimuli:
    movieFile = [stimDir '\' movieName]
    if ~isfile(movieFile)
        error('No movie file')
    end
    
    if ~isfolder('Data') % Switch this to isfolder if matlab 2017 or later
        mkdir('Data');
    end

    runExpTime = datestr(now); % Get the time the run occured at.

    dataSaveFile = ['Data/' subject '_' num2str(run) '_Data.mat']; % File to save both run data and eye data

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 1; 
    viewscreen = 2;


    
    % Other Timing Data:
    TR = 2.5; % TR length
    
    % Gray of the background:
    gray = [128 128 128]; 
    black = [0 0 0];

    
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
    
    pixPerAngle = 40; % Number of pixels per degree of visual angle
    stimPix = 10*pixPerAngle; % How large the stimulus rectangle will be
    fixPix = 10*pixPerAngle; % How large the fixation will be


    fixCrossDimPix = 10; % Fixation cross arm length
    lineWidthPix = 2; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    
    % Make base rectangle and centered rectangle for stimulus presentation
    baseRect = [0 0 1.5*stimPix stimPix]; % Size of the texture rect
    
    % Make base rectangle for fixation circle
    baseFixRect = [0 0 1.5*fixPix fixPix]; % Size of the fixation circle
    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
      viewStimRect = CenterRectOnPointd(baseRect, xCenter, yCenter);
    expStimRect = CenterRectOnPointd(baseRect, xCenterExp, yCenterExp);

    % Load Movie
    [movie duration fps] = Screen('OpenMovie', viewWindow, movieFile)
    ifi = 1/fps;
    exactDur = duration+10;

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
        Screen('PlayMovie',movie,1)
        Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
        %tex = Screen('GetMovieImage', viewWindow, movie);
        %Screen('DrawTexture', viewWindow,tex);
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
        

        frameIdx = 1;
        tic; % start stopwatch
        tex = Screen('GetMovieImage', viewWindow, movie);
        
        while true
            Screen('PlayMovie',movie,1);
            if toc < 10
                Screen('PlayMovie',movie,0);
                Screen('DrawText',expWindow,'True',0,200);
                frameLastBeforeVideo=frameIdx;
            end
            % Check keys
            [keyIsDown,secs, keyCode] = KbCheck;
                
            
            % Collect eye position
            [eyePosition(frameIdx,1), eyePosition(frameIdx,2)] = eyeTrack(xChannel, yChannel, xGain, yGain, xOffset, yOffset);
            fixation(frameIdx,1) = IsInRect(eyePosition(frameIdx,1),eyePosition(frameIdx,2),fixRect);
            fixationPerc = mean(fixation(1:frameIdx,1))*100;
            fixationText = ['Fixation:' num2str(fixationPerc)];
            Screen('DrawText',expWindow,fixationText,0,0);
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
            timeElapsed = toc;

            % Get movie image
            tex = Screen('GetMovieImage', viewWindow, movie);
            if tex<=0
                break;
            end

            Screen('FillRect',viewWindow,black);
            Screen('DrawTexture', viewWindow,tex,[],viewStimRect);
            Screen('DrawText', expWindow,['Time Elapsed: ' num2str(toc)],0,100);
         
            % Draw Fixation Cross on Framebuffer
            %Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
            
            % Draw fixation window on framebuffer
            Screen('FrameRect', expWindow, [255 255 255], fixRect);

            % Draw eyetrace on framebuffer
            Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            
            % Flip
            [timestamp] = Screen('Flip', viewWindow);
            [timestamp2] = Screen('Flip', expWindow);
            
            
            Screen('Close',tex) % Close the movie frame
            

            % Juice Reward
            
            if frameIdx > fps*rewardWait
                [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,fps,rewardWait,fixation,juiceDistTime,rewardPerf,rewardDur,timeSinceLastJuice);
            end
            frameIdx = frameIdx + 1; % Add one to frameIdx
            if quitNow == true
                
                break;
            end
        
        
        end
    Screen('CloseMovie')
        
    catch error
        rethrow(error)
    end % End of stim presentation
    
    save(dataSaveFile,'eyePosition','frameLastBeforeVideo');
    sca;
    
        
        
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
    
    function inRect = isInRect(xPos,yPos,rect)
        if (xPos >= rect(1)) && (xPos < rect(3)) && (yPos > rect(4)) && (yPos < rect(2))
            inRect = 1;
        else
            inRect = 0;
        end
    end


        
end


    
    
   






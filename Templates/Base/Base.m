function base(subject, counterbalance_indx, run)
    % Shape Color Paradigm 3.0
    % Stuart J. Duffield March 2022
    % Displays the stimuli from the Monkey Turk experiments in blocks.
    % Here for each block one of 7 stimuli (of the original 14) will be
    % displayed. At the end of the block there will be a choice
    
    % Parameters you care about:
    rewardDur = 0.04; % seconds
    rewardWait = 9; % seconds
    rewardPerf = .75; % 75% fixation to get reward
    exactDur = 30; % Need to manually calculate

    % Initialize DAQ
    DAQ('Debug',true);
    DAQ('Init');
    xGain = -550;
    yGain = 900;
    xOffset = 0;
    yOffset = 0;
    xChannel = 2;
    yChannel = 3; % DAQ indexes starting at 1, so different than fnDAQ
    ttlChannel = 8;


    
    %% Initialize Parameters
    KbName('UnifyKeyNames');
    % Initialize save paths for eyetracking and other data:
    curdir= pwd; % Current Directory
    stimDir = [curdir '/Stimuli']; % Change this if you move the location of the stimuli:
    if ~isfolder('Data') % Switch this to isfolder if matlab 2017 or later
        mkdir('Data');
    end
    runExpTime = datestr(now); % Get the time the run occured at.
    dataSaveFile = ['Data/' subject '_' num2str(run) '_Data.mat']; % File to save both run data and eye data
    movSaveFile = ['Data/' subject '_' num2str(run) '_Movie.mov']; % Create Movie Filename

    manualMovementPix = 10;

    % Movie parameters
    movieFPS = 10;

    % Refresh rate of monitors:
    fps = 30;
    ifi = 1/fps;

    % Timing Data:
    TR = 3; % TR length


    % Predefine Colors
    gray = [128 128 128];
    white = [255 255 255];
    green = [0 255 0];


    % Exact Duration
    runDur = 30; % Calculating this to compare to exact duration
    if runDur ~= exactDur % Ya gotta check or else you waste your scan time
        error('Run duration calculated from run parameters does not match hardcoded run duration length.')
    end

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 1; 
    viewscreen = 2;


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

    pixPerAngle = 40; % Number of pixels per degree of visual angle (actually 41.28, but very close
    stimPix = 6*pixPerAngle; % How large the stimulus rectangle will be
    fixPix = 3*pixPerAngle; % How large the fixation will be

    fixCrossDimPix = 10; % Fixation cross arm length
    lineWidthPix = 2; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords]; % Creates the fixation cross
    
    % Make base rectangle for fixation circle
    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
    
    juiceOn = false;
    juiceEndTime = 0;
    timeSinceLastJuice = 0;
    timeAtLastJuice = 0;
    quitNow = false;

    % Begind acutal stimulus presentation 
    try
        movie = Screen('CreateMovie', expWindow, movSaveFile,[],[],movieFPS);
        Screen('DrawText',expWindow,'Ready',xCenterExp,yCenterExp);


        Screen('Flip',expWindow);
        Screen('Flip',viewWindow);

        % Wait for TTL
        baselineVoltage = DAQ('GetAnalog',ttlChannel);
        while true
            [keyIsDown,secs,keyCode] = KbCheck;
            ttlVolt = DAQ('GetAnalog',ttlChannel);
            if keyCode(KbName('space'))
                break;
            elseif abs(ttlVolt - baselineVoltage) > 0.4
                break;
            end
        end
        
        flips = ifi:ifi:exactDur; 
        flips = flips + GetSecs;
        
        tic; % start timing
        frameIdx = 1; % What frame are we in

        % Begin Stimulus
           while true

            % Collect eye position
            [eyePosition(frameIdx,1),eyePosition(frameIdx,2)] = eyeTrack(xChannel,yChannel,xGain,yGain,xOffset,yOffset);
            fixation(frameIdx,1) = isInCircle(eyePosition(frameIdx,1),eyePosition(frameIdx,2),fixRect);
            
            if fixation(frameIdx,1) == 1
                circleColor = green;
            else
                circleColor = white;
            end

            if timeSinceLastJuice > rewardWait
                if frameIdx < fps*rewardWait;
                    tempFrameIdx = fps*rewardWait;
                else
                    tempFrameIdx = frameIdx;
                end

                if sum(fixation((tempFrameIdx-(fps*rewardWait)+1):tempFrameIdx),"all",'omitnan') > rewardPerf*fps*rewardWait
                    [juiceEndTime,juiceOn]= juice(rewardDur,juiceEndTime,toc,juiceOn);
                    timeSinceLastJuice = 0;
                    timeAtLastJuice = toc;
                else
                    timeSinceLastJuice = toc - timeAtLastJuice;                    
                end
            else
                timeSinceLastJuice = toc - timeAtLastJuice;
            end

            if juiceOn == true
                juiceSetting = 'On';
            else
                juiceSetting = 'Off';
            end

            % Check keys
            [keyIsDown,secs,keyCode] = KbCheck;


            % Process keys
            if keyCode(KbName('r')) % Recenter
                xOffset = xOffset + eyePosition(frameIdx,1)-xCenterExp;
                yOffset = yOffset + eyePosition(frameIdx,2)-yCenterExp;
            elseif keyCode(KbName('UpArrow')) % Move fixation point up
                yOffset = yOffset+manualMovementPix;
            elseif keyCode(KbName('DownArrow')) % Move fixation point down
                yOffset = yOffset-manualMovementPix;
            elseif keyCode(KbName('LeftArrow'))
                xOffset = xOffset+manualMovementPix;
            elseif keyCode(KbName('RightArrow'))
                xOffset = xOffset-manualMovementPix;
            elseif keyCode(KbName('j')) % Juice
                [juiceEndTime,juiceOn]=juice(rewardDur,juiceEndTime,toc,juiceOn);
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
            
            
            infotext = ['Time Elapsed: ', num2str(toc), '/', num2str(exactDur), newline,...
                'Fixation Percentage: ', num2str(sum(fixation(1:frameIdx,1))/length(fixation(1:frameIdx,1)*100)), newline,...
                'Juice: ', juiceSetting,newline,...
                'Juice End Time: ', num2str(juiceEndTime)]
               

            DrawFormattedText(expWindow,infotext);


            % Draw eyetrace on framebuffer
            Screen('DrawDots', expWindow, eyePosition(frameIdx,:)',5);
                
            % Draw stimuli
            Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);

            % Draw fixation window
            Screen('FrameOval',expWindow,white,fixRect);

            % add this frame to the movie
            if rem(frameIdx,fps/movieFPS)==1
                Screen('AddFrameToMovie',expWindow,[],[],movie)
            end

            % Flip
            [timestamp] = Screen('Flip', viewWindow, flips(frameIdx));
            [timestamp2] = Screen('Flip', expWindow, flips(frameIdx));

            [juiceEndTime,juiceOn] = juice(0,juiceEndTime, toc,juiceOn);
            
            if toc >= exactDur;
                quitNow = true
            end

            if quitNow == true
                Screen('FinalizeMovie', movie);
                sca
                break;
            end
            frameIdx = frameIdx+1;
        end
    catch error
        rethrow(error)
    end % End of stim presentation

    save(dataSaveFile);
    disp(['Fixation: ' num2str(sum(fixation)/length(fixation(1:frameIdx,1)))]);

    function [juiceEndTime,juiceOn] = juice(howLong,juiceEndTime, curTime,juiceOn)
        if howLong > 0
            if juiceEndTime > curTime
                juiceEndTime = juiceEndTime + howLong;
            else
                juiceEndTime = curTime + howLong;
            end
        end
        if juiceOn == true
            if juiceEndTime<=curTime
                DAQ('SetBit',[0 0 0 0]); % Turn it off if juice was on but juice no longer needs to be on
                juiceOn = false;
            else
                juiceOn = true;
            end
        elseif juiceOn == false
            if juiceEndTime > curTime
                DAQ('SetBit',[1 1 1 1])
                juiceOn = true;
            else
                juiceOn = false;
            end
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



            













    



 

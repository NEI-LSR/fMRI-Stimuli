function ColorLocalizer(subject, counterbalance_indx, run)
    % Shape Color Paradigm 3.0
    % Stuart J. Duffield March 2022
    % Displays the stimuli from the Monkey Turk experiments in blocks.
    % Here for each block one of 7 stimuli (of the original 14) will be
    % displayed. At the end of the block there will be a choice
    
    % Parameters you care about:
    rewardDur = 0.04; % seconds
    rewardWait = 9; % seconds
    rewardPerf = .75; % 75% fixation to get reward
    exactDur = 150; % Need to manually calculate

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
    block_order = [1 2 3 4 0];
    block_length = 10; % TRs
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
    LUTfile = '26-Jan-2022_PROPIXSmallNoFilter_LUT.mat';
    LUTDir = curdir;
    lookup = load([LUTDir '/26-Jan-2022_PROPIXSmallNoFilter_LUT.mat']);
    lookup = lookup.LUT;

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
    
    stim_colors = {[255 0 0; 0 255 0],...
        [0 0 255; 128 128 0]...
        [0 100 200; 200 100 0]...
        [200 100 0; 100 200 0]};

    % Exact Duration
    runDur = length(block_order)*block_length*TR; % Calculating this to compare to exact duration
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
    stimPix = pixPerAngle; % How large the stimulus rectangle will be
    fixPix = 3*pixPerAngle; % How large the fixation will be
    blurPix = 3; % How many pixels of blur between each stimulus
    stimMinusBlurPix = stimPix-blurPix;

    fixCrossDimPix = 10; % Fixation cross arm length
    lineWidthPix = 2; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords]; % Creates the fixation cross
    
    gratings = {};

    % Prep textures
    cyclePix = 2*stimPix;
    %period = 
    cyclesPerSec = 0.5;
    %pixPerFrame = cyclePix*cyclesPerSec/fps;
    tex={};
    for m = 1:length(stim_colors)
        color1 = stim_colors{m}(1,:);
        color2 = stim_colors{m}(2,:);
        for j = 1:(fps/cyclesPerSec)
            offset = round(cyclePix*sin(2*pi*j/(fps/cyclesPerSec)));
            tex{m}(j) = Screen('MakeTexture',viewWindow,trapezoid(stimMinusBlurPix,blurPix,color1,color2,offset,1080,lookup));
        end
    end

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
        
        
        flips = ifi:ifi:exactDur+1; 
        flips = flips + GetSecs;
        
        tic; % start timing
        frameIdx = 1; % What frame are we in
        block_index = 0;
        block_time = 0;
        % Begin Stimulus
           while true
            
            % Check block conditions 

            if frameIdx == 1 | block_time > block_length*TR
                block_start_time = toc;
                block_index = block_index+1;
                block = block_order(block_index);
            end

            block_time = toc-block_start_time; % what time is it within the block

            
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
            
            texInd = rem(frameIdx,(fps/cyclesPerSec))
            if texInd == 0;
                texInd = 30;
            end
            if block > 0;
                Screen('DrawTexture',viewWindow,tex{block}(texInd),[],viewRect);
            end

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

    

function vector = trapezoid(length1,length2,color1,color2,offset,size,varargin)
        % Do we have a LUT?
        LUTcheck = false;
        if length(varargin) == 1
            LUT = varargin{1};
            LUTcheck = true;
        elseif len(varargin{:}) > 1
            disp('Too many argument inputs, interpreting first argument as the LUT')
            LUT = varargin{1};
            LUTcheck = true;
        end
        % If we have a LUT, we can precalculate where each color falls.
        % Will help with calculations later
        if LUTcheck
            color1inv = NaN(1,3);
            color2inv = NaN(1,3);
            for i = 1:length(color1)
                d = 0;
                while isnan(color1inv(i))
                    color1inv(i)= find(color1(i)+d==LUT(:,i))
                    d = d + 1; % Walk it up if it returns NaN
                end
            end
            for i = 1:length(color2)
                d = 0;
                while isnan(color2inv(i))
                    color2inv(i)= find(color2(i)+d==LUT(:,i))
                    d = d + 1; % Walk it up if it returns NaN
                end
            end
        end

        vector = NaN(1,size,3);
        cycleLen = 2*length1+2*length2;
        for i = offset+1:offset+size;
            % First, we need to calculate the cycle number and the position
            % within the cycle
            if i > cycleLen
                p = rem(i,cycleLen);
                if p == 0
                    p = cycleLen;
                end
            elseif i<0
                p = cycleLen-rem(abs(i),cycleLen);
            else
                p = i;
                if p == 0
                    p = cycleLen;
                end
            end
            % Now, we need to determine the color multipliers at any given
            % time
            if p >= 1 && p <= length1
                color1mult = 1;
                color2mult = 0;
                slope = false; 
            elseif p > length1 && p <= length1+length2
                color1mult = 1-((p-length1)/(length2+1));
                color2mult = (p-length1)/(length2+1);
                slope = true;
            elseif p > length1 + length2 && p <= 2*length1 + length2
                color1mult=0;
                color2mult=1;
                slope = false;
            else
                color1mult = 1-(((length2+1) - (p - (2*length1+length2)))/(length2+1));
                color2mult = ((length2+1) - (p - (2*length1+length2)))/(length2+1);
                slope=true;
            end
            % Now, we need to calculate the colors
            if LUTcheck && slope
                vector(1,i-offset,:) = LUT(round(color1inv*color1mult+color2inv*color2mult));
            else
                vector(1,i-offset,:) = color1*color1mult+color2*color2mult;
            end

        end

    end

end

   









            













    



 

function FiveDot

    

    % Initialize DAQ
    DAQ('Init');
    xGain = -220;
    yGain = 205;
    gainStep = 5;
    xOffset = -930;
    yOffset = 650;
    xChannel = 2;
    yChannel = 3; % DAQ indexes starting at 1, so different than fnDAQ
    ttlChannel = 8;
    rewardDur = 0.05; % seconds
    rewardWait = 6; % seconds
    newRewardRate = rewardWait;
    maxChange = 0.5; % How much does it change
    rewardCalcDur = 10; % Number of seconds fixation is calculated over 
    incRate = true; % Change rate?
    rewardPerf = .80; % 80% fixation to get reward
    % play movie?
    start_movie = true;
    play_movie = false;

    % How long will this last
    exactDur = 6000;
    
    linecolorIdx = 1;
    linecolors = [0 0 0; 255 0 0; 0 255 0; 0 0 255; 255 255 255];
    linecolor = linecolors(1,:);

    
    
    % Initialize parameters
    KbName('UnifyKeyNames');
    % Initialize save paths for eyetracking, other data:
    curdir = pwd; % Current Directory
    stimDir = [curdir '/Stimuli']; % Stimulus directory
    if ~isfolder('Data') % Switch this to isfolder if matlab 2017 or later
        mkdir('Data');
    end

    runExpTime = datestr(now); % Get the time the run occured at.

    dataSaveFile = ['Data/'  'EyeData_Data.mat']; % File to save eye data
    
    % Prep mvie info
    movieName = 'our_planet.mp4';
    %stimDir = [curdir]; % Change this if you move the location of the stimuli:
    movieFile = [stimDir '\' movieName]
    
    if start_movie && ~isfile(movieFile)
        error('No movie file')
    end

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 1; 
    viewscreen = 2;

    % Refresh rate of monitors:
    fps = 30;
    ifi = 1/fps;
    
    % Gray of the background:
    %gray = [31 29 47]; % Wooster Shape-Color Gray 
    gray = [128 128 128]; 
    
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
    
    pixPerAngle = 100; % Number of pixels per degree of visual angle
    fixPix = 1*pixPerAngle; % How large the fixation will be
    stimPix = 200;
    
    fixCrossDimPix = 20; % Fixation cross arm length
    lineWidthPix = 4; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    % Make base rectangle and centered rectangle for stimulus presentation
    baseRect = [0 0 stimPix stimPix]; % Size of the texture rect
    
    % Make base rectangle for fixation circle
    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
    % Make stimulus rect
    stimRect = [0 0 0.5*fixPix 0.5*fixPix];
    viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
    expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
    % Load Fixation Grid and Create Texture:
    load([stimDir '/' 'fixGrid.mat'], 'fixGrid'); % Loads the .mat file with the fixation grid texture
    fixGridTex = Screen('MakeTexture', viewWindow, fixGrid); % Creates the fixation grid as a texture
    
        
    eyePosition = NaN(fps*exactDur,2); % Column 1 xposition, column 2 yposition
    fixation = NaN(fps*exactDur,1); % Fixation tracker
    Priority(2) % topPriorityLevel?
    %Priority(9) % Might need to change for windows
    juiceOn = false; % Logical for juice giving
    juiceDistTime = 0; % When was the last time juice was distributed
    quitNow = false;
    timeSinceLastJuice = GetSecs-juiceDistTime;
    
    % Prep movie if needed
    if start_movie
        [movie duration fps] = Screen('OpenMovie', viewWindow, movieFile)
    end
    % Begin actual stimulus presentation
    try
        Screen('DrawTexture', expWindow, fixGridTex);
        if start_movie
            Screen('PlayMovie',movie,1)
        end
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
            elseif keyCode(KbName('n')) && fixPix > pixPerAngle/2 % Increase fixation circle
                fixPix = fixPix - pixPerAngle/2; % Shrink fixPix by half a degree of visual angle
                baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
            elseif keyCode(KbName('m')) && fixPix < pixPerAngle*10
                fixPix = fixPix + pixPerAngle/2; % Increase fixPix by half a degree of visual angle
                baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
            elseif keyCode(KbName('s')) && yCenter < 1050 % Move fixation up
                yCenterExp = yCenterExp + pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                yCenter = yCenter + pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('w')) && yCenter > 0 % Move fixation down
                yCenterExp = yCenterExp - pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                yCenter = yCenter - pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('d')) && xCenter < 1900 % move fixation right
                xCenterExp = xCenterExp + pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                xCenter = xCenter + pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('a')) && xCenter > 0 % Move fixation left
                xCenterExp = xCenterExp - pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                xCenter = xCenter - pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('f'))
                [xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen
            elseif keyCode(KbName('y'))
                xGain = xGain + gainStep;
            elseif keyCode(KbName('h'))
                xGain = xGain - gainStep;
             elseif keyCode(KbName('t'))
                yGain = yGain + gainStep;
            elseif keyCode(KbName('g'))
                yGain = yGain - gainStep;
            elseif keyCode(KbName('q'))
                %linecolorIdx = randi([1 5], 1);
                %linecolor = linecolors(linecolorIdx,:);
                linecolor = [randi([1 255],1) randi([1 255],1) randi([1 255],1)];
            elseif keyCode(KbName('v'))
                if lineWidthPix < 10;
                    fixCrossDimPix = fixCrossDimPix + 4; % Fixation cross arm length
                    lineWidthPix = lineWidthPix + 1; % Fixation cross arm thickness
                    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
                    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
                    allCoords = [xCoords; yCoords];
                    stimRect(3) = stimRect(3) + 8;
                    stimRect(4) = stimRect(4) + 8;
                    viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                    expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
                end
            elseif keyCode(KbName('b'))
                if lineWidthPix > 1
                    fixCrossDimPix = fixCrossDimPix - 4; % Fixation cross arm length
                    lineWidthPix = lineWidthPix - 1; % Fixation cross arm thickness
                    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
                    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
                    allCoords = [xCoords; yCoords];
                    stimRect(3) = stimRect(3) - 8;
                    stimRect(4) = stimRect(4) - 8;
                    viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                    expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
                end
            elseif keyCode(KbName('z'))
                if play_movie == false
                    play_movie = true
                elseif play_movie == true
                    play_movie = false
                end
            elseif keyCode(KbName('p'))
                quitNow = true;
            end


            % Draw movie if playing on framebuffer
            if start_movie
                tex = Screen('GetMovieImage', viewWindow, movie);
            end
            if play_movie == true
                Screen('DrawTexture', viewWindow,tex,[],viewStimRect);
                Screen('DrawTexture', expWindow,tex,[],expStimRect);

            end

            % Draw Text on FrameBuffer:
            text = ['xGain: ', num2str(xGain), newline,...
                'yGain: ' num2str(yGain), newline,...
                'xLocation: ' num2str(xCenter),  newline,...
                'yLocation: ' num2str(yCenter), newline,...
                'Fixation Percentage: ', num2str(sum(fixation(1:frameIdx,1))/length(fixation(1:frameIdx,1)*100)), newline...
                'Reward Rate :' num2str(newRewardRate)];

            DrawFormattedText(expWindow, text);
            
            % Draw Fixation Cross on Framebuffer
            Screen('DrawLines', viewWindow, allCoords, lineWidthPix, linecolor, [xCenter yCenter], 2);
            Screen('DrawLines', expWindow, allCoords, lineWidthPix, linecolor, [xCenterExp yCenterExp], 2);

            % Draw fixation window on framebuffer
            Screen('FrameOval', expWindow, linecolor, fixRect);

            % Draw eyetrace on framebuffer
            Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            
            % Flip
            [timestamp] = Screen('Flip', viewWindow, flips(frameIdx));
            [timestamp2] = Screen('Flip', expWindow, flips(frameIdx));
            
            % Juice Reward
            if incRate == true && frameIdx > fps*rewardCalcDur
                 newRewardRate = ((1+maxChange) - sum(fixation(frameIdx-fps*rewardCalcDur+1:frameIdx),"all")/(fps*rewardCalcDur))*rewardWait;
            end
            if frameIdx > fps*rewardWait
                [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,fps,newRewardRate,fixation,juiceDistTime,rewardPerf,rewardDur,timeSinceLastJuice);
            end
            if quitNow == true
                sca;
                break;
            end
            
        end
        
        
    catch error
        rethrow(error)
    end % End of stim presentation
    
    disp(['xGain: ' num2str(xGain)]);
    disp(['yGain: ' num2str(yGain)]);
    disp(['xOffset: ' num2str(xOffset)]);
    disp(['yOffset: ' num2str(yOffset)]);

    save(dataSaveFile, 'eyePosition');
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


        
end


    
    
   






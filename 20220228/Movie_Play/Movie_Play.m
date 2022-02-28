function Movie_Play(subject, run)
    % Play Movie 1.0
    % Stuart J. Duffield January 2022

    
    movieName = 'sherlock_seg1.mp4';

    % Initialize DAQ
    DAQ('Debug',false);
    DAQ('Init');
    xGain = 550;
    yGain = -700;
    xOffset = 0;
    yOffset = 0;
    xChannel = 2;
    yChannel = 3; % DAQ indexes starting at 1, so different than fnDAQ
    ttlChannel = 8;
    rewardDur = 0.08; % seconds
    rewardWait = 3.5; % seconds
    rewardPerf = .90; % 80% fixation to get reward
    
    
    
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
    fps = round(fps);
    ifi = 1/fps;
    exactDur = round(duration+(20*TR));

    eyePosition = NaN(round(fps*exactDur)+3000,2); % Column 1 xposition, column 2 yposition
    fixation = NaN(round(fps*exactDur)+3000,1); % Fixation tracker
    Priority(2) % topPriorityLevel?
    %Priority(9) % Might need to change for windows
    juiceOn = false; % Logical for juice giving
    juiceDistTime = 0; % When was the last time juice was distributed
    quitNow = false;
    timeSinceLastJuice = GetSecs-juiceDistTime;
    
    % Begin actual stimulus presentation
    try
        Screen('PlayMovie',movie,1)
        %Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
        Screen('DrawText',expWindow,'Ready',960,540)
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
        
        drawLines = true;
        frameIdx = 1;
        tic; % start stopwatch    
        flips = toc:ifi:(20*TR);
        flip_indx = 1;
        while toc < (10*TR) && quitNow == false
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
            elseif keyCode(KbName('z'))
                if drawLines == true
                    drawLines = false;
                elseif drawLines == false
                    drawLines = true;
                end

            end


            Screen('FillRect',viewWindow,gray);
            Screen('DrawText', expWindow,['Time Elapsed: ' num2str(toc)],0,100);
         
            % Draw Fixation Cross on Framebuffer
            if drawLines == true
                Screen('DrawLines', viewWindow, allCoords, lineWidthPix,black, [xCenter yCenter], 2);
            end

            % Draw fixation window on framebuffer
            Screen('FrameRect', expWindow, [255 255 255], fixRect);

            % Draw eyetrace on framebuffer
            Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            
            % Flip
            [timestamp] = Screen('Flip', viewWindow,flips(flip_indx));
            [timestamp2] = Screen('Flip', expWindow,flips(flip_indx));
            flip_indx = flip_indx+1;   
                            
    
            % Juice Reward
                
            if frameIdx > fps*rewardWait
                [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,fps,rewardWait,fixation,juiceDistTime,rewardPerf,rewardDur,timeSinceLastJuice);
            end

            frameIdx = frameIdx + 1; % Add one to frameIdx


        end
        frameLastBeforeVideo=frameIdx;
        tex = Screen('GetMovieImage', viewWindow, movie);
        
        while toc < ((10*TR)+duration-(2*ifi)) && quitNow == false
%             Screen('PlayMovie',movie,1);
%             if toc < (10*TR)
%                 Screen('PlayMovie',movie,0);
%                 Screen('DrawText',expWindow,'True',0,200);
%                 frameLastBeforeVideo=frameIdx;
%             end
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

            % Get movie image
            tex = Screen('GetMovieImage', viewWindow, movie);
            if tex<=0
                break;
                error('Movie ran out of frames');

            end

            Screen('FillRect',viewWindow,gray);
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
        tex = Screen('GetMovieImage', viewWindow, movie);
        Screen('PlayMovie',movie,0)
        end_indx = frameIdx;
        flips = timestamp:ifi:(timestamp+(11*TR));
        flip_indx = 1;
        while toc < (duration+(20*TR)) && quitNow == false
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

            % Get movie image
            

            Screen('FillRect',viewWindow,gray);
            Screen('DrawTexture', viewWindow,tex,[],viewStimRect);
            Screen('DrawText', expWindow,['Time Elapsed: ' num2str(toc)],0,100);
         
            % Draw Fixation Cross on Framebuffer
            Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
            
            % Draw fixation window on framebuffer
            Screen('FrameRect', expWindow, [255 255 255], fixRect);

            % Draw eyetrace on framebuffer
            Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            
            % Flip
            [timestamp] = Screen('Flip', viewWindow,flips(flip_indx));
            [timestamp2] = Screen('Flip', expWindow,flips(flip_indx));
            flip_indx = flip_indx+1;   
                            
    
            % Juice Reward
                
            if frameIdx > fps*rewardWait
                [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,fps,rewardWait,fixation,juiceDistTime,rewardPerf,rewardDur,timeSinceLastJuice);
            end

            frameIdx = frameIdx + 1; % Add one to frameIdx


        end
        Screen('CloseMovie')


        
    catch error
        rethrow(error)
    end % End of stim presentation

    save(dataSaveFile,'eyePosition','frameLastBeforeVideo','end_indx');
    sca;
    disp(fixationText);
        
        
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


    
    
   






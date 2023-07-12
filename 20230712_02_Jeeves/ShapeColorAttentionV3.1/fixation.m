
function [params] = fixation(params);

    newRewardRate = params.rewardWait;
    maxChange = 0.2; % How much does it change
    rewardCalcDur = 10; % Number of seconds fixation is calculated over 
    incRate = true; % Change rate?


    % How long will this last
    exactDur = 3600;
    
    linecolors = [0 0 0; 255 0 0; 0 255 0; 0 0 255; 255 255 255];
    linecolor = linecolors(1,:);

    
    
    % Initialize parameters
    KbName('UnifyKeyNames');
    % Initialize save paths for eyetracking, other data:

    params.date_time = strrep(strrep(datestr(datetime),' ','_'),':','_'); % Get the numstring of the time 
    dataSaveFile = ['Data/'  num2str(params.date_time) '_EyeData.mat']; % File to save eye data

   
    
    % Initialize Screens
    Screen('Preference', 'SkipSyncTests', 1); 
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    
    
    [expWindow, expRect] = Screen('OpenWindow', params.expscreen, params.gray); % Open experimenter window
    [viewWindow, viewRect] = Screen('OpenWindow', params.viewscreen, params.gray); % Open viewing window (for subject)
    Screen('BlendFunction', viewWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    Screen('BlendFunction', expWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    
    [xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
    [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen
    
    fixPix = 1*params.pixPerAngle; % How large the fixation will be
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
    load([params.stimDir '/' 'fixGrid.mat'], 'fixGrid'); % Loads the .mat file with the fixation grid texture
    fixGridTex = Screen('MakeTexture', viewWindow, fixGrid); % Creates the fixation grid as a texture
    
        
    eyePosition = NaN(params.FPS*exactDur,2); % Column 1 xposition, column 2 yposition
    fixation = NaN(params.FPS*exactDur,1); % Fixation tracker
    Priority(2) % topPriorityLevel?
    %Priority(9) % Might need to change for windows
    juiceOn = false; % Logical for juice giving
    juiceDistTime = 0; % When was the last time juice was distributed
    quitNow = false;
    timeSinceLastJuice = GetSecs-juiceDistTime;
    
    % Begin actual stimulus presentation
    try
        Screen('DrawTexture', expWindow, fixGridTex);

        Screen('Flip', expWindow);
        Screen('Flip', viewWindow);
        
        % Wait for TTL
        baselineVoltage = DAQ('GetAnalog',params.ttlChannel);
        while true
            [keyIsDown,secs, keyCode] = KbCheck;
            ttlVolt = DAQ('GetAnalog',params.ttlChannel);
            if keyCode(KbName('space'))
                break;
            elseif abs(ttlVolt - baselineVoltage) > 0.4
                break;
            end
        end
        
        flips = params.IFI:params.IFI:exactDur;
        flips = flips + GetSecs;
        
        for frameIdx = 1:params.FPS*exactDur
            % Check keys
            [keyIsDown,secs, keyCode] = KbCheck;
                
            
            % Collect eye position
            [eyePosition(frameIdx,1), eyePosition(frameIdx,2)] = eyeTrack(params.xChannel, params.yChannel, params.xGain, params.yGain, params.xOffset, params.yOffset);
            fixation(frameIdx,1) = isInCircle(eyePosition(frameIdx,1),eyePosition(frameIdx,2),fixRect);
            % Process Keys
            if keyCode(KbName('r')) % Recenter
                params.xOffset = params.xOffset + eyePosition(frameIdx,1)-xCenterExp;
                params.yOffset = params.yOffset + eyePosition(frameIdx,2)-yCenterExp;
            elseif keyCode(KbName('j')) % Juice
                juiceOn = true;
            elseif keyCode(KbName('n')) && fixPix > params.pixPerAngle/2 % Increase fixation circle
                fixPix = fixPix - params.pixPerAngle/2; % Shrink fixPix by half a degree of visual angle
                baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
            elseif keyCode(KbName('m')) && fixPix < params.pixPerAngle*10
                fixPix = fixPix + params.pixPerAngle/2; % Increase fixPix by half a degree of visual angle
                baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
            elseif keyCode(KbName('s')) && yCenter < 1050 % Move fixation up
                yCenterExp = yCenterExp + params.pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                yCenter = yCenter + params.pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('w')) && yCenter > 0 % Move fixation down
                yCenterExp = yCenterExp - params.pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                yCenter = yCenter - params.pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('d')) && xCenter < 1900 % move fixation right
                xCenterExp = xCenterExp + params.pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                xCenter = xCenter + params.pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('a')) && xCenter > 0 % Move fixation left
                xCenterExp = xCenterExp - params.pixPerAngle;
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                xCenter = xCenter - params.pixPerAngle;
                viewStimRect = CenterRectOnPointd(stimRect, xCenter,yCenter);
                expStimRect = CenterRectOnPointd(stimRect, xCenterExp,yCenterExp);
            elseif keyCode(KbName('f'))
                [xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
                fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen
            elseif keyCode(KbName('y'))
                params.xGain = params.xGain + params.gainStep;
            elseif keyCode(KbName('h'))
                params.xGain = params.xGain - params.gainStep;
             elseif keyCode(KbName('t'))
                params.yGain = params.yGain + params.gainStep;
            elseif keyCode(KbName('g'))
                params.yGain = params.yGain - params.gainStep;
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
            elseif keyCode(KbName('1!')) % Juice
                params.rewardDur = params.rewardDur + params.rewardKeyChange;
            elseif keyCode(KbName('2@')) % Juice
                params.rewardDur = params.rewardDur - params.rewardKeyChange;
            elseif keyCode(KbName('3#')) % Juice
                params.rewardWait = params.rewardWait + params.rewardWaitChange;
            elseif keyCode(KbName('4$')) % Juice
                params.rewardWait = params.rewardWait - params.rewardWaitChange;
            elseif keyCode(KbName('p'))
                quitNow = true;
            end


            % Draw Text on FrameBuffer:
            text = ['xGain (y+/h-): ', num2str(params.xGain), newline,...
                'yGain (t+/g-): ' num2str(params.yGain), newline,...
                'xLocation: ' num2str(xCenter),  newline,...
                'yLocation: ' num2str(yCenter), newline,...
                'Fixation Percentage: ', num2str(sum(fixation(1:frameIdx,1))/length(fixation(1:frameIdx,1)*100)), newline...
                'Reward Duration (+1/-2): ' num2str(params.rewardDur),newline,...
                'Reward Wait Time (+3/-4): ' num2str(newRewardRate),newline,...
                '(v+/b-): Increase/Decrease Fixation Cross',newline,...
                '(n+/m-): Increase/Decrease Fixation Window',newline,...
                '(q): Change Cross Color',newline,...
                '(r): Recenter',newline,...
                '(f): Place Fixation Cross at Center',newline,...
                '(wasd): Move Fixation Cross Around',newline,...
                '(p): quit'];

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
            if incRate == true && frameIdx > params.FPS*rewardCalcDur
                 newRewardRate = ((1+maxChange) - sum(fixation(round(frameIdx-params.FPS*rewardCalcDur+1):frameIdx),"all")/(params.FPS*rewardCalcDur))*params.rewardWait;
            end
            if frameIdx > params.FPS*params.rewardWait
                [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,params.FPS,newRewardRate,fixation,juiceDistTime,params.rewardPerf,params.rewardDur,timeSinceLastJuice);
            end
            if quitNow == true
                sca;
                break;
            end
            
        end
        
        
    catch error
        rethrow(error)
    end % End of stim presentation
    
    disp(['xGain: ' num2str(params.xGain)]);
    disp(['yGain: ' num2str(params.yGain)]);
    disp(['xOffset: ' num2str(params.xOffset)]);
    disp(['yOffset: ' num2str(params.yOffset)]);
    disp(['Fixation: ' num2str(sum(fixation,1,'omitnan')/length(fixation(~isnan(fixation))))]);

    save(dataSaveFile, 'eyePosition');
    sca;
    close all;
        
        
    function [juiceOn, juiceDistTime,timeSinceLastJuice] = juiceCheck(juiceOn, frameIdx,fps,rewardWait,fixation,juiceDistTime,rewardPerf,rewardDur,timeSinceLastJuice)

        timeSinceLastJuice = GetSecs-juiceDistTime;
        
        if juiceOn == false && timeSinceLastJuice > rewardWait && sum(fixation(round(frameIdx-fps*rewardWait+1:frameIdx)),"all") > rewardPerf*fps*rewardWait
            juiceOn = true;
        end
        if juiceOn == true 
            juiceOn = false;
            DAQ('SetBit',[1 1 1 1]);
            juiceDistTime = GetSecs;
            timeSinceLastJuice = GetSecs-juiceDistTime;
        end
        if timeSinceLastJuice > params.rewardDur % This won't have the best timing since its linked to the fliprate
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


    
    
   






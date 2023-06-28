function [params] = Fruit_Decode(params)
    % Fruit Decode
    % Stuart J. Duffield, Noah K. Lasky-Nielson, and Helen E. Feibes June 2023
    % Experiment to see if we can decode color information from grayscale
    % images of fruits. Presents images of fruits in a blocked design.
    


    
    %% Initialize Parameters
    KbName('UnifyKeyNames'); % Create common key naming scheme for keyboard

    % Run information
    params.complete = false;

    % Set up save file paths
    params.runExpTime = datestr(now); % Get the time the run occured at.
    params.sessionDate = datestr(now,'yyyy-mm-dd');
    params.date_time = strrep(strrep(datestr(datetime),' ','_'),':','_'); % Get the numstring of the time 
    nameInfo = [params.subject '_Run_' num2str(params.runNum) '_IMA_' num2str(params.IMA) '_' params.date_time];
    params.dataSaveFile = fullfile(params.dataDir,[nameInfo '_Data.mat']); % File to save both run data and eye data
    params.movSaveFile = ['Data/' nameInfo '_Movie.mov']; % Create Movie Filename
    params.DMSaveFile = fullfile(params.dataDir,[nameInfo '_DM.txt']); % Create Design Matrix Filename
    params.eyeTraceSaveFile = fullfile(params.resultsDir,[nameInfo '_eyeDistance.png']); % Create eyetrace filename
    params.eyeTraceDistanceDMSaveFile = fullfile(params.resultsDir,[nameInfo '_eyeDistance.csv']); % Create eye distance csv
    params.eyeTraceFixationDMSaveFile = fullfile(params.resultsDir,[nameInfo '_eyeFixation.csv']); % Create eye distance csv

    % Set up other screen parameters 
    params.red = [255 0 0]; % Red color
    params.green = [0 255 0]; % Green color
    params.blue = [0 0 255]; % Blue color
    params.white = [255 255 255]; % White color

    % Initialize Screens
    Screen('Preference', 'SkipSyncTests', 1); % Skip sync tests
    Screen('Preference', 'VisualDebugLevel', 0); % Don't visually debug
    Screen('Preference', 'Verbosity', 0); % No verbosity
    Screen('Preference', 'SuppressAllWarnings', 1); % Supress all warnings

    [expWindow, expRect] = Screen('OpenWindow', params.expscreen, params.gray); % Open experimenter window
    [viewWindow, viewRect] = Screen('OpenWindow', params.viewscreen, params.gray); % Open viewing window (for subject)
    [xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
    [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen
    Screen('BlendFunction', viewWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    Screen('BlendFunction', expWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function

    params.stimPix = 20*params.pixPerAngle; % How large the stimulus rectangle will be
    params.fixPix = params.stimPix; % How large the params.fixation rectangle will be

    % Make base rectangle for stimulus presentation
    params.baseRect = [0 0 params.stimPix params.stimPix]; % Size of the texture rect
    
    % Premake these variables to prevent error
    viewStimRect = CenterRectOnPointd(params.baseRect, xCenter, yCenter);
    expStimRect = CenterRectOnPointd(params.baseRect, xCenterExp, yCenterExp);
    
    % Make base rectangle for params.fixation rectangle
    params.baseFixRect = [0 0 params.fixPix params.fixPix]; % Size of the params.fixation rectangle
    params.fixRect = CenterRectOnPointd(params.baseFixRect, xCenterExp, yCenterExp); % We center the params.fixation rectangle on the center of the screen
    
    % Create Textures
    for i = 1:length(params.conditions)
        a = dir([params.stimDir filesep params.conditions{i} '*.png']);
        names = extractfield(a,'name');
        params.imagePaths(i).paths = strcat(params.stimDir,filesep,names);
        params.textures(i).texinds = NaN(length(params.imagePaths(i).paths),1);
        for y = 1:length(params.imagePaths(i).paths)
            [img,~,alpha] = imread(params.imagePaths(i).paths{y});
            image = cat(3,img,alpha);
            params.textures(i).texinds(y) = Screen('MakeTexture',viewWindow,image);
            Screen('DrawText',expWindow,['Loaded ' names{y}],xCenterExp,yCenterExp); % Display 'ready' 
            Screen('Flip',expWindow); % First flip
        end
    end

    % How many images will be displayed in each block?
    params.numblockimages = params.blocklength*params.TR/params.stimDur;

    % Create variables that track different states of the script and
    % behavior
    params.eyePosition = NaN(10000*params.runDur,2); % Set up eyePosition array
    params.fixation = NaN(10000*params.runDur,1); % Set up fixation array
    params.blockTracker = NaN(10000*params.runDur,1); % Set up block tracking array
    params.juiceOnTracker = NaN(10000*params.runDur,1); % Tracing whether juice is 'on' or not
    params.timeTracker = NaN(10000*params.runDur,1); % Actually track the time

    % Set priority
    Priority(2) % Highest priority for windows, 9 is highest priority for linux and mac

    % Juice and timing variables
    juiceOn = false; % Logical for juice giving
    juiceEndTime = 0; % Initialize the variable that stores when the juice ends
    timeSinceLastJuice = 0; % Initialze the variable that stores how long it has been since the juice turned off
    timeAtLastJuice = 0; % Initialize the variable storing when the juice was last given
    quitNow = false; % Initialize the variable that flags if it is time to quit
    
    % Begin actual stimulus presentation
    % Always start with try because Psychtoolbox locks up badly
    try
       movie = Screen('CreateMovie', expWindow, params.movSaveFile,[],[],params.movieFPS); % Open movie file
       Screen('DrawText',expWindow,'Ready',xCenterExp,yCenterExp); % Display 'ready' 
       Screen('Flip',expWindow); % First flip
       Screen('Flip',viewWindow); % First flip
       % Wait for TTL
        baselineVoltage = DAQ('GetAnalog',params.ttlChannel); % Get the baseline voltage
        while true
            [keyIsDown,secs,keyCode] = KbCheck; % Get keyboard inputs
            ttlVolt = DAQ('GetAnalog',params.ttlChannel); % Get current voltage
            if keyCode(KbName('space')) % If space is pressed
                break; % Begin
            elseif abs(ttlVolt - baselineVoltage) > 0.4 % If TTL voltage has changed by more than said values
                break; % Begin
            end
        end

        tic; % start timing
        startBlockTime = toc; % Start block timer
        blockTime = 0; % Initialize the variable that stores how much block time has passed
        blockIndx = 0; % What block are we in
        frameIdx = 0; % What frame is this

        % Begin Stimulus
        while true
            % Exit logic
            if toc >= params.runDur % Has the run completed
                quitNow = true;
                params.complete = true;
            end
            
            if quitNow == true
                Screen('FinalizeMovie',movie);
                sca
                save(params.dataSaveFile);
                disp(['params.fixation: ' num2str(sum(params.fixation,'omitnan')/sum(~isnan(params.fixation)))]);
                break
            end
            
            % Add Frames
            frameIdx = frameIdx + 1;

            % Block Logic
            if blockIndx == 0
                blockIndx = blockIndx + 1;
                blockType = params.conditions{blockIndx};
                blockstimuliorder = randsample(params.textures(blockIndx).texinds,params.numblockimages,true);
                stimuliIndx = 1;
                stimuliTime = 0;
                startBlockTime = toc;
                startStimuliTime = toc;

            end

            blockTime = toc-startBlockTime; % What is the blocktime
            
            if blockTime >= params.blocklength*params.TR && blockIndx < params.numblocks
                blockIndx = blockIndx + 1;
                blockType = params.conditions{blockIndx};
                blockTime = 0;
                startBlockTime = toc;
                blockstimuliorder = randsample(params.textures(blockIndx).texinds,params.numblockimages,true);
                stimuliIndx = 1;
                stimuliTime = 0;
                startStimuliTime = toc;

            end
            
            params.blockTracker(frameIdx) = blockIndx; % Store what block we're in

            % Collect eye position
            [params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2)] = eyeTrack(params.xChannel,params.yChannel,params.xGain,params.yGain,params.xOffset,params.yOffset);
            params.fixation(frameIdx,1) = isInRect(params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2),params.fixRect);
            
            if timeSinceLastJuice > params.rewardWaitActual % Has enough time passed to give reward again
                startTime = toc - params.rewardWait;
                fixationindices = params.timeTracker > startTime;

                if sum(params.fixation(fixationindices),"all",'omitnan') > sum(fixationindices)*params.rewardPerf % Have they kept fixation enough to get reward again
                    [juiceEndTime,juiceOn]= juice(params.rewardDur,juiceEndTime,toc,juiceOn);
                    timeSinceLastJuice = 0;
                    timeAtLastJuice = toc;
                    params.rewardWaitActual = params.rewardWait+(2*rand-1)*params.rewardWaitJitter; % Jitter the reward wait
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
            [keyIsDown,~,keyCode] = KbCheck;


            % Process keys
            if keyIsDown == 1
                if keyCode(KbName('r')) % Recenter
                    params.xOffset = params.xOffset + params.eyePosition(frameIdx,1)-xCenterExp;
                    params.yOffset = params.yOffset + params.eyePosition(frameIdx,2)-yCenterExp;
                    keyIsDown=0;
                elseif keyCode(KbName('UpArrow')) % Move params.fixation point up
                    params.yOffset = params.yOffset+params.manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('DownArrow')) % Move params.fixation point down
                    params.yOffset = params.yOffset-params.manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('LeftArrow'))
                    params.xOffset = params.xOffset+params.manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('RightArrow'))
                    params.xOffset = params.xOffset-params.manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('j')) % Juice
                    [juiceEndTime,juiceOn]=juice(params.rewardDur,juiceEndTime,toc,juiceOn);
                    keyIsDown=0;
                elseif keyCode(KbName('c'))
                    params.rewardDur = params.rewardDur + params.rewardKeyChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('v')) && params.rewardDur > params.rewardKeyChange
                    params.rewardDur = params.rewardDur - params.rewardKeyChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('b'))
                    params.rewardWait = params.rewardWaitChange + params.rewardWait;
                    keyIsDown = 0;
                elseif keyCode(KbName('n')) && params.rewardWait > params.rewardWaitChange
                    params.rewardWait = params.rewardWait-params.rewardWaitChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('1!'))
                    params.rewardWaitJitter = params.rewardWaitChange + params.rewardWaitJitter;
                    keyIsDown = 0;
                elseif keyCode(KbName('2@')) && params.rewardWaitJitter > params.rewardWaitChange
                    params.rewardWait = params.rewardWaitJitter-params.rewardWaitChange;
                    keyIsDown = 0;
                % Need to change this from circle to rectangle
                % elseif keyCode(KbName('w')) && params.fixPix > params.pixPerAngle/2 % Increase params.fixation circle
                %    params.fixPix = params.fixPix - params.pixPerAngle/2; % Shrink params.fixPix by half a degree of visual angle
                %    params.baseFixRect = [0 0 params.fixPix params.fixPix]; % Size of the params.fixation circle
                %    params.fixRect = CenterRectOnPointd(params.baseFixRect, xCenterExp, yCenterExp); % We center the params.fixation rectangle on the center of the screen
                %    keyIsDown=0;
                % elseif keyCode(KbName('s')) && params.fixPix < params.pixPerAngle*10
                %    params.fixPix = params.fixPix + params.pixPerAngle/2; % Increase params.fixPix by half a degree of visual angle
                %    params.baseFixRect = [0 0 params.fixPix params.fixPix]; % Size of the params.fixation circle
                %    params.fixRect = CenterRectOnPointd(params.baseFixRect, xCenterExp, yCenterExp); % We center the params.fixation rectangle on the center of the screen
                %    keyIsDown=0;
            
                 elseif keyCode(KbName('p'))
                    quitNow = true;
                    keyIsDown=0;
                 end
            end


            % Prepare to draw stimuli
            stimuliTime = toc-startStimuliTime;
            if stimuliTime > params.stimDur
                if stimuliIndx < params.numblockimages
                    stimuliIndx = stimuliIndx + 1;
                end
                startStimuliTime = toc;
                stimuliTime = 0;
            end
            Screen('DrawTexture',viewWindow,blockstimuliorder(stimuliIndx),[],viewStimRect);


            % Draw eyetrace on framebuffer
            Screen('DrawDots',expWindow, params.eyePosition(frameIdx,:)',5);

            infotext = ['Time Elapsed: ', num2str(toc), '/', num2str(params.runDur), newline,...
                    'Block Time Elapsed: ', num2str(blockTime), '/',num2str(params.blocklength*params.TR), newline,...
                    'Block Number: ', num2str(blockIndx), newline,...
                    'Fixation Percentage: ', num2str(sum(params.fixation(1:frameIdx,1))/length(params.fixation(1:frameIdx,1)*100)), newline,...
                    'Block Type: ', blockType,newline,...
                    'Juice: ', juiceSetting,newline,...
                    'Juice End Time: ', num2str(juiceEndTime),newline,...
                    'Reward Duration (+c/-v): ', num2str(params.rewardDur),newline,...
                    'Reward Wait Time (+b/-n): ', num2str(params.rewardWait),newline,...
                    'Actual Reward Wait Time: ', num2str(params.rewardWaitActual),newline,...
                    'Reward Jitter (+1/-2): ', num2str(params.rewardWaitJitter)];
            
             DrawFormattedText(expWindow,infotext);

             Screen('Flip',expWindow); 
             Screen('Flip',viewWindow); 
        end


    catch ME
        Screen('FinalizeMovie',movie);
        sca
        save(params.dataSaveFile);
        rethrow(ME)

    end
       

function [xPos,yPos] = eyeTrack(xChannel,yChannel,xGain,yGain,xOffset,yOffset) % Get eye position
    coords = DAQ('GetAnalog',[xChannel yChannel]);
    xPos = (coords(1)*xGain)-xOffset;
    yPos = (coords(2)*yGain)-yOffset;
end


function inRect = isInRect(xPos, yPos, rect) % Check to see if eye position is in rectangle
    if (xPos <= rect(3) && xPos >= rect(1) && yPos <= rect(4) && yPos >= rect(2)) % Check to see if the x and y points are in the rectangle
        inRect = true;
    else
        inRect = false;
    end
end

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
    end



            













    


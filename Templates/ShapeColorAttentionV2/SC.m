function [params] = SC(params)
    % Shape Color Paradigm 5.0
    % Stuart J. Duffield September 2022
    % Displays the stimuli from the Monkey Turk experiments
    % Occasiasonally will display a probe to make sure the subject it
    % paying attention. During this probe the animal will be presented with
    % a 4-AFC task, will be rewarded for making the correct choice. In
    % previous versions of the attention task this was a 2-AFC task.
    
    % Set random seed generator. 
    params.seed = rng('shuffle'); % This essentially just makes sure that the seed
    % is different each time. Sets the seed of the rng based on the current
    % time, so every time this is ran it should have a different seed.

    
    %% Initialize Parameters
    KbName('UnifyKeyNames'); % Create common key naming scheme for keyboard
    
    % Run information
    params.complete = false; % Run not completed yet
    
    % Set up save file paths
    params.runExpTime = datestr(now); % Get the time the run occured at.
    params.date_time = strrep(strrep(datestr(datetime),' ','_'),':','_'); % Get the numstring of the time 
    params.dataSaveFile = fullfile(params.dataDir,[params.subject '_' num2str(params.runNum) '_' params.date_time '_Data.mat']); % File to save both run data and eye data
    params.movSaveFile = ['Data/' params.subject '_' num2str(params.runNum) '_' params.date_time '_Movie.mov']; % Create Movie Filename
    params.DMSaveFile = fullfile(params.dataDir,[params.subject '_' num2str(params.runNum) '_' params.date_time '_DM.txt']); % Create Design Matrix Filename
    
    % Set up other screen parameters
    params.jitterFrames = params.FPS/2; % How often do we want the stimuli to jitter? 

    %params.gray = [31 29 47]; % Gray of background
    
    params.gray = [31 29 47];
    params.red = [255 0 0]; % Red color
    params.green = [0 255 0]; % Green color
    params.blue = [0 0 255]; % Blue color
    params.white = [255 255 255]; % White color


    % Load Textures:
    load(fullfile(params.stimDir,'achrom.mat'), 'achrom'); % Achromatic Shapes
    load(fullfile(params.stimDir,'chrom.mat'), 'chrom'); % Chromatic Shapes
    load(fullfile(params.stimDir,'chromBW.mat'), 'chromBW'); % Chromatic Shapes Black and White
    load(fullfile(params.stimDir,'colorcircles.mat'), 'colorcircles'); % Colored Circles



    % Initialize Screens
    Screen('Preference', 'SkipSyncTests', 1); % Skip sync tests
    Screen('Preference', 'VisualDebugLevel', 0); % Don't visually debug
    Screen('Preference', 'Verbosity', 0); % No verbosity
    Screen('Preference', 'SuppressAllWarnings', 1); % Supress all warnings

    [expWindow, expRect] = Screen('OpenWindow', params.expscreen, params.gray); % Open experimenter window
    [viewWindow, viewRect] = Screen('OpenWindow', params.viewscreen, params.gray); % Open viewing window (for subject)
    Screen('BlendFunction', viewWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    Screen('BlendFunction', expWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % Blend function
    
    [xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
    [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen

    stimPix = 6*params.pixPerAngle; % How large the stimulus rectangle will be
    jitterPix = 1*params.pixPerAngle; % How large the jitter will be
    fixPix = 3*params.pixPerAngle; % How large the fixation will be
    distPix = params.choiceDistAngle*params.pixPerAngle; % How far apart the choices will be

    fixCrossDimPix = 10; % Fixation cross arm length
    lineWidthPix = 2; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0]; 
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords]; % Creates the fixation cross
    
    % Make base rectangle and centered rectangle for stimulus presentation
    baseRect = [0 0 stimPix stimPix]; % Size of the texture rect
    sideViewRect = CenterRectOnPointd(baseRect,0.5*stimPix,yCenterExp);
    choiceRightRect = CenterRectOnPointd(baseRect,xCenter+0.5*distPix,yCenter);
    choiceLeftRect = CenterRectOnPointd(baseRect,xCenter-0.5*distPix,yCenter);
    choiceRightRectExp = CenterRectOnPointd(baseRect,xCenterExp+0.5*distPix,yCenterExp);
    choiceLeftRectExp = CenterRectOnPointd(baseRect,xCenterExp-0.5*distPix,yCenterExp);

    % Make base rectangle for fixation circle
    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
    rightFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp+0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choice on the right
    leftFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp-0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choiceo n the left

    % Create Textures
    achromTex = NaN(size(achrom,4),1); % Initialize NaN Vectors
    circleTex = NaN(size(colorcircles,4),1);
    BWTex = NaN(size(chromBW,4),1);
    chromTex = NaN(size(chrom,4),1);
    
    assert(size(achrom,4)==size(colorcircles,4),'The number of images for achromatic shapes and colored circles do not match');
    assert(size(achrom,4)==size(chromBW,4),'The number of images for achromatic shapes and black and white shapes do not match');
    assert(size(achrom,4)==size(chrom,4),'The number of images for achromatic shapes and chromatic shapes do not mathch');

    for jj = 1:size(achrom,4) % Create the textures
        achromTex(jj) = Screen('MakeTexture',viewWindow,achrom(:,:,:,jj));
        circleTex(jj) = Screen('MakeTexture',viewWindow,colorcircles(:,:,:,jj));
        BWTex(jj) = Screen('MakeTexture',viewWindow,chromBW(:,:,:,jj));
        chromTex(jj) = Screen('MakeTexture',expWindow,chrom(:,:,:,jj));
    end

    achromOrder = randsample(length(achromTex),params.blockrepeats); % Order by which achromatic shapes are presented

    while true % run a while loop to make sure that no associated colors and shapes are adjacent
        circleOrder = randsample(length(circleTex),params.blockrepeats); % Order by which colors are presented
        bwOrder = randsample(length(BWTex),params.blockrepeats); % Order by which black and white shapes are presented

        testblockorder = NaN(size(params.blockorder)); % Create a fake matrix to place
        testblockorder(params.blockorder==params.colorCase) = circleOrder; % Fill in circle indices
        testblockorder(params.blockorder==params.bwCase) = bwOrder; % Fill in black and white indices
        diffblockorder = diff(testblockorder); % Check the difference, if associated shapes and colors are adjacent, redraw, else break the while loop
        if ~ismember(0,diffblockorder)
            break
        end
    end
    
    circleOrderNames = params.colors(circleOrder); % What are the names of the colors in order
    bwOrderNames = params.chrom(bwOrder); % What are the names of the chrom shapes in order
    achromOrderNames = params.achrom(achromOrder); % What are the names of the achrom shapes in order
    params.orderNames = strings(size(params.blockorder)); % Initialize ordernames
    params.orderNames(params.blockorder==params.colorCase) = circleOrderNames; % Add colored circles to the ordernames
    params.orderNames(params.blockorder==params.bwCase) = bwOrderNames; % Add chromatic shapes to the ordernames
    params.orderNames(params.blockorder==params.achromCase) = achromOrderNames; % Add achromatic shapes to the ordernames

    % Figure out how many probes and where they are
    remainder = params.numProbes_init/floor(params.numProbes_init)-1; % Get the remainder of the numProbes
    random_comp = rand; % Get a random value between 0 and 1 to compare it against
    if remainder>random_comp
        params.numProbes = ciel(params.numProbes_init); % Round up
    else
        params.numProbes = floor(params.numProbes_init); % Round down
    end

    params.probeIndices = randsample(params.numblocks,params.numProbes); % Get the indices of the probe trials
    params.probeArray = false(1,params.numblocks); % Turn these indices into array form, initialize
    params.probeArray(params.probeIndices) = true; % Turn these indices into array form, finalize

    % Now produce the Design Matrix
    params = createSCDM(params);



    eyePosition = NaN(params.FPS*params.runDur,2); % Set up eyePosition array
    fixation = NaN(params.FPS*params.runDur,1); % Set up fixation array
    leftFixation = NaN(params.FPS*params.runDur,1); % Set up left fixation array
    rightFixation = NaN(params.FPS*params.runDur,1); % Set up right fixation array
    blockTracker = NaN(params.FPS*params.runDur,1); % Set up block tracking array
    juiceOnTracker = NaN(params.FPS*params.runDur,1); % Tracing whether juice is 'on' or not
    timeTracker = NaN(params.FPS*params.runDur,1); % Actually track the time

    % Initialize Randoms
    randDists = rand([params.runDur*params.FPS,1]); % Initialize the matrix storing where the distances of the jitter will be
    randAngles = rand([params.runDur*params.FPS,1]); % Initialize the matrix storing where the angles of the jitter will be

    % Calculate jitter
    jitterDist = round(randDists*jitterPix); % Random number between 0 and maximum number of pixels
    jitterAngle = randAngles*2*pi; % Gives us a random radian
    jitterX = cos(jitterAngle).*jitterDist; % X
    jitterY = sin(jitterAngle).*jitterDist; % Y
    Priority(2) % topPriorityLevel?
    %Priority(9) % Might need to change for windows
    juiceOn = false; % Logical for juice giving
    juiceEndTime = 0; % Initialize the variable that stores when the juice ends
    timeSinceLastJuice = 0; % Initialze the variable that stores how long it has been since the juice turned off
    timeAtLastJuice = 0; % Initialize the variable storing when the juice was last given
    quitNow = false; % Initialize the variable that flags if it is time to quit
    % initialRects = createTiledRects(expRect,length(allTex),4);
    % Begind acutal stimulus presentation 
    try
        movie = Screen('CreateMovie', expWindow, params.movSaveFile,[],[],params.movieFPS); % Open movie file
        Screen('DrawText',expWindow,'Ready',xCenterExp,yCenterExp); % Display 'ready'
        % for i = 1:length(allTex)
        %    Screen('DrawTexture',expWindow,allTex(i),[],initialRects(:,i))
        %    Screen('DrawTexture',viewWindow,allTex(i),[],initialRects(:,i))
        % end
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
        
        flips = params.IFI:params.IFI:params.runDur+10; % Adding a bit of leeway
        flips = flips + GetSecs; % Initialize the timepoints at which the program should flip
        
        tic; % start timing
        startBlockTime = toc; % Start block timer
        blockTime = 0; % Initialize the variable that stores how much block time has passed
        blockIndx = 0; % What block are we in
        frameIdx = 1; % What frame are we in
        achromIndx = 1;
        circleIndx = 1;
        bwIndx = 1;
        correctSideChoices = randi(2,params.numProbes,1); % 1 will be correct choice on left, 2 will be correct choice on right
        sideChoices = zeros(params.numProbes,1); 
        choiceIndx = 0;
        correctChoiceCounter = 0;
        isgray = false;
        circleColor = params.white;


        % Begin Stimulus
           while true
            % Get the time that the block starts
            if blockTime >=params.blocklength*params.TR || frameIdx == 1
                isgray = false; % is it going to be gray? Determined by switch below
                startBlockTime = toc;
                blockIndx = blockIndx+1;
                if blockIndx <= length(params.blockorder)
                    switch params.blockorder(blockIndx) % Setting all the relevant texture info. Really should consolidate this with the code below
                        case params.achromCase % ACh
                            stimTex = achromTex(achromOrder(achromIndx)); % What will be displayed
                            choiceCorrectTex = stimTex; % Correct choice texture
                            unchosenInds = setdiff(achromOrder,achromOrder(achromIndx)); % What was not displayed
                            while true % check to make sure incorrect and correct tex are not the same
                                choiceIncorrectInd = randsample(unchosenInds,1); % What will be shown as the incorrect texture 
                                if achromTex(choiceIncorrectInd) ~= choiceCorrectTex
                                    break
                                end
                            end
                            choiceIncorrectTex = achromTex(choiceIncorrectInd);
                            objectName = params.achrom(achromOrder(achromIndx));
                            achromIndx = achromIndx+1; % Move achrom selection up 1
                            blockType = 'Achromatic Shapes';
                        case params.colorCase % Colored Cirles
                            stimTex = circleTex(circleOrder(circleIndx)); % What will be displayed
                            choiceCorrectTex = BWTex(circleOrder(circleIndx)); % Correct choice texture
                            chromDispTex = chromTex(circleOrder(circleIndx)); % Corresponding chromatic shape
                            unchosenInds = setdiff(circleOrder,circleOrder(circleIndx)); % What was not displayed
                            while true
                                choiceIncorrectInd = randsample(unchosenInds,1); % What will be shown as the incorrect texure
                                if circleTex(choiceIncorrectInd) ~= stimTex
                                    break
                                end
                            end
                            choiceIncorrectTex = BWTex(choiceIncorrectInd);
                            objectName = params.colors(circleOrder(circleIndx));
                            circleIndx = circleIndx+1;
                            blockType = 'Colored Circles';
                        case params.grayCase % Gray
                            isgray = true;
                            blockType = 'Gray';
                        case params.bwCase % Black and White Color Associated Shapes
                            stimTex = BWTex(bwOrder(bwIndx)); % What will be displayed
                            choiceCorrectTex = circleTex(bwOrder(bwIndx)); % Correct choice texture
                            chromDispTex = chromTex(bwOrder(bwIndx)); % Corresponding chromatic shape
                            unchosenInds = setdiff(bwOrder,bwOrder(bwIndx)); % What was not displayed
                            while true
                                choiceIncorrectInd = randsample(unchosenInds,1); % What will be shown as the incorrect texure
                                if circleTex(choiceIncorrectInd) ~= choiceCorrectTex
                                    break
                                end
                            end
                            choiceIncorrectTex = circleTex(choiceIncorrectInd);
                            objectName = params.chrom(bwOrder(bwIndx));
                            bwIndx = bwIndx+1;
                            blockType = 'Black and White Chromatic Shapes';
                    end
                elseif blockIndx > length(params.blockorder)
                    isgray=true;
                    blockType = 'Gray';
                end
                if blockIndx <= length(params.blockorder)
                    if params.probeArray(blockIndx) == 1 && isgray==false && params.choiceSectionDur > 0 % Add one to choice index
                        choiceIndx = choiceIndx+1;
                    end
                end
                if toc >= params.runDur
                    quitNow = true;
                    params.complete = true; % Run completed
                end
                if frameIdx >= params.runDur*params.FPS
                    quitNow = true;
                    params.complete = true; % Run completed
                end
            end
            if toc >= params.runDur
                quitNow = true;
                params.complete = true; % Run completed
            end
            if frameIdx >= params.runDur*params.FPS
                quitNow = true;
                params.complete = true; % Run completed
            end
            if quitNow == true
                Screen('FinalizeMovie', movie);
                sca
                save(params.dataSaveFile);
                disp(['Fixation: ' num2str(sum(fixation,'omitnan')/length(fixation(1:frameIdx,1)))]);
                disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])
                break;
                
            end

            blockTime = toc-startBlockTime;
            blockTracker(frameIdx) = blockIndx; % Store what block we're in
            choices = {'Left','Right'};
            if isgray == true
                choice = 'None';
            elseif params.probeArray(blockIndx) == 1 && params.choiceSectionDur > 0
                choice = choices{correctSideChoices(choiceIndx)};
            else
                choice = 'None';
            end
            
            
            % Collect eye position
            [eyePosition(frameIdx,1),eyePosition(frameIdx,2)] = eyeTrack(params.xChannel,params.yChannel,params.xGain,params.yGain,params.xOffset,params.yOffset);
            fixation(frameIdx,1) = isInCircle(eyePosition(frameIdx,1),eyePosition(frameIdx,2),fixRect);
            
            if fixation(frameIdx,1) == 1
                circleColor = params.green;
            else
                circleColor = params.white;
            end

            if timeSinceLastJuice > params.rewardWaitActual
                startIdx = round(frameIdx-((params.FPS*params.rewardWait)+1));
                if startIdx < 1
                    startIdx = 1;
                elseif startIdx >=frameIdx
                    startIdx = frameIdx - 1;
                end
                if sum(fixation(startIdx:frameIdx),"all",'omitnan') > params.rewardPerf*params.FPS*params.rewardWaitActual
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
                    params.xOffset = params.xOffset + eyePosition(frameIdx,1)-xCenterExp;
                    params.yOffset = params.yOffset + eyePosition(frameIdx,2)-yCenterExp;
                    keyIsDown=0;
                elseif keyCode(KbName('UpArrow')) % Move fixation point up
                    params.yOffset = params.yOffset+params.manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('DownArrow')) % Move fixation point down
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
                elseif keyCode(KbName('z')) % Increase Choice Reward Dur
                    params.choiceRewardDur = params.choiceRewardDur + params.rewardKeyChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('x')) && params.choiceRewardDur > params.rewardKeyChange % Decrease Choice Reward Dur
                    params.choiceRewardDur = params.choiceRewardDur - params.rewardKeyChange;
                    keyIsDown = 0;
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
                elseif keyCode(KbName('w')) && fixPix > params.pixPerAngle/2 % Increase fixation circle
                    fixPix = fixPix - params.pixPerAngle/2; % Shrink fixPix by half a degree of visual angle
                    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                    rightFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp+0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choice on the right
                    leftFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp-0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choiceo n the left
                    keyIsDown=0;
                elseif keyCode(KbName('s')) && fixPix < params.pixPerAngle*10
                    fixPix = fixPix + params.pixPerAngle/2; % Increase fixPix by half a degree of visual angle
                    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                    rightFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp+0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choice on the right
                    leftFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp-0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choiceo n the left
                    keyIsDown=0;
    
                elseif keyCode(KbName('p'))
                    quitNow = true;
                    keyIsDown=0;
                end
            end
            
            
            if blockIndx <= length(params.blockorder)
                blockTimeTotal = params.blocklength*params.TR;
            else
                blockTimeTotal = params.endGrayDur;
            end
            if blockIndx <= length(params.blockorder)
                if params.probeArray(blockIndx) == 1;
                    inProbe = 'Probe Block';
                else
                    inProbe = 'No Probe';
                end
            end

            infotext = ['Time Elapsed: ', num2str(toc), '/', num2str(params.runDur), newline,...
                'Block Time Elapsed: ', num2str(blockTime), '/',num2str(blockTimeTotal), newline,...
                'Block Number: ', num2str(blockIndx), newline,...
                'Fixation Percentage: ', num2str(sum(fixation(1:frameIdx,1))/length(fixation(1:frameIdx,1)*100)), newline,...
                'Correct Choice Side: ', choice, newline,...
                'Block Type: ', blockType,newline,...
                'Object Name: ', char(objectName),newline,...
                inProbe,newline,...
                'Juice: ', juiceSetting,newline,...
                'Juice End Time: ', num2str(juiceEndTime),newline,...
                'Correct Number of Choices: ', num2str(correctChoiceCounter), '/' num2str(choiceIndx), newline,...
                'Choice Reward Duruation (+z/-x): ', num2str(params.choiceRewardDur),newline,...
                'Reward Duration (+c/-v): ', num2str(params.rewardDur),newline,...
                'Reward Wait Time (+b/-n): ', num2str(params.rewardWait),newline,...
                'Actual Reward Wait Time: ', num2str(params.rewardWaitActual),newline,...
                'Reward Jitter (+1/-2): ' num2str(params.rewardWaitJitter)];
               

            DrawFormattedText(expWindow,infotext);

            % Draw associated chromatic shape if BW block or circle block
            if blockIndx <= length(params.blockorder)
                if params.blockorder(blockIndx) == params.bwCase || params.blockorder(blockIndx) == params.colorCase
                    Screen('DrawTexture',expWindow,chromDispTex,[],sideViewRect);
                end
            
            
                if blockTime < params.stimDur*params.TR % In stimulus presentation mode
    
                    if rem(frameIdx,params.jitterFrames) == 1 % Create rectangles for stim draw
                        viewStimRect = CenterRectOnPointd(baseRect, round(xCenter+jitterX(frameIdx)), round(yCenter+jitterY(frameIdx)));
                        expStimRect = CenterRectOnPointd(baseRect, round(xCenterExp+jitterX(frameIdx)), round(yCenterExp+jitterY(frameIdx)));
                    end
    
                    % Draw Stimulus on Framebuffer
                    if isgray == false % Is it not a gray block?
                        Screen('DrawTexture', viewWindow, stimTex,[],viewStimRect);
                        Screen('DrawTexture', expWindow, stimTex,[],expStimRect);  
                    end
    
                    % Draw Fixation Cross on Framebuffer
                    Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                
                    % Draw fixation window on framebuffer
                    Screen('FrameOval', expWindow, circleColor, fixRect);
    
                    % Draw eyetrace on framebuffer
                    Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
                elseif blockTime >= params.stimDur*params.TR && blockTime < (params.stimDur+params.grayDur)*params.TR % Inter event interval
                    % Draw Fixation Cross on Framebuffer
                    Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                
                    % Draw fixation window on framebuffer
                    Screen('FrameOval', expWindow, circleColor, fixRect);
    
                    % Draw eyetrace on framebuffer
                    Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
                
                elseif blockTime >= (params.stimDur+params.grayDur)*params.TR && params.choiceSectionDur > 0 && params.probeArray(blockIndx) == 1 % Choice interval
    
    
    
                    % Draw stimuli
                    if isgray == true
                        % If gray draw fixation cross
                        Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
    
                        % Draw fixation window
                        Screen('FrameOval',expWindow,circleColor,fixRect);
    
                        % Draw Eyetrace
                        Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
                    elseif isgray == false
                        % check to see where fixation is
                        leftFixation(frameIdx) = isInCircle(eyePosition(frameIdx,1),eyePosition(frameIdx,2),leftFixRect);
                        rightFixation(frameIdx) = isInCircle(eyePosition(frameIdx,1),eyePosition(frameIdx,2),rightFixRect);
    
                        % Draw choices
                        if sideChoices(choiceIndx) == 0
                            if correctSideChoices(choiceIndx) == 1 % Left side
                                Screen('DrawTexture',viewWindow,choiceCorrectTex,[],choiceLeftRect);
                                Screen('DrawTexture',viewWindow,choiceIncorrectTex,[],choiceRightRect);
                                Screen('DrawTexture',expWindow,choiceCorrectTex,[],choiceLeftRectExp); 
                                Screen('DrawTexture',expWindow,choiceIncorrectTex,[],choiceRightRectExp);
                                if  leftFixation(frameIdx) == 1 % Turn it green
                                    choiceColorLeft = params.green;
                                else
                                    choiceColorLeft = params.white;
                                end
                                if rightFixation == 1 
                                    choiceColorRight = params.red;
                                else
                                    choiceColorRight = params.white;
                                end
                                % for actual reward processing
                                if sideChoices(choiceIndx) == 0 && sum(leftFixation(frameIdx-(params.choiceDur*params.FPS+1):frameIdx),'all','omitnan') == params.choiceDur*params.FPS
                                    [juiceEndTime, juiceOn] = juice(params.choiceRewardDur,juiceEndTime,toc,juiceOn);
                                    sideChoices(choiceIndx) = 1;
                                    correctChoiceCounter = correctChoiceCounter+1;
                                elseif sideChoices(choiceIndx) == 0 && sum(rightFixation(frameIdx-(params.choiceDur*params.FPS+1):frameIdx),'all','omitnan') == params.choiceDur*params.FPS
                                    sideChoices(choiceIndx) = 2;
                                end
        
                            elseif correctSideChoices(choiceIndx) == 2 % Right side
                                Screen('DrawTexture',viewWindow,choiceCorrectTex,[],choiceRightRect);
                                Screen('DrawTexture',viewWindow,choiceIncorrectTex,[],choiceLeftRect);
                                Screen('DrawTexture',expWindow,choiceCorrectTex,[],choiceRightRectExp); 
                                Screen('DrawTexture',expWindow,choiceIncorrectTex,[],choiceLeftRectExp); 
                                if leftFixation(frameIdx) == 1 
                                    choiceColorLeft = params.red;
                                else
                                    choiceColorLeft = params.white;
                                end
                                if rightFixation(frameIdx) == 1 
                                    choiceColorRight = params.green;
                                else
                                    choiceColorRight = params.white;
                                end
                                if sideChoices(choiceIndx) == 0 && sum(leftFixation(frameIdx-(params.choiceDur*params.FPS+1):frameIdx),'all','omitnan') == params.choiceDur*params.FPS
                                    sideChoices(choiceIndx) = 1;
                                elseif sideChoices(choiceIndx) == 0 && sum(rightFixation(frameIdx-(params.choiceDur*params.FPS+1):frameIdx),'all','omitnan') == params.choiceDur*params.FPS
                                    [juiceEndTime, juiceOn] = juice(params.choiceRewardDur,juiceEndTime,toc,juiceOn);
                                    sideChoices(choiceIndx) = 2;
                                    correctChoiceCounter = correctChoiceCounter+1;
                                    params.choiceRewardDur = params.choiceRewardDur;
    
    
                                end
                            end
                         
                        end
                        % Draw fixation windows on framebuffer
                        Screen('FrameOval',expWindow, choiceColorRight, rightFixRect);
                        Screen('FrameOval',expWindow,choiceColorLeft, leftFixRect);
    
                        % Draw eyetrace on framebuffer
                        Screen('DrawDots', expWindow, eyePosition(frameIdx,:)',5);
                    
                    end
                else
                    Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
    
                    % Draw fixation window
                    Screen('FrameOval',expWindow,circleColor,fixRect);
    
                    % Draw Eyetrace
                    Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
                end
           else
                Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);

                % Draw fixation window
                Screen('FrameOval',expWindow,circleColor,fixRect);

                % Draw Eyetrace
                Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            end
            % add this frame to the movie
            if rem(frameIdx,params.FPS/params.movieFPS)==1
                Screen('AddFrameToMovie',expWindow,[],[],movie)
            end

            % Flip
            [timestamp] = Screen('Flip', viewWindow, flips(frameIdx));
            [timestamp2] = Screen('Flip', expWindow, flips(frameIdx));
            
            
            [juiceEndTime,juiceOn] = juice(0,juiceEndTime, toc,juiceOn);
            
            
            frameIdx = frameIdx+1;
            if frameIdx >= params.runDur*params.FPS
                quitNow = true
            end
            % Store any other variables:
            juiceOnTracker(frameIdx) = juiceOn; % Is the juice on at this frame?
            timeTracker(frameIdx) = toc; % What is the time at this frame?
            if quitNow == true
                Screen('FinalizeMovie', movie);
                sca
                break;
            end
            end
    catch error
        rethrow(error)
        save(params.dataSaveFile);
        disp(['Fixation: ' num2str(sum(fixation,'omitnan')/length(fixation(1:frameIdx,1)))]);
        disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])

    end % End of stim presentation
    save(params.dataSaveFile);
    disp(['Fixation: ' num2str(sum(fixation,'omitnan')/length(fixation(1:frameIdx,1)))]);
    disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])
    close all;

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
        

    function [xPos,yPos] = eyeTrack(xChannel,yChannel,xGain,yGain,xOffset,yOffset)
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



            













    



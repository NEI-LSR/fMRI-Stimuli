function SC(subject, counterbalance_indx, run)
    % Shape Color Paradigm 3.0
    % Stuart J. Duffield March 2022
    % Displays the stimuli from the Monkey Turk experiments in blocks.
    % Here for each block one of 7 stimuli (or the original 14) will be
    % displayed. At the end of the block there will be a choice
    
    % Set random seed generator. 
    seed = rng('shuffle'); % This essentially just makes sure that the seed
    % is different each time. Sets the seed of the rng based on the current
    % time, so every time this is ran it should have a different seed.

    % Parameters you care about:
    repeat_blockorder = 1;
    rewardDur = 0.02; % seconds
    rewardWait = 0.75; % seconds
    rewardWaitChange = 0.01;
    rewardPerf = .75; % 90% fixation to get reward
    choiceDur = 0.7; % Needs to fixate at choice for this time period before getting reward
    choiceRewardDur = 0.3;
    rewardKeyChange = 0.01;
    choiceRewardIncrement = 0;
    exactDur = 1374; % Need to manually calculate
    exactDur = ceil(exactDur);
    endGrayDur = 30; % End gray duration, in seconds
    LumSetting = 3; % 1 is high luminance colors and shapes, 2 is low, 3 is all
    choiceDistAngle = 10; % The presented choices will be seperated by 10 degrees of visual angle
    stimDur = 5; % Number of TRs the block stimulus will be shown
    grayDur = 2; % Number of TRs the inter-event interval will be on, showing gray
    choiceSectionDur = 1; % Number of TRs the choice will be on
    blocklength = stimDur+grayDur+choiceSectionDur; % Number of TRs per block
    movieFPS = 10;
    manualMovementPix = 10;
    % cases
    achromCase = 1; 
    colorCase = 2;
    grayCase = 3;
    bwCase = 4;
    % Initialize DAQ
    DAQ('Debug',false);
    DAQ('Init');
    xGain = -500;
    yGain = 700;
    xOffset = -203;
    yOffset = -272;
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
    date_time=strrep(strrep(datestr(datetime),' ','_'),':','_') % Get the numstring of the time 
    dataSaveFile = ['Data/' subject '_' num2str(run) '_' date_time '_Data.mat']; % File to save both run data and eye data
    movSaveFile = ['Data/' subject '_' num2str(run) '_' date_time '_Movie.mov']; % Create Movie Filename

    % Refresh rate of monitors:
    fps = 30;
    jitterFrames = fps/2;
    ifi = 1/fps;

    % Timing Data:
    TR = 3; % TR length

    % Gray of the background:
    gray = [31 29 47]; 
    %gray = [118,98,128];
    % Other colors
    red = [255 0 0];
    green = [0 255 0];
    blue = [0 0 255];
    white = [255 255 255];

    % Load in block orders
    blockorders = csvread('blockorder.csv'); % This is produced from the counterbalance script @kurt braunlich wrote for me
    blockorder = blockorders(counterbalance_indx,:); % Get the blockorder used for this run
    blockorder=repmat(blockorder,1,repeat_blockorder);
    if LumSetting == 3
        blockorder=repmat(blockorder,1,2); % Repeat blockorder for double length
    end
    % Exact Duration

    runDur = ceil(TR*blocklength*length(blockorder)+endGrayDur); % Calculating this to compare to exact duration

    %exactDur = runDur;
    disp(['Run dur:' num2str(runDur)])
    if runDur ~= exactDur % Ya gotta check or else you waste your scan time
        disp(['Run dur:' num2str(runDur)])
        disp(['ExactDur: ' num2str(exactDur)])
        error('Run duration calculated from run parameters does not match hardcoded run duration length.')
    end

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 1; 
    viewscreen = 2;

    % Load Textures:
    load([stimDir '/' 'achrom.mat'], 'achrom'); % Achromatic Shapes
    load([stimDir '/' 'chrom.mat'], 'chrom'); % Chromatic Shapes
    load([stimDir '/' 'chromBW.mat'], 'chromBW'); % Chromatic Shapes Black and White
    load([stimDir '/' 'colorcircles.mat'], 'colorcircles'); % Colored Circles

    if LumSetting == 1 % High luminance
        achrom = achrom(:,:,:,1:2:end);
        chromBW = chromBW(:,:,:,1:2:end);
        colorcircles = colorcircles(:,:,:,1:2:end);
        chrom = chrom(:,:,:,1:2:end);
        disp('High luminance conditions will be displayed')
    elseif LumSetting == 2 % Low luminance
        achrom = achrom(:,:,:,2:2:end);
        chromBW = chromBW(:,:,:,2:2:end);
        colorcircles = colorcircles(:,:,:,2:2:end);
        chrom = chrom(:,:,:,2:2:end);
        disp('Low luminance conditions will be displayed')
    elseif LumSetting == 3 % Both
        disp('All conditions will be displayed')
    end

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
    jitterPix = 1*pixPerAngle; % How large the jitter will be
    fixPix = 3*pixPerAngle; % How large the fixation will be
    distPix = choiceDistAngle*pixPerAngle; % How far apart the choices will be

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

    for i = 1:size(achrom,4) % Create the textures
        achromTex(i) = Screen('MakeTexture',viewWindow,achrom(:,:,:,i));
        circleTex(i) = Screen('MakeTexture',viewWindow,colorcircles(:,:,:,i));
        BWTex(i) = Screen('MakeTexture',viewWindow,chromBW(:,:,:,i));
        chromTex(i) = Screen('MakeTexture',expWindow,chrom(:,:,:,i));
    end
    achromTex = repmat(achromTex,repeat_blockorder,1);
    circleTex = repmat(circleTex,repeat_blockorder,1);
    BWTex = repmat(BWTex,repeat_blockorder,1);
    chromTex = repmat(chromTex,repeat_blockorder,1);

    allTex = [achromTex; circleTex; BWTex; chromTex];
    achromOrder = randperm(length(achromTex)); % Order by which achromatic shapes are presented
    circleOrder = randperm(length(circleTex)); % Order by which colors are presented
    bwOrder = randperm(length(BWTex)); % Order by which black and white shapes are presented
    stimulus_order = []; % Save this for later
    

    eyePosition = NaN(fps*exactDur,2);
    fixation = NaN(fps*exactDur,1);
    leftFixation = NaN(fps*exactDur,1);
    rightFixation = NaN(fps*exactDur,1);
    blockTracker = NaN(fps*exactDur,1);
    juiceOnTracker = NaN(fps*exactDur,1); % Tracing whether juice is 'on' or not
    timeTracker = NaN(fps*exactDur,1); % Actually track the time

    % Initialize Randoms
    randDists = rand([exactDur*fps,1]);
    randAngles = rand([exactDur*fps,1]);

    % Calculate jitter
    jitterDist = round(randDists*jitterPix); % Random number between 0 and maximum number of pixels
    jitterAngle = randAngles*2*pi; % Gives us a random radian
    jitterX = cos(jitterAngle).*jitterDist; % X
    jitterY = sin(jitterAngle).*jitterDist; % Y
    Priority(2) % topPriorityLevel?
    %Priority(9) % Might need to change for windows
    juiceOn = false; % Logical for juice giving
    juiceEndTime = 0;
    timeSinceLastJuice = 0;
    timeAtLastJuice = 0;
    quitNow = false;
    initialRects = createTiledRects(expRect,length(allTex),4);
    % Begind acutal stimulus presentation 
    try
        movie = Screen('CreateMovie', expWindow, movSaveFile,[],[],movieFPS);
        Screen('DrawText',expWindow,'Ready',xCenterExp,yCenterExp);
        for i = 1:length(allTex)
            Screen('DrawTexture',expWindow,allTex(i),[],initialRects(:,i))
            Screen('DrawTexture',viewWindow,allTex(i),[],initialRects(:,i))
        end
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
        
        flips = ifi:ifi:exactDur+10; % Adding a bit of leeway
        flips = flips + GetSecs;
        
        tic; % start timing
        startBlockTime = toc; % start block timer
        blockTime = 0;
        blockIndx = 0; % What block are we in
        frameIdx = 1; % What frame are we in
        achromIndx = 1;
        circleIndx = 1;
        bwIndx = 1;
        correctSideChoices = randi(2,length(blockorder(blockorder~=grayCase)),1); % 1 will be correct choice on left, 2 will be correct choice on right
        sideChoices = zeros(length(blockorder(blockorder~=grayCase)),1); 
        choiceIndx = 0;
        correctChoiceCounter = 0;
        isgray = false;
        circleColor = white;


        % Begin Stimulus
           while true
            % Get the time that the block starts
            if blockTime >=blocklength*TR | frameIdx == 1;
                isgray = false; % is it going to be gray? Determined by switch below
                startBlockTime = toc;
                blockIndx = blockIndx+1;
                if blockIndx <= length(blockorder)
                    switch blockorder(blockIndx) % Setting all the relevant texture info. Really should consolidate this with the code below
                        case achromCase % ACh
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
                            achromIndx = achromIndx+1; % Move achrom selection up 1
                            blockType = 'Achromatic Shapes';
                        case colorCase % Colored Cirles
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
                            circleIndx = circleIndx+1;
                            blockType = 'Colored Circles';
                        case grayCase % Gray
                            isgray = true;
                            blockType = 'Gray';
                        case bwCase % Black and White Color Associated Shapes
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
                            bwIndx = bwIndx+1;
                            blockType = 'Black and White Chromatic Shapes';
                    end
                elseif blockIndx > length(blockorder)
                    isgray=true;
                    blockType = 'Gray';
                end

                if isgray==false && choiceSectionDur > 0 % Add one to choice index
                    choiceIndx = choiceIndx+1;
                end
                if toc >= exactDur
                    quitNow = true;
                end
                if frameIdx >= exactDur*fps;
                    quitNow = true;
                end
            end
            if toc >= exactDur
                quitNow = true;
            end
            if frameIdx >= exactDur*fps;
                quitNow = true;
            end
            if quitNow == true
                Screen('FinalizeMovie', movie);
                sca
                save(dataSaveFile);
                disp(['Fixation: ' num2str(sum(fixation)/length(fixation(1:frameIdx,1)))]);
                disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])
                break;
                
            end

            blockTime = toc-startBlockTime;
            blockTracker(frameIdx) = blockIndx; % Store what block we're in
            choices = {'Left','Right'};
            if isgray == true
                choice = 'None';
            else
                if choiceSectionDur > 0 
                    choice = choices{correctSideChoices(choiceIndx)};
                else
                    choice = NaN;
                end
            end
            
            
            % Collect eye position
            [eyePosition(frameIdx,1),eyePosition(frameIdx,2)] = eyeTrack(xChannel,yChannel,xGain,yGain,xOffset,yOffset);
            fixation(frameIdx,1) = isInCircle(eyePosition(frameIdx,1),eyePosition(frameIdx,2),fixRect);
            
            if fixation(frameIdx,1) == 1
                circleColor = green;
            else
                circleColor = white;
            end

            if timeSinceLastJuice > rewardWait
                startIdx = round(frameIdx-((fps*rewardWait)+1));
                if startIdx < 1
                    startIdx = 1;
                elseif startIdx >=frameIdx
                    startIdx = frameIdx - 1;
                end
                if sum(fixation(startIdx:frameIdx),"all",'omitnan') > rewardPerf*fps*rewardWait
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
            if keyIsDown == 1
                if keyCode(KbName('r')) % Recenter
                    xOffset = xOffset + eyePosition(frameIdx,1)-xCenterExp;
                    yOffset = yOffset + eyePosition(frameIdx,2)-yCenterExp;
                    keyIsDown=0;
                elseif keyCode(KbName('UpArrow')) % Move fixation point up
                    yOffset = yOffset+manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('DownArrow')) % Move fixation point down
                    yOffset = yOffset-manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('LeftArrow'))
                    xOffset = xOffset+manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('RightArrow'))
                    xOffset = xOffset-manualMovementPix;
                    keyIsDown=0;
                elseif keyCode(KbName('j')) % Juice
                    [juiceEndTime,juiceOn]=juice(rewardDur,juiceEndTime,toc,juiceOn);
                    keyIsDown=0;
                elseif keyCode(KbName('z')) % Increase Choice Reward Dur
                    choiceRewardDur = choiceRewardDur + rewardKeyChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('x')) && choiceRewardDur > rewardKeyChange % Decrease Choice Reward Dur
                    choiceRewardDur = choiceRewardDur - rewardKeyChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('c'))
                    rewardDur = rewardDur + rewardKeyChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('v')) && rewardDur > rewardKeyChange
                    rewardDur = rewardDur - rewardKeyChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('b'))
                    rewardWait = rewardWaitChange + rewardWait;
                    keyIsDown = 0;
                elseif keyCode(KbName('n')) && rewardWait > rewardWaitChange
                    rewardWait = rewardWait-rewardWaitChange;
                    keyIsDown = 0;
                elseif keyCode(KbName('w')) && fixPix > pixPerAngle/2 % Increase fixation circle
                    fixPix = fixPix - pixPerAngle/2; % Shrink fixPix by half a degree of visual angle
                    baseFixRect = [0 0 fixPix fixPix]; % Size of the fixation circle
                    fixRect = CenterRectOnPointd(baseFixRect, xCenterExp, yCenterExp); % We center the fixation rectangle on the center of the screen
                    rightFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp+0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choice on the right
                    leftFixRect = CenterRectOnPointd(baseFixRect*2, xCenterExp-0.5*distPix, yCenterExp); % Area of fixation that can be looked at for choiceo n the left
                    keyIsDown=0;
                elseif keyCode(KbName('s')) && fixPix < pixPerAngle*10
                    fixPix = fixPix + pixPerAngle/2; % Increase fixPix by half a degree of visual angle
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
            
            
            
            infotext = ['Time Elapsed: ', num2str(toc), '/', num2str(exactDur), newline,...
                'Block Time Elapsed: ', num2str(blockTime), '/',num2str(blocklength*TR), newline,...
                'Block Number: ', num2str(blockIndx), newline,...
                'Fixation Percentage: ', num2str(sum(fixation(1:frameIdx,1))/length(fixation(1:frameIdx,1)*100)), newline,...
                'Correct Choice Side: ', choice, newline,...
                'Block Type: ', blockType,newline,...
                'Juice: ', juiceSetting,newline,...
                'Juice End Time: ', num2str(juiceEndTime),newline,...
                'Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx), newline,...
                'Choice Reward Duruation (+z/-x): ' num2str(choiceRewardDur),newline,...
                'Reward Duration (+c/-v): ' num2str(rewardDur),newline,...
                'Reward Wait Time (+b/-n): ' num2str(rewardWait)];
               

            DrawFormattedText(expWindow,infotext);

            % Draw associated chromatic shape if BW block or circle block
            if blockIndx <= length(blockorder)
                if blockorder(blockIndx) == bwCase || blockorder(blockIndx) == colorCase
                    Screen('DrawTexture',expWindow,chromDispTex,[],sideViewRect);
                end
            end

            if blockTime < stimDur*TR % In stimulus presentation mode

                if rem(frameIdx,jitterFrames) == 1 % Create rectangles for stim draw
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
            elseif blockTime >= stimDur*TR && blockTime < (stimDur+grayDur)*TR % Inter event interval
                % Draw Fixation Cross on Framebuffer
                Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
            
                % Draw fixation window on framebuffer
                Screen('FrameOval', expWindow, circleColor, fixRect);

                % Draw eyetrace on framebuffer
                Screen('DrawDots',expWindow, eyePosition(frameIdx,:)',5);
            elseif blockTime >= (stimDur+grayDur)*TR && choiceSectionDur > 0 % Choice interval



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
                                choiceColorLeft = [0 255 0];
                            else
                                choiceColorLeft = [255 255 255];
                            end
                            if rightFixation == 1 
                                choiceColorRight = [255 0 0];
                            else
                                choiceColorRight = [255 255 255];
                            end
                            % for actual reward processing
                            if sideChoices(choiceIndx) == 0 && sum(leftFixation(frameIdx-(choiceDur*fps+1):frameIdx),'all','omitnan') == choiceDur*fps
                                [juiceEndTime, juiceOn] = juice(choiceRewardDur,juiceEndTime,toc,juiceOn);
                                sideChoices(choiceIndx) = 1;
                                correctChoiceCounter = correctChoiceCounter+1;
                            elseif sideChoices(choiceIndx) == 0 && sum(rightFixation(frameIdx-(choiceDur*fps+1):frameIdx),'all','omitnan') == choiceDur*fps
                                sideChoices(choiceIndx) = 2;
                            end
    
                        elseif correctSideChoices(choiceIndx) == 2 % Right side
                            Screen('DrawTexture',viewWindow,choiceCorrectTex,[],choiceRightRect);
                            Screen('DrawTexture',viewWindow,choiceIncorrectTex,[],choiceLeftRect);
                            Screen('DrawTexture',expWindow,choiceCorrectTex,[],choiceRightRectExp); 
                            Screen('DrawTexture',expWindow,choiceIncorrectTex,[],choiceLeftRectExp); 
                            if leftFixation(frameIdx) == 1 
                                choiceColorLeft = [255 0 0];
                            else
                                choiceColorLeft = [255 255 255];
                            end
                            if rightFixation(frameIdx) == 1 
                                choiceColorRight = [0 255 0];
                            else
                                choiceColorRight = [255 255 255];
                            end
                            if sideChoices(choiceIndx) == 0 && sum(leftFixation(frameIdx-(choiceDur*fps+1):frameIdx),'all','omitnan') == choiceDur*fps
                                sideChoices(choiceIndx) = 1;
                            elseif sideChoices(choiceIndx) == 0 && sum(rightFixation(frameIdx-(choiceDur*fps+1):frameIdx),'all','omitnan') == choiceDur*fps
                                [juiceEndTime, juiceOn] = juice(choiceRewardDur,juiceEndTime,toc,juiceOn)
                                sideChoices(choiceIndx) = 2;
                                correctChoiceCounter = correctChoiceCounter+1;
                                choiceRewardDur = choiceRewardDur+choiceRewardIncrement;


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

            % add this frame to the movie
            % ALSO SAVE
            if rem(frameIdx,fps/movieFPS)==1
                Screen('AddFrameToMovie',expWindow,[],[],movie)
                %save(dataSaveFile);
            end

            % Flip
            [timestamp] = Screen('Flip', viewWindow, flips(frameIdx));
            [timestamp2] = Screen('Flip', expWindow, flips(frameIdx));
            
            
            [juiceEndTime,juiceOn] = juice(0,juiceEndTime, toc,juiceOn);
            
            
            frameIdx = frameIdx+1;
            if frameIdx >= exactDur*fps
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
        save(dataSaveFile);
        disp(['Fixation: ' num2str(sum(fixation,'omitnan')/length(fixation(1:frameIdx,1)))]);
        disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])

    end % End of stim presentation
    save(dataSaveFile);
    disp(['Fixation: ' num2str(sum(fixation,'omitnan')/length(fixation(1:frameIdx,1)))]);
    disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])

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
    
    function rects = createTiledRects(arearect,numRects,rows)
        totwidth = arearect(3)-arearect(1);
        totheight = arearect(4)-arearect(2);
        stimPerRow = ceil(numRects/rows);
        widths = totwidth/stimPerRow;
        heights = totheight/rows;
        rect_base = [0 0 widths heights];
        centers_x = (arearect(1)+widths/2):widths:arearect(3);
        centers_y = (arearect(2)+heights/2):heights:arearect(4);
        rects = NaN(4,numRects);
        for i = 1:rows
            for j = 1:stimPerRow
                k = (i-1)*stimPerRow+j;
                rects(:,k) = CenterRectOnPointd(rect_base,centers_x(j),centers_y(i));
            end
        end
    end



close all;
end



            













    



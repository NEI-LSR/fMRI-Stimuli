function [params] = SC(params)
    % Shape Color Paradigm 5.0
    % Stuart J. Duffield December 2022
    % Displays the stimuli from the Monkey Turk experiments
    % Occasiasonally will display a probe to make sure the subject it
    % paying attention. This probe is a 4-AFC task, for which a correct
    % response results in a reward. Previous versions of the attention task
    % had a 2-AFC task. The 4-AFC resembles the final tablet task the
    % animals were trained on.
    
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
    params.sessionDate = datestr(now,'yyyy-mm-dd');
    params.date_time = strrep(strrep(datestr(datetime),' ','_'),':','_'); % Get the numstring of the time 
    nameInfo = [params.subject '_Run_' num2str(params.runNum) '_IMA_' num2str(params.IMA) '_' params.date_time];
    params.dataSaveFile = fullfile(params.dataDir,[nameInfo '_Data.mat']); % File to save both run data and eye data
    params.movSaveFile = ['Data/' nameInfo '_Movie.mov']; % Create Movie Filename
    params.DMSaveFile = fullfile(params.dataDir,[nameInfo '_DM.txt']); % Create Design Matrix Filename
    params.summaryTableSaveFile = fullfile(params.resultsDir,[nameInfo '_Results.csv']); % Create results table filename
    params.eyeTraceSaveFile = fullfile(params.resultsDir,[nameInfo '_eyeDistance.png']); % Create eyetrace filename
    params.eyeTraceDistanceDMSaveFile = fullfile(params.resultsDir,[nameInfo '_eyeDistance.csv']); % Create eye distance csv
    params.eyeTraceFixationDMSaveFile = fullfile(params.resultsDir,[nameInfo '_eyeFixation.csv']); % Create eye distance csv

    % Set up other screen parameters
    params.jitterFrames = params.FPS/2; % How often do we want the stimuli to jitter? 
    
    params.gray = [31 29 47];% [103    87   125]; % The gray of the background. Very important!
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

    params.stimPix = 6*params.pixPerAngle; % How large the stimulus rectangle will be
    params.jitterPix = 1*params.pixPerAngle; % How large the jitter will be
    params.fixPix = 3*params.pixPerAngle; % How large the params.fixation circle will be
    params.distPix = params.choiceDistAngle*params.pixPerAngle; % How far apart the choices will be

    params.fixCrossDimPix = 10; % params.fixation cross arm length
    params.lineWidthPix = 2; % params.fixation cross arm thickness
    params.xCoords = [-params.fixCrossDimPix params.fixCrossDimPix 0 0]; 
    params.yCoords = [0 0 -params.fixCrossDimPix params.fixCrossDimPix];
    params.allCoords = [params.xCoords; params.yCoords]; % Creates the params.fixation cross
    
    % Make base rectangle and centered rectangle for stimulus presentation
    params.baseRect = [0 0 params.stimPix params.stimPix]; % Size of the texture rect
    params.sideViewRect = CenterRectOnPointd(params.baseRect,0.5*params.stimPix,yCenterExp); % Create side view rectangle to show the full colored stimulus/achromatic stimulus
    
    % Premake these variables to prevent error
    viewStimRect = CenterRectOnPointd(params.baseRect, xCenter, yCenter);
    expStimRect = CenterRectOnPointd(params.baseRect, xCenterExp, yCenterExp);
    
    % Make choice rects
    params.horzDist = cos(deg2rad(45))*params.distPix; % Calculate the horizontal distance
    params.vertDist = sin(deg2rad(45))*params.distPix; % Calculate the vertical distance
    params.choiceUpperRightRect = CenterRectOnPointd(params.baseRect,xCenter+params.horzDist,yCenter-params.vertDist); % Create upper right choice rectangle (Index 1, clockwise)
    params.choiceLowerRightRect = CenterRectOnPointd(params.baseRect,xCenter+params.horzDist,yCenter+params.vertDist); % Create lower right choice rectangle (Index 2, clockwise)
    params.choiceLowerLeftRect = CenterRectOnPointd(params.baseRect,xCenter-params.horzDist,yCenter+params.vertDist); % Create lower left choice rectangle (Index 3, clockwise)
    params.choiceUpperLeftRect = CenterRectOnPointd(params.baseRect,xCenter-params.horzDist,yCenter-params.vertDist); % Create upper left choice rectangle (Index 4, clockwise)
    
    % Now for the experimenter view for choice rects
    params.choiceUpperRightRectExp = CenterRectOnPointd(params.baseRect,xCenterExp+params.horzDist,yCenterExp-params.vertDist); % Create upper right choice rectangle (Index 1, clockwise)
    params.choiceLowerRightRectExp = CenterRectOnPointd(params.baseRect,xCenterExp+params.horzDist,yCenterExp+params.vertDist); % Create lower right choice rectangle (Index 2, clockwise)
    params.choiceLowerLeftRectExp = CenterRectOnPointd(params.baseRect,xCenterExp-params.horzDist,yCenterExp+params.vertDist); % Create lower left choice rectangle (Index 3, clockwise)
    params.choiceUpperLeftRectExp = CenterRectOnPointd(params.baseRect,xCenterExp-params.horzDist,yCenterExp-params.vertDist); % Create upper left choice rectangle (Index 4, clockwise)
    
    params.choiceColors = [params.white;params.white;params.white;params.white]; % The colors, by row, of each params.fixation circle

    % Make base rectangle for params.fixation circle
    params.baseFixRect = [0 0 params.fixPix params.fixPix]; % Size of the params.fixation circle
    params.fixRect = CenterRectOnPointd(params.baseFixRect, xCenterExp, yCenterExp); % We center the params.fixation rectangle on the center of the screen
    params.fixRectMult = 1.5;
    params.fixUpperRightRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp+params.horzDist,yCenterExp-params.vertDist); % Create upper FixRect choice rectangle (Index 1, clockwise)
    params.fixLowerRightRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp+params.horzDist,yCenterExp+params.vertDist); % Create lower right choice rectangle (Index 2, clockwise)
    params.fixLowerLeftRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp-params.horzDist,yCenterExp+params.vertDist); % Create lower left choice rectangle (Index 3, clockwise)
    params.fixUpperLeftRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp-params.horzDist,yCenterExp-params.vertDist); % Create upper left choice rectangle (Index 4, clockwise)

    % To make indexing these rectangles possible:
    params.fixRects = {params.fixUpperRightRect,params.fixLowerRightRect,params.fixLowerLeftRect,params.fixUpperLeftRect}; % Cell array of params.fixation choice rects, this needs to be repeated later in the main code for updating
    params.choiceRects = {params.choiceUpperRightRect,params.choiceLowerRightRect,params.choiceLowerLeftRect,params.choiceUpperLeftRect}; % Cell array of choice rects
    params.choiceRectsExp = {params.choiceUpperRightRectExp,params.choiceLowerRightRectExp,params.choiceLowerLeftRectExp,params.choiceUpperLeftRectExp}; % Cell array of choice rects, experimenter side

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
    
    achromOrder = params.stimIndex(params.stimorder(params.blockorder==params.achromCase)); % Order by which achromatic shapes are presented (should be empty in this paradigm)
    circleOrder = params.stimIndex(params.stimorder(params.blockorder==params.colorCase)); % Order by which colors are presented
    bwOrder = params.stimIndex(params.stimorder(params.blockorder==params.bwCase)); % Order by which the chromatic shapes are presented

    achromList = params.stimIndex; % Give a list of numbers from one to the number of achromatic textures
    circleList = params.stimIndex; % Give a list of numbers from one to the number of circle textures
    bwList = params.stimIndex; % Give a list of numbers from one to the number of black and white textures

    params.circleOrderNames = params.colors(circleOrder); % What are the names of the colors in order
    params.bwOrderNames = params.chrom(bwOrder); % What are the names of the chrom shapes in order
    params.achromOrderNames = params.achrom(achromOrder); % What are the names of the achrom shapes in order
    params.orderNames = strings(size(params.blockorder)); % Initialize ordernames
    params.orderNames(params.blockorder==params.colorCase) = params.circleOrderNames; % Add colored circles to the ordernames
    params.orderNames(params.blockorder==params.bwCase) = params.bwOrderNames; % Add chromatic shapes to the ordernames
    params.orderNames(params.blockorder==params.achromCase) = params.achromOrderNames; % Add achromatic shapes to the ordernames
    
    params.blockNames = strings(size(params.blockorder)); % Initialize block names
    params.blockNames(params.blockorder==params.colorCase) = "Colors"; 
    params.blockNames(params.blockorder==params.bwCase) = "Chromatic";
    params.blockNames(params.blockorder==params.achromCase) = "Achromatic";

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



    params.eyePosition = NaN(params.FPS*params.runDur,2); % Set up eyePosition array
    params.fixation = NaN(params.FPS*params.runDur,1); % Set up fixation array
    params.choiceFixation = NaN(params.FPS*params.runDur,4); % Set up choice fixation array, first column for upper right fixation, second lower right, third lower left, fourth upper left
    params.blockTracker = NaN(params.FPS*params.runDur,1); % Set up block tracking array
    params.subBlockTracker = strings(params.FPS*params.runDur,1); % Set up sub-block tracking array, for stim, gray, choice, etc
    params.juiceOnTracker = NaN(params.FPS*params.runDur,1); % Tracing whether juice is 'on' or not
    params.timeTracker = NaN(params.FPS*params.runDur,1); % Actually track the time

    % Initialize Randoms
    randDists = rand([params.runDur*params.FPS,1]); % Initialize the matrix storing where the distances of the jitter will be
    randAngles = rand([params.runDur*params.FPS,1]); % Initialize the matrix storing where the angles of the jitter will be

    % Calculate jitter
    jitterDist = round(randDists*params.jitterPix); % Random number between 0 and maximum number of pixels
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
        % for i = 1:length(allTex) % For drawing all stimuli
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
        achromIndx = 1; % What is the index number of the achromatic block
        circleIndx = 1; % What is the index number of the color block
        bwIndx = 1; % What is the index number of the chromatic block
        params.correctSideChoices = randi(4,params.numProbes,1); % 1 will be correct choice on upper right, 2 will be correct choice on lower right, 3 will be correct choice on lower left, 4 will be correct choice on upper left
        params.choiceStimuli = zeros(params.numProbes,4); % What were all the stimuli shown?
        params.choiceStimuliNames = strings(params.numProbes,4); % What are the names of the stimuli shown
        params.correctChoiceStimuliNames = strings(params.numProbes,1); % What are the names of the correct stimuli choices
        params.sideChoices = zeros(params.numProbes,1); % What was chosen? 
        choiceIndx = 0; % How many choices have there been?
        correctChoiceCounter = 0; % How many correct choices were there
        isgray = false; % Is it gray
        circleColor = params.white; % What is the fixation circle color


        % Begin Stimulus
        while true
            % Get the time that the block starts
            if frameIdx == 1 && params.startGrayDur > 0
                startBlockTime = toc;
                isgray = true;
                blockType = 'Start Gray';
                objectName = 'None';
            elseif toc > params.startGrayDur
                if blockIndx == 0 || blockTime >=params.blocklength*params.TR
                    startBlockTime = toc;
                    blockIndx = blockIndx+1;
                    isgray = false; % is it going to be gray? Determined by switch below

              
                    if blockIndx <= length(params.blockorder)
                        if params.probeArray(blockIndx) == 1 && isgray==false && params.choiceSectionDur > 0 % Add one to choice index
                            choiceIndx = choiceIndx+1;
                        end
                        switch params.blockorder(blockIndx) % Setting all the relevant texture info. Really should consolidate this with the code below
                            case params.achromCase % ACh
                                choiceCorrectInd = achromOrder(achromIndx); % What is the index of the correct choice
                                stimTex = achromTex(achromOrder(achromIndx)); % What will be displayed
                                unchosenInds = setdiff(achromList,achromOrder(achromIndx)); % What was not displayed, as list indexes (not of the textures)
                                choiceIncorrectInds = randsample(unchosenInds,3); % What will be incorrect choices, as list indexes (not of the textures)
    
                                if params.probeArray(blockIndx) == 1 % Is it a choice block?
                                    params.choiceStimuli(choiceIndx,params.correctSideChoices(choiceIndx)) = choiceCorrectInd;
                                    params.choiceStimuli(choiceIndx,params.choiceStimuli(choiceIndx,:) == 0) = choiceIncorrectInds;
                                    params.choiceStimuliNames(choiceIndx,:) = params.achrom(params.choiceStimuli(choiceIndx,:));
                                    params.correctChoiceStimuliNames(choiceIndx) = params.achrom(choiceCorrectInd);
                                    choiceTex = zeros(4,1);
                                    choiceTex = achromTex(params.choiceStimuli(choiceIndx,:));
                                end
    
                                objectName = params.achrom(achromOrder(achromIndx));
                                achromIndx = achromIndx+1; % Move achrom selection up 1
                                blockType = 'Achromatic Shapes';
                            case params.colorCase % Colored Cirles
                                choiceCorrectInd = circleOrder(circleIndx); % What is the index of the correct choice
                                stimTex = circleTex(circleOrder(circleIndx)); % What will be displayed
                                chromDispTex = chromTex(circleOrder(circleIndx)); % Corresponding chromatic shape
                                unchosenInds = setdiff(circleList,circleOrder(circleIndx)); % What was not displayed, as list indexes (not of the textures)
                                choiceIncorrectInds = randsample(unchosenInds,3); % What will be incorrect choices, as list indexes (not of the textures)
    
                                if params.probeArray(blockIndx) == 1 % Is it a choice block?
                                    params.choiceStimuli(choiceIndx,params.correctSideChoices(choiceIndx)) = choiceCorrectInd;
                                    params.choiceStimuli(choiceIndx,params.choiceStimuli(choiceIndx,:) == 0) = choiceIncorrectInds;
                                    params.choiceStimuliNames(choiceIndx,:) = params.chrom(params.choiceStimuli(choiceIndx,:));
                                    params.correctChoiceStimuliNames(choiceIndx) = params.chrom(choiceCorrectInd);
                                    choiceTex = zeros(4,1);
                                    choiceTex = BWTex(params.choiceStimuli(choiceIndx,:));
                                end
    
                                objectName = params.colors(circleOrder(circleIndx));
                                circleIndx = circleIndx+1;
                                blockType = 'Colored Circles';
                            case params.grayCase % Gray
                                isgray = true;
                                blockType = 'Gray';
                            case params.bwCase % Black and White Color Associated Shapes
                                choiceCorrectInd = bwOrder(bwIndx); % What is the index of the correct choice
                                stimTex = BWTex(bwOrder(bwIndx)); % What will be displayed
                                chromDispTex = chromTex(bwOrder(bwIndx)); % Corresponding chromatic shape
                                unchosenInds = setdiff(bwList,bwOrder(bwIndx)); % What was not displayed, as list of indexes, (not of the textures)
                                choiceIncorrectInds = randsample(unchosenInds,3); % What will be incorrect choices, as list indexes (not of the textures)
    
                                if params.probeArray(blockIndx) == 1 % Is it a choice block?
                                    params.choiceStimuli(choiceIndx,params.correctSideChoices(choiceIndx)) = choiceCorrectInd;
                                    params.choiceStimuli(choiceIndx,params.choiceStimuli(choiceIndx,:) == 0) = choiceIncorrectInds;
                                    params.choiceStimuliNames(choiceIndx,:) = params.colors(params.choiceStimuli(choiceIndx,:));
                                    params.correctChoiceStimuliNames(choiceIndx) = params.colors(choiceCorrectInd);
                                    choiceTex = zeros(4,1);
                                    choiceTex = circleTex(params.choiceStimuli(choiceIndx,:));
                                end
    
                                objectName = params.chrom(bwOrder(bwIndx));
                                bwIndx = bwIndx+1;
                                blockType = 'Black and White Chromatic Shapes';
                        end
                    elseif blockIndx > length(params.blockorder)
                        isgray=true;
                        blockType = 'Gray';
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
                disp(['params.fixation: ' num2str(sum(params.fixation,'omitnan')/length(params.fixation(1:frameIdx,1)))]);
                disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])
                break;
                
            end

            blockTime = toc-startBlockTime; % What is the blocktime
            params.blockTracker(frameIdx) = blockIndx; % Store what block we're in
            choices = {'Upper Right','Lower Right','Lower Left','Upper Left'};
            if isgray == true
                choice = 'None';
            elseif params.probeArray(blockIndx) == 1 && params.choiceSectionDur > 0
                choice = choices{params.correctSideChoices(choiceIndx)};
            else
                choice = 'None';
            end
            
            
            % Collect eye position
            [params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2)] = eyeTrack(params.xChannel,params.yChannel,params.xGain,params.yGain,params.xOffset,params.yOffset);
            params.fixation(frameIdx,1) = isInCircle(params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2),params.fixRect);
            
            if params.fixation(frameIdx,1) == 1
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
                if sum(params.fixation(startIdx:frameIdx),"all",'omitnan') > params.rewardPerf*params.FPS*params.rewardWaitActual
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
                elseif keyCode(KbName('w')) && params.fixPix > params.pixPerAngle/2 % Increase params.fixation circle
                    params.fixPix = params.fixPix - params.pixPerAngle/2; % Shrink params.fixPix by half a degree of visual angle
                    params.baseFixRect = [0 0 params.fixPix params.fixPix]; % Size of the params.fixation circle
                    params.fixRect = CenterRectOnPointd(params.baseFixRect, xCenterExp, yCenterExp); % We center the params.fixation rectangle on the center of the screen
                    params.fixUpperRightRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp+params.horzDist,yCenterExp-params.vertDist); % Create upper right choice rectangle (Index 1, clockwise)
                    params.fixLowerRightRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp+params.horzDist,yCenterExp+params.vertDist); % Create lower right choice rectangle (Index 2, clockwise)
                    params.fixLowerLeftRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp-params.horzDist,yCenterExp+params.vertDist); % Create lower left choice rectangle (Index 3, clockwise)
                    params.fixUpperLeftRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp-params.horzDist,yCenterExp-params.vertDist); % Create upper left choice rectangle (Index 4, clockwise)
                    params.fixRects = {params.fixUpperRightRect,params.fixLowerRightRect,params.fixLowerLeftRect,params.fixUpperLeftRect}; % Cell array of params.fixation choice rects, this needs to be repeated later in the main code for updating

                    keyIsDown=0;
                elseif keyCode(KbName('s')) && params.fixPix < params.pixPerAngle*10
                    params.fixPix = params.fixPix + params.pixPerAngle/2; % Increase params.fixPix by half a degree of visual angle
                    params.baseFixRect = [0 0 params.fixPix params.fixPix]; % Size of the params.fixation circle
                    params.fixRect = CenterRectOnPointd(params.baseFixRect, xCenterExp, yCenterExp); % We center the params.fixation rectangle on the center of the screen
                    params.fixUpperRightRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp+params.horzDist,yCenterExp-params.vertDist); % Create upper right choice rectangle (Index 1, clockwise)
                    params.fixLowerRightRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp+params.horzDist,yCenterExp+params.vertDist); % Create lower right choice rectangle (Index 2, clockwise)
                    params.fixLowerLeftRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp-params.horzDist,yCenterExp+params.vertDist); % Create lower left choice rectangle (Index 3, clockwise)
                    params.fixUpperLeftRect = CenterRectOnPointd(params.fixRect*params.fixRectMult,xCenterExp-params.horzDist,yCenterExp-params.vertDist); % Create upper left choice rectangle (Index 4, clockwise)
                    params.fixRects = {params.fixUpperRightRect,params.fixLowerRightRect,params.fixLowerLeftRect,params.fixUpperLeftRect}; % Cell array of params.fixation choice rects, this needs to be repeated later in the main code for updating
                    keyIsDown=0;
    
                elseif keyCode(KbName('p'))
                    quitNow = true;
                    keyIsDown=0;
                end
            end
            
            if toc <= params.startGrayDur
                blockTimeTotal = params.startGrayDur;
            elseif blockIndx <= length(params.blockorder)
                blockTimeTotal = params.blocklength*params.TR;
            else
                blockTimeTotal = params.endGrayDur;
            end

            if blockIndx > 0 && blockIndx <= length(params.blockorder)
                if params.probeArray(blockIndx) == 1;
                    inProbe = 'Probe Block';
                else
                    inProbe = 'No Probe';
                end
            else
                inProbe = 'Start Gray Duration';
            end

            infotext = ['Time Elapsed: ', num2str(toc), '/', num2str(params.runDur), newline,...
                'Block Time Elapsed: ', num2str(blockTime), '/',num2str(blockTimeTotal), newline,...
                'Block Number: ', num2str(blockIndx), newline,...
                'params.fixation Percentage: ', num2str(sum(params.fixation(1:frameIdx,1))/length(params.fixation(1:frameIdx,1)*100)), newline,...
                'Correct Choice Location: ', choice, newline,...
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
            if toc > params.startGrayDur && blockIndx <= length(params.blockorder) && blockIndx > 0
                if params.blockorder(blockIndx) == params.bwCase || params.blockorder(blockIndx) == params.colorCase
                    Screen('DrawTexture',expWindow,chromDispTex,[],params.sideViewRect);
                end
            
            
                if blockTime < params.stimDur*params.TR % In stimulus presentation mode


                    if rem(frameIdx,params.jitterFrames) == 1 % Create rectangles for stim draw
                        viewStimRect = CenterRectOnPointd(params.baseRect, round(xCenter+jitterX(frameIdx)), round(yCenter+jitterY(frameIdx)));
                        expStimRect = CenterRectOnPointd(params.baseRect, round(xCenterExp+jitterX(frameIdx)), round(yCenterExp+jitterY(frameIdx)));
                    end
    
                    % Draw Stimulus on Framebuffer
                    if isgray == false % Is it not a gray block?
                        
                        % Record type of sub-block
                        params.subBlockTracker(frameIdx) = "Stimulus";

                        Screen('DrawTexture', viewWindow, stimTex,[],viewStimRect);
                        Screen('DrawTexture', expWindow, stimTex,[],expStimRect);  
                    elseif isgray == true
                        params.subBlockTracker(frameIdx) = "Gray";
                    end
    
                    % Draw params.fixation Cross on Framebuffer
                    Screen('DrawLines', viewWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                    Screen('DrawLines', expWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenterExp yCenterExp], 2);

                    % Draw params.fixation window on framebuffer
                    Screen('FrameOval', expWindow, circleColor, params.fixRect);
    
                    % Draw eyetrace on framebuffer
                    Screen('DrawDots',expWindow, params.eyePosition(frameIdx,:)',5);

                elseif blockTime >= params.stimDur*params.TR && blockTime < (params.stimDur+params.grayDur)*params.TR % Inter event interval
                    
                    % Record type of sub-block
                    params.subBlockTracker(frameIdx) = "Gray";

                    % Draw params.fixation Cross on Framebuffer
                    Screen('DrawLines', viewWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                    Screen('DrawLines', expWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenterExp yCenterExp], 2);

                    % Draw params.fixation window on framebuffer
                    Screen('FrameOval', expWindow, circleColor, params.fixRect);
    
                    % Draw eyetrace on framebuffer
                    Screen('DrawDots',expWindow, params.eyePosition(frameIdx,:)',5);
                
                elseif blockTime >= (params.stimDur+params.grayDur)*params.TR && params.choiceSectionDur > 0 && params.probeArray(blockIndx) == 1 && blockTime < (params.stimDur+params.grayDur+params.choiceSectionDur)*params.TR % Choice interval
    
    
    
                    % Draw stimuli
                    if isgray == true
                        params.subBlockTracker(frameIdx) = "Gray";

                        % If gray draw params.fixation cross
                        Screen('DrawLines', viewWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                        Screen('DrawLines', expWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenterExp yCenterExp], 2);

                        % Draw params.fixation window
                        Screen('FrameOval',expWindow,circleColor,params.fixRect);
    
                        % Draw Eyetrace
                        Screen('DrawDots',expWindow, params.eyePosition(frameIdx,:)',5);
                    elseif isgray == false
                        
                        % Store what type of sub-block it is
                        params.subBlockTracker(frameIdx) = "Choice";

                        % check to see where params.fixation is
                        params.choiceFixation(frameIdx,1) = isInCircle(params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2),params.fixRects{1});
                        params.choiceFixation(frameIdx,2) = isInCircle(params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2),params.fixRects{2});
                        params.choiceFixation(frameIdx,3) = isInCircle(params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2),params.fixRects{3});
                        params.choiceFixation(frameIdx,4) = isInCircle(params.eyePosition(frameIdx,1),params.eyePosition(frameIdx,2),params.fixRects{4});

                        % Draw 
                        if params.sideChoices(choiceIndx) == 0
                            Screen('DrawTexture',viewWindow,choiceTex(1),[],params.choiceRects{1});
                            Screen('DrawTexture',expWindow,choiceTex(1),[],params.choiceRectsExp{1});
                            Screen('DrawTexture',viewWindow,choiceTex(2),[],params.choiceRects{2});
                            Screen('DrawTexture',expWindow,choiceTex(2),[],params.choiceRectsExp{2});
                            Screen('DrawTexture',viewWindow,choiceTex(3),[],params.choiceRects{3});
                            Screen('DrawTexture',expWindow,choiceTex(3),[],params.choiceRectsExp{3});
                            Screen('DrawTexture',viewWindow,choiceTex(4),[],params.choiceRects{4});
                            Screen('DrawTexture',expWindow,choiceTex(4),[],params.choiceRectsExp{4});
                        end
                        
                        for yy = 1:4
                            if params.sideChoices(choiceIndx) == 0 && sum(params.choiceFixation(frameIdx-(params.choiceDur*params.FPS+1):frameIdx,yy),'all','omitnan') == params.choiceDur*params.FPS
                                params.sideChoices(choiceIndx) = yy;
                                if yy == params.correctSideChoices(choiceIndx)
                                    correctChoiceCounter = correctChoiceCounter+1;
                                    [juiceEndTime, juiceOn] = juice(params.choiceRewardDur,juiceEndTime,toc,juiceOn);
                                end
                            end
                            if params.choiceFixation(frameIdx,yy) == 1
                                if yy == params.correctSideChoices(choiceIndx)
                                    params.choiceColors(yy,:) = params.green;
                                else 
                                    params.choiceColors(yy,:) = params.red;
                                end
                            else
                                params.choiceColors(yy,:) = params.white;
                            end

                        end

                        % Draw params.fixation windows on framebuffer
                        Screen('FrameOval',expWindow, params.choiceColors(1,:), params.fixRects{1});
                        Screen('FrameOval',expWindow, params.choiceColors(2,:), params.fixRects{2});
                        Screen('FrameOval',expWindow, params.choiceColors(3,:), params.fixRects{3});
                        Screen('FrameOval',expWindow, params.choiceColors(4,:), params.fixRects{4});

                        % Draw eyetrace on framebuffer
                        Screen('DrawDots', expWindow, params.eyePosition(frameIdx,:)',5);

                    end
                elseif blockTime >= (params.stimDur+params.grayDur+params.choiceSectionDur)*params.TR && blockTime < (params.stimDur+params.grayDur+params.choiceSectionDur+params.ITIdur)*params.TR % ITI segment

                    params.subBlockTracker(frameIdx) = "Gray";

                    % Draw params.fixation Cross
                    Screen('DrawLines', viewWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                    Screen('DrawLines', expWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenterExp yCenterExp], 2);

                    % Draw params.fixation window
                    Screen('FrameOval',expWindow,circleColor,params.fixRect);
    
                    % Draw Eyetrace
                    Screen('DrawDots',expWindow, params.eyePosition(frameIdx,:)',5);                    

                else

                    params.subBlockTracker(frameIdx) = "Gray";

                    % Draw params.fixation Cross
                    Screen('DrawLines', viewWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                    Screen('DrawLines', expWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenterExp yCenterExp], 2);

                    % Draw params.fixation window
                    Screen('FrameOval',expWindow,circleColor,params.fixRect);
    
                    % Draw Eyetrace
                    Screen('DrawDots',expWindow, params.eyePosition(frameIdx,:)',5);
                end
            else
                
                params.subBlockTracker(frameIdx) = "Gray";
                % Draw params.fixation Cross
                Screen('DrawLines', viewWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenter yCenter], 2);
                Screen('DrawLines', expWindow, params.allCoords, params.lineWidthPix, [0 0 0], [xCenterExp yCenterExp], 2);

                % Draw params.fixation window
                Screen('FrameOval',expWindow,circleColor,params.fixRect);

                % Draw Eyetrace
                Screen('DrawDots',expWindow, params.eyePosition(frameIdx,:)',5);
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
                params.complete =true;
            end
            % Store any other variables:
            
            % Was the juice on sometime during this frame? (we set this up
            % as such so that if it is on anytime during the frame it is
            % set to 1)
            if isnan(params.juiceOnTracker(frameIdx))
                params.juiceOnTracker(frameIdx) = juiceOn;
            end
            if juiceOn == 1 && params.juiceOnTracker(frameIdx) == 0
                params.juiceOnTracker(frameIdx) = juiceOn;
            end 

            params.timeTracker(frameIdx) = toc; % What is the time at this frame?

            if quitNow == true
                Screen('FinalizeMovie', movie);
                sca
                break;
            end
        end
    catch error
        rethrow(error)
        save(params.dataSaveFile);
        disp(['fixation: ' num2str(sum(params.fixation,'omitnan')/length(params.fixation(1:frameIdx,1)))]);
        disp(['Correct Number of Choices: ' num2str(correctChoiceCounter), '/' num2str(choiceIndx)])
    
    end % End of stim presentation
    save(params.dataSaveFile);
    disp(['params.fixation: ' num2str(sum(params.fixation,'omitnan')/length(params.fixation(1:frameIdx,1)))]);
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



            













    



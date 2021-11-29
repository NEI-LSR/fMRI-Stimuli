function ShapeColor(subject, counterbalance_indx, run)
    % Shape Color Paradigm 2.2
    % Stuart J. Duffield November 2021
    % Displays the stimuli from the Monkey Turk experiments in blocks.
    % Blocks include gray, colored chromatic shapes, black and white chromatic
    % shapes, achromatic shapes, and colored blobs.

    % Initialize parameters

    % Initialize save paths for eyetracking, other data:
    curdir = pwd; % Current Directory
    
    stimDir = [curdir '/Stimuli']; % Change this if you move the location of the stimuli:

    if ~isdir('Data') % Switch this to isfolder if matlab 2017 or later
        mkdir('Data');
    end

    runExpTime = datestr(now); % Get the time the run occured at.

    dataSaveFile = ['Data/' subject '_' run '_Data.mat'] % File to save both run data and eye data

    % Manually set screennumbers for experimenter and viewer displays:
    expscreen = 1; 
    viewscreen = 2;

    % Refresh rate of monitors:
    fps = 60;
    ifi = 1/fps;
    
    % Other Timing Data:
    TR = 3; % TR length
    stimPerTR = 1; % 1 stimulus every TR
    
    % Gray of the background:
    gray = [155 155 155]; 

    % Load in block orders:
    blockorders = csvread('block_design.csv'); % This is produced from the counterbalance script @kurt braunlich wrote for me
    blockorder = (blockorders(counterbalance_indx,:)-1); % We subtract 1 because the csv stores the blocks with indices 1-5, we process them with indices 0-4
    blocklength = 14; % Block length is in TRs. 
    
    % Exact Duration
    runDur = TR*blocklength*length(blockorder); % You better pray this is correct
    exactDur = 840; % Specify this to check
    
    if runDur ~= exactDur % Ya gotta check or else you waste your scan time
        error('Run duration calculated from run parameters does not match hardcoded run duration length.')
    end
    

    % Load Textures:
    load([stimDir '/' 'achrom.mat'], 'achrom');
    load([stimDir '/' 'chrom.mat'], 'chrom');
    load([stimDir '/' 'chromBW.mat'], 'chromBW');
    load([stimDir '/' 'colorcircles.mat'], 'colorcircles');
    stimsize = size(chrom(:,:,1,1));
    grayTex = cat(3,repmat(gray(1),stimsize(1)),repmat(gray(2),stimsize(1)),repmat(gray(3),stimsize(1)));
    
    % Initialize Screens
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    
    [expWindow, expRect] = Screen('OpenWindow', expscreen, gray);
    [viewWindow, viewRect] = Screen('OpenWindow', viewscreen, gray);
    
    [xCenter, yCenter] = RectCenter(viewRect); % Get center of the view screen
    [xCenterExp, yCenterExp] = RectCenter(expRect); % Get center of the experimentor's screen
    
    pixPerAngle = 100; % Number of pixels per degree of visual angle
    stimPix = 6*pixPerAngle;
    jitterPix = 2*pixPerAngle;
    
    
    fixCrossDimPix = 40; % Fixation cross arm length
    lineWidthPix = 4; % Fixation cross arm thickness
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    
    % Make base rectangle and centered rectangle for stimulus presentation
    baseRect = [0 0 stimPix stimPix]; % Size of the texture rect
    
    % Load Fixation Grid and Create Texture:
    load([stimDir '/' 'fixGrid.mat'], 'fixGrid'); % Loads the .mat file with the fixation grid texture
    fixGridTex = Screen('MakeTexture', window, fixGrid); % Creates the fixation grid as a texture
    
    % Create Shape-Color Textures 
    Movie = cat(4,grayTex,chromBW,chrom,achrom,colorcircles); % Array of all possible stimulus images:
    % Gray (1), Chromatic Black and White (2:15), Chromatic (16:29),
    % Achromatic (30:43), Colored Circles (44:57)
    % Stuart's note--I need to figure out which index of each texture
    % corresponds to what
    
    baseTex = NaN(size(Movie, ndims(Movie))); % Creates a vector of NaNs that match the length of each stimulus
    
    for i = 1:size(Movie,ndims(Movie))
        baseTex(i) = Screen('MakeTexture', window, Movie(:, :, :, i)); % Initializes textures--each index corresponds to a texture
    end
    
    texture = NaN(fps*params.run.exactDuration, 1); % Initialize vector of indices
    
    stimulus_order = [];
    
    framesPerBlock = blocklength*TR*fps*stimPerTR; % Frames per block
    framesPerStim = TR*fps*stimPerTR; % Frames per stim
    for i = 1:length(blockorder)
        switch blockorder(i)
            case 0 % gray
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                texture(frames) = repmat(baseTex(1),1,framesPerBlock);
                stimulus_order = [stimulus_order repmat(0, [1,blocklength])];
            case 1 % Chromatic Shapes Uncolored
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(blocklength);
                chromBWTex = baseTex(2:15)
                texture(frames) = repelem(chromBWTex(order),framesPerStim);
                stimulus_order = [stimulus_order order];
            case 2 % Chromatic Shapes Colored
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(blocklength);
                chromTex = baseTex(16:29)
                texture(frames) = repelem(chromTex(order),framesPerStim);
                stimulus_order = [stimulus_order order];
            case 3 % Achromatic Shapes
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(params.run.blocklength);
                AchromTex = baseTex(30:43)
                texture(frames) = repelem(AchromTex(order),framesPerStim);
                stimulus_order = [stimulus_order order];
            case 4 % Colored Circles
                frames = (1:framesPerBlock)+(i-1)*framesPerBlock;
                order = randperm(params.run.blocklength);
                circTex = baseTex(44:57)
                texture(frames) = repelem(circTex(order),framesPerStim);
                stimulus_order = [stimulus_order order];
        end
    end
    
    Priority(9) % Might need to change for windows
    
    % Begin actual stimulus presentation
    try
        Screen('DrawTexture', expWindow, fixGridTex);
        Screen('DrawDots', viewWindow, [0 0], dotsize);
        Screen('Flip', expWindow);
        Screen('Flip', viewWindow);
        
        % Wait for TTL
        % Function for Wait for TTL
        
        flips = ifi:ifi:exactDur;
        flips = flips + getSecs;
        
        for frameIdx = 1:fps*exactDur
            % Check keys
            [keyIsDown,secs, keyCode] = KbCheck;
            
            % Draw Fixation Cross on Framebuffer
            Screen('DrawLines', viewWindow, allCoords, lineWidthPix, [0 0 0], [xCenter yCenter], 2);
            
            % Calculate jitter
            jitterDist = round(rand*jitterPix); % Random number between 0 and maximum number of pixels
            jitterAngle = rand*2*pi; % Gives us a random radian
            jitterX = cos(jitterAngle)*jitterDist; % X
            jitterY = sin(jitterAngle)*jitterDist; % Y
            
            % Create rectangles for stim draw
            viewStimRect = CenterRectOnPointd(baseRect, xCenter+jitterX, yCenter*jitterY);
            expStimRect = CenterRectOnPointd(baseRect, xCenterExp+jitterX, yCenterExp*jitterY);
            
            % Draw Stimulus on Framebuffer
            Screen('DrawTexture', viewStimRect, texture(frameIdx)); % Needs to be sized and have jitter
            Screen('DrawTexture', expStimRect, texture(frameIdx)); % Needs to be sized and have jitter
            
            % Draw fixation point on framebuffer
            
            % Draw fixation window on framebuffer
            
            
            % Flip
            Screen('Flip', viewWindow, flips(frameIdx));
            Screen('Flip', expWindow, flips(frameIdx));
        end
        
        
    catch error
        rethrow(error)
    end % End of stim presentation
    
    save(dataSaveFile, 'stimulus_order');
    
        
        
        
        
end
    
    
    

% Things need to do
% Set up DAQ card and eyetracking
% Set up keyboard






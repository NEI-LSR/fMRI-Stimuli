%% Menu for Experiments
% Menu for Fruit Decode
% Initialize parameters here
% Stuart J Duffield 06/07/2023

% Initialize general parameters here
params = struct(); % Initialize paramter structure
% Who is the subject
params.subject = 'Stuart';
params.experiment = 'Fruit Block Decoding';
params.runNum = 0; % What number run are we at? Starts at 0 because the while loop below increments this

% Reward parameters
params.rewardDur = 0.01; % Seconds of reward
params.rewardWait = 1.5; % Seconds, time to wait between rewards
params.rewardWaitActual = params.rewardWait; % This will be changed by the jitter
params.rewardWaitChange = 0.001; % Seconds, increment to change reward wait by during experiment
params.rewardWaitJitter = 0.25; % Seconds, jitter in how much reward is given by at any moment
params.rewardPerf = 0.75; % Fixation, how much to get reward
params.rewardKeyChange = 0.001; % Seconds, increment to change reward durations by during experiment

% Calibration Parameters and DAQ Startup settings
params.gainStep = 5; % Pixels/Volt, how much to change the gain by
DAQ('Debug',true); % Set DAQ to not debug
DAQ('Init'); % Initialize DAQ
params.xGain = -2080; % Pixels/Volt
params.yGain = 2215; % Pixels/Volt
params.xOffset = -946; % Pixels
params.yOffset = -1286; % Pixels
params.xChannel = 2; % DAQ indexes starts at 1
params.yChannel = 3; % Where y channel inputs to the DAQ
params.ttlChannel = 8; % Where the TTL channel inputs to the DAQ
params.manualMovementPix = 10;

% Set up folder structure
params.curdir = pwd; % Get the current working directory
params.stimDir = fullfile(params.curdir,'Stimuli'); % Get the stimuli directory
params.dataDir = fullfile(params.curdir,'Data'); % Get the data directory
params.resultsDir = fullfile(params.curdir,'Results'); % Get the results directory
if ~isfolder(params.dataDir) % Does the data folder exist?
    mkdir(params.dataDir); % If not, then make it
end
if ~isfolder(params.resultsDir) % Does the results folder exist?
    mkdir(params.resultsDir)
end

% Screen information
params.expscreen = 1; % Experimenter's Screen
params.viewscreen = 2; % Subject's Screen
params.pixPerAngle = 50; % Number of pixels (horizontally or vertically) that makes up 1 DvA

% Now set up parameters for the particular experiment you're running
% In this case Shape Color Attention
params.endGrayDur = 12; % Seconds, how long gray is on at end of experiment
params.startGrayDur = 9; % Seconds, how long gray is on at start of experiment
params.stimDur = 0.5; % Seconds, how many seconds is each individual stimulus on during a block
params.blocklength = 10; % TRs, number of TRs in each block
params.TR = 3; % Seconds, how many TRs 
params.movieFPS = 10; % Number of frames per second the movie will have
params.FPS = 30; % Number of frames per second the playback of the experiment will be.
params.IFI = 1/params.FPS; % Inter frame interval
params.conditions = {'Apple','Banana','Orange','Grape','patch_Apple','patch_Banana','patch_Orange','patch_Grape'}; % The conditions of different blocks
params.numconds = length(params.conditions); % Number of conditions

params.blockorders = [
     1     2     8     3     7     4     6     5;
     2     3     1     4     8     5     7     6;
     3     4     2     5     1     6     8     7;
     4     5     3     6     2     7     1     8;
     5     6     4     7     3     8     2     1;
     6     7     5     8     4     1     3     2;
     7     8     6     1     5     2     4     3;
     8     1     7     2     6     3     5     4]; % All of the block orders for different runs



params.numblocks = size(params.blockorders,2); % How many blocks per run
params.numorders = size(params.blockorders,1); % How many orders there are
params.runDur = ceil(params.TR*params.blocklength*size(params.blockorders,2)+params.endGrayDur+params.startGrayDur); % Calculate the total run length in seconds


% Colors
params.gray = [128 128 128]; % Background Gray
prompt_begin = ['What run number do you want to begin with?'];
reply = input (prompt_begin,'s');
params.runNum = str2double(reply) - 1;
params.blockorderindex = 0; % Just to start, will automatically be set otherwise
params.IMA = 0; % Start out IMA at 0 as well


while true % Now we run a while loop to actually display the menu
    prompt = ['NOTE: CHANGING THE LENGTH OF THE EXPERIMENT WILL RESULT IN ERRORS UPON DESIGN MATRIX COMBINATION. IF CHANGING THE LENGTH, CREATE A NEW SESSION FOLDER',newline,...
        'Menu',newline,...
        'Experiment: ', params.experiment,newline,...
        'Subject: ', params.subject,newline,...
        'TR Length (Seconds): ', num2str(params.TR),newline,...
        'Run Duration (seconds, TRs): ' num2str(params.runDur) ', ' num2str(params.runDur/params.TR),newline,...
        'We have completed ', num2str(params.runNum), ' run this session.',newline,...
        newline,...
        'Enter 1 to begin fixation',newline,...
        'Enter 2 to begin ' params.experiment, newline,...
        'Enter N to go to the next run, IMA, and order number',newline,...
        'Enter P to quit'];
    reply = input(prompt,'s');
    if reply == '1'
        params = fixation(params);
    elseif reply == '2'
        params.runNum = params.runNum + 1; % Add one to run number
        prompt = 'What order number do you want? ';
        params.blockorderindex = str2double(input(prompt,'s'));
        params.blockorder = params.blockorders(params.blockorderindex,:);
        prompt = 'What IMA is this? ';
        params.IMA = str2double(input(prompt,'s'));
        disp([num2str(params.IMA) ' -IMA'  ,newline,...
        num2str(params.runNum) ' -Run number' ,newline,...
        num2str(params.blockorderindex) '- Block order' ]);
        reply = input('Confirm? y (Yes)/Backspace (No)','s');
        if reply == 'y'
            params = Fruit_Decode(params);
        else
            params.runNum = params.runNum - 1
            continue
        end
    elseif reply == 'n'
        params.runNum = params.runNum + 1;
        if params.blockorderindex < params.numorders
            params.blockorderindex = params.blockorderindex + 1;
        else 
            disp('Returning to first block order')
            params.blockorderindex = 1;
        end
        params.blockorder = params.blockorders(params.blockorderindex,:);
        params.IMA = params.IMA + 1;
        disp([num2str(params.IMA) ' -IMA'  ,newline,...
            num2str(params.runNum) ' -Run number' ,newline,...
            num2str(params.blockorderindex) '- Block order' ]);
        reply = input('Confirm? Y (Yes)/Backspace (No)','s')
        if reply == 'y'
            params = SC(params);
            params = generateRunInfo(params);
        else
            params.runNum = params.runNum - 1
            continue
        end    
    elseif reply == 'p'
        break
    end

end
     
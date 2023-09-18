%% Menu for Experiments
% Menu for Shape Color
% Initialize parameters here
% Stuart J Duffield 09/2022
% In this version added option to display subset of stimuli set by
% params.use_index

% Initialize general parameters here
params = struct(); % Initialize paramter structure
% Who is the subject
params.subject = 'Jeeves';
params.experiment = 'Shape Color 5.2';
params.runNum = 0; % What number run are we at? Starts at 0 because the while loop below increments this

% Reward parameters
params.rewardDur = 0.01; % Seconds of reward
params.rewardWait = 1.75; % Seconds, time to wait between rewards
params.rewardWaitActual = params.rewardWait; % This will be changed by the jitter
params.rewardWaitChange = 0.001; % Seconds, increment to change reward wait by during experiment
params.rewardWaitJitter = 0.25; % Seconds, jitter in how much reward is given by at any moment
params.rewardPerf = 0.75; % % Fixation, how much to get reward
params.rewardKeyChange = 0.001; % Seconds, increment to change reward durations by during experiment

% Calibration Parameters and DAQ Startup settings
params.gainStep = 5; % Pixels/Volt, how much to change the gain by
DAQ('Debug',false); % Set DAQ to not debug
DAQ('Init'); % Initialize DAQ
params.xGain = -1190; % Pixels/Volt
params.yGain = 395; % Pixels/Volt
params.xOffset = -946; % Pixels
params.yOffset = -1286; % Pixels
params.xChannel = 3; % DAQ indexes starts at 1 ...changed from 2
params.yChannel = 2; % Where y channel inputs to the DAQ ...changed from 3
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
params.expscreen = 2; % Experimenter's Screen
params.viewscreen = 1; % Subject's Screen
params.pixPerAngle = 40; % Number of pixels per degree of visual stimuli. 
% Note: after the projector standardization between Marianne and Stuart's
% setups, the actual pixels per degree of visual angle is 50. This has been
% kept consistent throughout experiments, however, so I will not update the
% parameter here, even if it is misleading.

% Now set up parametesr for the particular experiment you're running
% In this case Shape Color Attention
params.choiceDur = 0.7; % Seconds, how long to fixate at choice to get a reward
params.choiceRewardDur = 0.15; % Seconds, how long the reward is for correct choice
params.endGrayDur = 12; % Seconds, how long gray is on at end of experiment
params.startGrayDur = 9; % Seconds, how long gray is on at start of experiment
params.choiceDistAngle = 4; % Degrees Visual Angle, how distant the choices will be 
params.stimDur = 3; % TRs, how many TRs the stimulus will be on
params.grayDur = 0; % TRs, how many TRs the gray will be after the stimulus
params.choiceSectionDur = 1; % TRs, how many TRs the choice will be on. If not choice stimulus, will be gray
params.ITIdur = 3; % TRs, how many TRs there will be gray after the choice.
params.blocklength = params.stimDur+params.grayDur+params.choiceSectionDur+params.ITIdur; % TRs, number of TRs in each block
params.TR = 3; % Seconds, how many TRs 
params.movieFPS = 10; % Number of frames per second the movie will have
params.FPS = 30; % Number of frames per second the playback of the experiment will be.
params.IFI = 1/params.FPS; % Inter frame interval
params.numconds = 3; % Number of conditions
params.colors = ["LightRed","DarkRed","LightYellow","DarkYellow","LightGreen","DarkGreen","LightTurquiose","DarkTurquiose","LightBlue","DarkBlue","LightPurple","DarkPurple","LightGray","DarkGray"];
params.chrom = ["Hourglass","UpArrow","Diamond","Spike","Lock","Bar","Spade","Dodecagon","Sawblade","Nail","Rabbit","Puzzle","Venn","Hat"];
params.achrom = ["Chevron","Tie","Acorn","House","Pacman","Stickyhand","Bell","LeftArrow","Heart","Ditto","Crowbar","Gem","Jellyfish","Star"];
params.use_index = [2,3,6,7,10,11,14];


params.numStim = 7; % Number of unique stimuli across category
params.numBDOrder = 2; % Order of the debruijn sequencing
params.numSplits = 14; % How many orders to subdivide the DB sequencing into
params.numOverlap = 1; % How much overlap between sequences
while true
    prompt = 'Load Session? (y/n): ';
    reply = input(prompt,'s');
    if reply == 'y'
        params.loadSession = true; % Are we going to load the stimuli
        prompt = 'What session do you want to load?';
        params.sessionFile = input(prompt,'s');
        disp(['Loading session ', params.sessionFile]);
        try
            params.stimIndex = csvread(fullfile(params.dataDir,[params.sessionFile,'_stimindices.csv']));
            params.stimOrders = csvread(fullfile(params.dataDir,[params.sessionFile,'_stimorders.csv']));
            break
        catch
            disp('Failed to load session');
            continue
        end
            
        
    elseif reply == 'n'
        params = gen_seq_stim(params,params.numStim,length(params.use_index),params.numBDOrder,params.numSplits,params.numOverlap,params.use_index);
        break
    else 
        continue
    end
end
disp('Stimuli indices: ')
disp(params.stimIndex)

params.blockorders = (params.stimOrders > 7) + 2; % Creates array of 2s and 3s, which matches to colorcase and bwcase.
% If the stimorder is 1-7, it is a color, if 8-14, a shape
params.numblocks = size(params.blockorders,2); % How many blocks per run
params.numorders = size(params.blockorders,1); % How many orders there are
params.totconds = params.numorders*params.numblocks; % How many total conditions are there
params.runDur = ceil(params.TR*params.blocklength*size(params.blockorders,2)+params.endGrayDur+params.startGrayDur); % Calculate the total run length in seconds

params.uniqueconds = length(params.colors)+length(params.chrom)+length(params.achrom);
params.achromCase = 1; % When blockorder == 1, it is an achrom block
params.colorCase = 2; % When blockorder == 2, it is a color block
params.bwCase = 3; % When blockorder == 3, it is a chromatic block
params.grayCase = 4; % When blockorder == 4, it is a gray block. Currently unused. 
params.probeChance = 1; % The chance that it is a probe trial
params.numProbes_init = params.probeChance*params.numblocks; % Number of probes per trial

% Colors
params.gray = [31 29 47]; %[103    87   125]; % This gray is redefined in SC.m, so changing this here will not affect the main script
prompt_begin = ['What run number do you want to begin with?'];
reply = input (prompt_begin,'s');
params.runNum = str2double(reply) - 1;
params.blockorderindex = 0; % Just to start, will automatically be set otherwise
params.IMA = 0; % Start out IMA at 0 as well


while true % Now we run a while loop to actually display the menu
    if params.runNum >= 1
        combineDMs(params); % Warning--if you change the length of the experiment, this will return an error. 
    end
    prompt = ['NOTE: CHANGING THE LENGTH OF THE EXPERIMENT WILL RESULT IN ERRORS UPON DESIGN MATRIX COMBINATION. IF CHANGING THE LENGTH, CREATE A NEW SESSION FOLDER',newline,...
        'Menu',newline,...
        'Experiment: ', params.experiment,newline,...
        'Subject: ', params.subject,newline,...
        'TR Length (Seconds): ', num2str(params.TR),newline,...
        'Stimulus Duration (TRs): ', num2str(params.stimDur),newline,...
        'Gray Duration (TRs): ', num2str(params.grayDur),newline,...
        'Choice Duration (TRs): ', num2str(params.choiceSectionDur),newline,...
        'ITI Duration (TRs): ', num2str(params.ITIdur),newline,...
        'Run Duration (seconds, TRs): ' num2str(params.runDur) ', ' num2str(params.runDur/params.TR),newline,...
        'We have completed ', num2str(params.runNum), ' run this session.',newline,...
        newline,...
        'Enter 1 to begin fixation',newline,...
        'Enter 2 to begin ' params.experiment, newline,...
        'Enter N to go to the next run, IMA, and order number',newline,...
        'Enter A to combine and compute behavioral metrics for this session',newline,...
        'Enter P to quit'];
    reply = input(prompt,'s');
    if reply == '1'
        params = fixation(params);
    elseif reply == '2'
        params.runNum = params.runNum + 1; % Add one to run number
        prompt = 'What order number do you want? ';
        params.blockorderindex = str2double(input(prompt,'s'));
        params.blockorder = params.blockorders(params.blockorderindex,:);
        params.stimorder = params.stimOrders(params.blockorderindex,:);
        params.stimorder = mod(params.stimorder-1,params.numStim)+1; 
        prompt = 'What IMA is this? ';
        params.IMA = str2double(input(prompt,'s'));
        disp([num2str(params.IMA) ' -IMA'  ,newline,...
        num2str(params.runNum) ' -Run number' ,newline,...
        num2str(params.blockorderindex) '- Block order' ]);
        reply = input('Confirm? y (Yes)/Backspace (No)','s');
        if reply == 'y'
            params = SC(params);
            generateRunInfo(params);
        else
            params.runNum = params.runNum - 1
            continue
        end
    elseif reply == 'a'
        params = combineRunInfo(params);
    elseif reply == 'n'
        params.runNum = params.runNum + 1;
        if params.blockorderindex < params.numorders
            params.blockorderindex = params.blockorderindex + 1;
        else 
            disp('Generating new stimuli indices and sequences...')
             params = gen_seq_stim(params,params.numStim,length(params.use_index),params.numBDOrder,params.numSplits,params.numOverlap,params.use_index);
            %params = gen_seq_stim(params,params.numStim,length(params.colors),params.numBDOrder,params.numSplits,params.numOverlap); 
            params.blockorders = (params.stimOrders > 7) + 2; % Creates array of 2s and 3s, which matches to colorcase and bwcase.
            % If the stimorder is 1-4, it is a color, if 5-8, a shape
            disp('Stimuli indices: ')
            disp(params.stimIndex)
            params.blockorderindex = 1;
        end
        params.blockorder = params.blockorders(params.blockorderindex,:);
        params.stimorder = params.stimOrders(params.blockorderindex,:);
        params.stimorder = mod(params.stimorder-1,params.numStim)+1; 
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
     
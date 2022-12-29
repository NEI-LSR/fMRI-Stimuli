%% Menu for Experiments
% Menu for Shape Color
% Initialize parameters here
% Stuart J Duffield 09/2022

% Initialize general parameters here
params = struct(); % Initialize paramter structure
% Who is the subject
params.subject = 'Wooster';
params.experiment = 'Shape Color 4.0';
params.runNum = 0; % What number run are we at? Starts at 0 because the while loop below increments this

% Reward parameters
params.rewardDur = 0.015; % Seconds of reward
params.rewardWait = 1.5; % Seconds, time to wait between rewards
params.rewardWaitActual = params.rewardWait; % This will be changed by the jitter
params.rewardWaitChange = 0.01; % Seconds, increment to change reward wait by during experiment
params.rewardWaitJitter = 0.25; % Seconds, jitter in how much reward is given by at any moment
params.rewardPerf = 0.75; % % Fixation, how much to get reward
params.rewardKeyChange = 0.01; % Seconds, increment to change reward durations by during experiment

params.gainStep = 5; % Pixels/Volt, how much to change the gain by
% Calibration Parameters and DAQ Startup settings
DAQ('Debug',false); % Set DAQ to not debug
DAQ('Init'); % Initialize DAQ
params.xGain = -625; % Pixels/Volt
params.yGain = 700; % Pixels/Volt
params.xOffset = -1185; % Pixels
params.yOffset = -640; % Pixels
params.xChannel = 2; % DAQ indexes starts at 1
params.yChannel = 3; % Where y channel inputs to the DAQ
params.ttlChannel = 8; % Where the TTL channel inputs to the DAQ
params.manualMovementPix = 10;
% Set up folder structure
params.curdir = pwd; % Get the current working directory
params.stimDir = fullfile(params.curdir,'Stimuli'); % Get the stimuli directory
params.dataDir = fullfile(params.curdir,'Data'); % Get the data directory
if ~isfolder(params.dataDir) % Does the data folder exist?
    mkdir(params.dataDir); % If not, then make it
end

% Screen information
params.expscreen = 1; % Experimenter's Screen
params.viewscreen = 2; % Subject's Screen
params.pixPerAngle = 40; % Number of pixels per degree of visual stimuli

% Now set up parametesr for the particular experiment you're running
% In this case Shape Color Attention
params.choiceDur = 0.7; % Seconds, how long to fixate at choice to get a reward
params.choiceRewardDur = 0.4; % Seconds, how long the reward is for correct choice
params.endGrayDur = 30; % Seconds, how long gray is on at end of experiment
params.choiceDistAngle = 10; % Degrees Visual Angle, how distant the choices will be 
params.stimDur = 8; % TRs, how many TRs the stimulus will be on
params.grayDur = 1; % TRs, how many TRs the gray will be after the stimulus
params.choiceSectionDur = 1; % TRs, how many TRs the choice will be on. If not choice stimulus, will be gray
params.blocklength = params.stimDur+params.grayDur+params.choiceSectionDur; % TRs, number of TRs in each block
params.TR = 3; % Seconds, how many TRs 
params.movieFPS = 10; % Number of frames per second the movie will have
params.FPS = 30; % Number of frames per second the playback of the experiment will be.
params.IFI = 1/params.FPS; % Inter frame interval
params.numconds = 3; % Number of conditions
params.blockrepeats = 3; % Number of times blocks are repeated
params.blockorders = repmat(williams(params.numconds),1,params.blockrepeats); % Generated using Williams counterbalancing (see williams.m) and repeated the matrix by 3 in its length
params.numblocks = size(params.blockorders,2); % How many blocks per run
params.numorders = size(params.blockorders,1); % How many orders there are
params.totconds = params.numorders*params.numblocks; % How many total conditions are there
params.runDur = ceil(params.TR*params.blocklength*size(params.blockorders,2)+params.endGrayDur); % Calculate the total run length in seconds
params.colors = ["LightRed","DarkRed","LightYellow","DarkYellow","LightGreen","DarkGreen","LightTurquiose","DarkTurquiose","LightBlue","DarkBlue","LightPurple","DarkPurple","LightGray","DarkGray"];
params.chrom = ["Hourglass","UpArrow","Diamond","Spike","Lock","Bar","Spade","Dodecagon","Sawblade","Nail","Rabbit","Puzzle","Venn","Hat"];
params.achrom = ["Chevron","Tie","Acorn","House","Pacman","Stickyhand","Bell","LeftArrow","Heart","Ditto","Crowbar","Gem","Jellyfish","Star"];
params.uniqueconds = length(params.colors)+length(params.chrom)+length(params.achrom);
params.achromCase = 1; % When blockorder == 1, it is an achrom block
params.colorCase = 2; % When blockorder == 2, it is a color block
params.bwCase = 3; % When blockorder == 3, it is a chromatic block
params.grayCase = 4; % When blockorder == 4, it is a gray block. Currently unused. 
params.probeChance = 1/4.5; % The chance that it is a probe trial
params.numProbes_init = params.probeChance*params.numblocks; % Number of probes per trial

% Colors
params.gray = [31 29 47];
prompt_begin = ['What run number do you want to begin with?'];
reply = input (prompt_begin,'s');
params.runNum = str2double(reply) - 1;
params.blockorderindex = 0; % Just to start, will automatically be set otherwise
params.IMA = 0; % Start out IMA at 0 as well


while true % Now we run a while loop to actually display the menu
    prompt = ['Menu',newline,...
        'Experiment: ', params.experiment,newline,...
        'Subject: ', params.subject,newline,...
        'TR Length (Seconds): ', num2str(params.TR),newline,...
        'Stimulus Duration (TRs): ', num2str(params.stimDur),newline,...
        'Gray Duration (TRs): ', num2str(params.grayDur),newline,...
        'Choice Duration (TRs): ', num2str(params.choiceSectionDur),newline,...
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
        reply = input('Confirm? Enter (Yes)/Backspace (No)','s');
        if reply == 'y'
            params = SC(params);
        else
            continue
        end
    elseif reply == 'n'
        params.runNum = params.runNum + 1;
        if params.blockorderindex < params.numorders
            params.blockorderindex = params.blockorderindex + 1;
        else 
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
        else
            continue
        end    
    elseif reply == 'p'
        break
    end
end
     
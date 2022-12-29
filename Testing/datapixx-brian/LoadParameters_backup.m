function [params] = LoadParameters()
    
    %% DataPixx parameters
    params.datapixx.analogInRate         = 1000;                                                                                       % In Hz
    params.datapixx.analogOutRate        = 1000;                                                                                       % In Hz
    params.datapixx.adcChannels          = [0 1 2 3 4 5 6 7];                                                                          % ADC channels assigned to inputs (7 = scannerTTL)
    params.datapixx.dacChannels          = 1;                                                                                          % DAC channels assigned to outputs
    params.datapixx.adcBufferAddress     = 4e6;                                                                                        % Set DataPixx internal ADC buffer address
    params.datapixx.dacBufferAddress     = 8e6;                                                                                        % Set DataPixx internal DAC buffer address
    params.datapixx.calibrationOffset    = [-2.43 -2.21];                                                                              % Eye tracker calibration voltage offset    ([X Y] axes)
    params.datapixx.calibrationGain      = [25 25];                                                                                    % Eye tracker calibration voltage gain      ([X Y] axes)
    params.datapixx.calibrationSign      = [-1 1];                                                                                     % Eye tracker calibration voltage inversion ([X Y] axes)
    
    
    %% Directories
    subjectID                            = 'Francois';                                                                                 % Monkey's name
    params.directory.main                = fileparts(mfilename('fullpath'));                                                           % Path to current folder (this .m file)
    params.directory.stimuli             = [params.directory.main '/' 'stimuli'];                                                      % Path to stimuli subfolder
    params.directory.save                = [params.directory.main '/' 'results'];                                                      % Path to results subfolder
    params.directory.subject             = [params.directory.save '/' subjectID];                                                      % Path to subject subfolder
    params.directory.session             = [params.directory.subject '/' datestr(clock,'yyyymmdd')];                                   % Path to session subfolder
    
    
    %% Display parameters
    params.display.num                   = max(Screen('Screens'));                                                                     % 0 = internal display
    params.display.viewingDistance       = 37.0;                                                                                       % In cm
    params.display.size                  = [70.1 39.9];%[50.4 28.4];%[88.9 50.0];                                                                                % In cm
    params.display.fps                   = 60;                                                                                         % In Hz
    params.display.ifi                   = 1 / params.display.fps;                                                                     % Inter frame interval
    params.display.resolution            = [1920 1080];                                                                                % In pixels
    params.display.scaleHD               = params.display.resolution(2) / 1080;                                                        % Scaling factor relative to HD (1080p)
    DefineScreenRectangles;
    params.display.pixPerCm              = params.display.expWindowRect([3 4]) ./ params.display.size;                                 % Pixels/cm
    params.display.pixPerDeg             = 2 * (params.display.pixPerCm * params.display.viewingDistance * tand(0.5));                 % Pixels/degree
    params.display.grayBackground        = [0.5 0.5 0.5];                                                                              % Gray color
    params.display.blackBackground       = [0 0 0];                                                                                    % Black color
    params.key.names                     = struct([]);                                                                                 % Preallocating key log
    
    
    %% Experiment parameters
    params.run.startTime                 = 0;                                                                                          % In seconds
    params.run.endTime                   = 0;                                                                                          % In seconds
    params.run.exactDuration             = 300;                                                                                        % In seconds
    params.run.duration                  = 0;                                                                                          % In seconds
    params.run.isAborted                 = 0;                                                                                          % Flag to manually end the run
    params.run.isExperiment              = 1;                                                                                          % 0 = training
    params.run.type                      = 'retino';                                                                                   % 'retino' or 'motion' or 'fixation'
    params.run.stimContrast              = 1;                                                                                          % 0 to 1
    params.run.frameIdx                  = 0;                                                                                          % Frame counter
    params.run.log                       = NaN(params.run.exactDuration*params.display.fps, 8);                                        % Preallocating frame log
    
    
    %% Fixation parameters
    params.run.fixation.eye2track        = 'left';                                                                                     % 'left' OR 'right' (not both)
    params.run.fixation.windowSize       = 2;                                                                                          % In degrees
    params.run.fixation.windowColor      = [1 0 0; 0 1 0];                                                                             % [Red; Green]
    params.run.fixation.windowRect       = CenterRect([0, 0, params.run.fixation.windowSize.*params.display.pixPerDeg], params.display.monkWindowRect); % Fixation window rectangle
    params.run.fixation.dotSize          = 10 * params.display.scaleHD;                                                                % dotSizeInPixels * params.display.scaleHD
    params.run.fixation.dotColor         = [1 0 0];                                                                                    % Red color
    params.run.fixation.dotOffset        = [0 0];                                                                                      % In pixels (fixation dot screen offset values)
    params.run.fixation.isDotOn          = 1;                                                                                          % Flag to toggle fixation dot on/off
    params.run.fixation.isGridOn         = 0;                                                                                          % Flag to toggle fixation grid on/off (only on monkey screen)
    params.run.fixation.coordinates      = [];                                                                                         % In pixels (gaze center screen coordinates)
    params.run.fixation.isInWindow       = 0;                                                                                          % Flag to report if fixation is in fixation window
    params.run.fixation.isBroken         = 1;                                                                                          % Flag to report fixation break
    params.run.fixation.breakStartIdx    = 1;                                                                                          % Frame index of fixation break start
    params.run.fixation.breakTolerance   = 0.3;                                                                                        % In seconds (allowed fixation break duration)
    params.run.fixation.log              = 0;                                                                                          % Fixation durations log
    params.run.fixation.numSamples       = 30;
    
    
    %% Reward parameters
    params.run.reward.TTL                = 0.015;                                                                                      % In seconds
    params.run.reward.startFrequency     = 2.0;                                                                                        % In Hz
    params.run.reward.minFrequency       = 0.5;                                                                                        % In Hz
    params.run.reward.maxFrequency       = 1.0;                                                                                        % In Hz
    params.run.reward.frequency          = params.run.reward.startFrequency;                                                           % In Hz
    params.run.reward.frequencyIncrement = (params.run.reward.maxFrequency-params.run.reward.minFrequency) / 5;                        % In Hz
    params.run.reward.interval           = 1 / params.run.reward.frequency;                                                            % In seconds
    params.run.reward.count              = 0;                                                                                          % Reward counter
    params.run.reward.maxCount           = round(((params.run.exactDuration-sum(1./(params.run.reward.minFrequency:params.run.reward.frequencyIncrement:params.run.reward.maxFrequency)))*params.run.reward.maxFrequency) ...
                                           + sum(1./(params.run.reward.minFrequency:params.run.reward.frequencyIncrement:params.run.reward.maxFrequency))); % Maximum number of reward obtainable (for non-stop fixation)
    
    
    %% Defining screen rectangles of experimenter and monkey displays
    function DefineScreenRectangles
        
        params.display.windowRect        = [0, 0, 2*params.display.resolution(2)*16/9, params.display.resolution(2)];                  % Screen rectangle spanning 2 monitors (experimenter + monkey, each at 1920x1080) 
        params.display.expWindowRect     = params.display.windowRect;                                                                              
        params.display.expWindowRect(3)  = params.display.expWindowRect(3) / 2;                                                        % Screen rectangle of experimenter display
        params.display.monkWindowRect    = params.display.windowRect;                                                                              
        params.display.monkWindowRect(1) = params.display.expWindowRect(3);                                                            % Screen rectangle of monkey display
        
        [params.display.expRectCenter(1), params.display.expRectCenter(2)]   = RectCenter(params.display.expWindowRect);               % Experimenter display screen rectangle center
        [params.display.monkRectCenter(1), params.display.monkRectCenter(2)] = RectCenter(params.display.monkWindowRect);              % Monkey display screen rectangle center
        
        params.display.expRect  = CenterRectOnPoint([-1 -1 1 1]*params.display.resolution(2)/2, params.display.expRectCenter(1), params.display.expRectCenter(2));   % Experimenter display stimulus rectangle
        params.display.monkRect = CenterRectOnPoint([-1 -1 1 1]*params.display.resolution(2)/2, params.display.monkRectCenter(1), params.display.monkRectCenter(2)); % Monkey display stimulus rectangle
        
    end % Function end
    
end % Function end

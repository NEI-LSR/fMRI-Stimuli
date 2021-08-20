if params.fixation.duration > 0 && params.fixation.duration~=params.fixation.log(end)
    params.fixation.log(end+1) = params.fixation.duration;
end
if size(params.fixation.log, 2) > 1
    params.fixation.log = params.fixation.log';
end

params2change = params;
clear params;


%% DataPixx parameters
params.datapixx.analogInRate         = params2change.datapixx.analogInRate;
params.datapixx.analogOutRate        = params2change.datapixx.analogOutRate;
params.datapixx.adcChannels          = params2change.datapixx.adcChannels;
params.datapixx.dacChannels          = params2change.datapixx.dacChannels;
params.datapixx.adcBufferAddress     = params2change.datapixx.adcBufferAddress;
params.datapixx.dacBufferAddress     = params2change.datapixx.dacBufferAddress;
params.datapixx.calibrationOffset    = params2change.datapixx.calibrationOffset;
params.datapixx.calibrationGain      = params2change.datapixx.calibrationGain;
params.datapixx.calibrationSign      = params2change.datapixx.calibrationSign;


%% Directories
subjectID                            = 'Francois';
params.directory.main                = params2change.run.mainDir;
params.directory.stimuli             = params2change.run.stimDir(1:end-1);
params.directory.save                = params2change.run.saveDir(1:end-1);
params.directory.subject             = [params.directory.save '/' subjectID];


%% Display parameters
params.display.num                   = params2change.display.num;
params.display.viewingDistance       = params2change.display.viewingDistance;
params.display.size                  = params2change.display.size;
params.display.fps                   = params2change.display.fps;
params.display.ifi                   = params2change.display.ifi;
params.display.resolution            = [1280 720];
params.display.windowRect            = params2change.display.windowRect;
params.display.expWindowRect         = params2change.display.expWindowRect;
params.display.monkWindowRect        = params2change.display.monkWindowRect;
params.display.expRectCenter         = params2change.display.expRectCenter;
params.display.monkRectCenter        = params2change.display.monkRectCenter;
params.display.expRect               = params2change.display.expRect;
params.display.monkRect              = params2change.display.monkRect;
params.display.pixPerCm              = params2change.display.pixPerCm;
params.display.pixPerDeg             = params2change.display.pixPerDeg;
params.display.grayBackground        = params2change.display.backgroundColor;
params.display.blackBackground       = [0 0 0];


%% Keyboard shortcuts
if ~isfield(params2change.keys,'abortRun')
    key                              = params2change.keys;
    key.names                        = key.names';
    key.functions(1)                 = {'abortRun'};
    key.functions                    = key.functions';
    key.list                         = key.list';
    key                              = renameStructField(key, 'endRun', 'abortRun');
    params.key                       = key;
else
    params.key                       = params2change.keys;
end


%% Experiment parameters
params.run.startTime                 = params2change.run.startTime;
params.run.endTime                   = params2change.run.endTime;
params.run.exactDuration             = params2change.run.duration;
params.run.duration                  = params2change.run.endDuration;
if ~isfield(params2change.keys,'abortRun')
    params.run.isAborted             = params2change.run.isEnd;
else
    params.run.isAborted             = params2change.run.isAborted;
end
params.run.isExperiment              = params2change.run.isExperiment;
if isfield(params2change.display, 'stimContrast')
    params.run.stimContrast          = params2change.display.stimContrast;
else
    params.run.stimContrast          = 0;
end
params.run.frameIdx                  = params2change.run.frameIdx;
params.run.log                       = params2change.run.log;

params.directory.session             = [params.directory.subject '/' datestr(params.run.startTime, 'yyyymmdd')];


%% Fixation parameters
params.run.fixation.eye2track        = params2change.fixation.eye2track;
params.run.fixation.windowSize       = params2change.fixation.windowSize;
params.run.fixation.windowColor      = params2change.fixation.windowColor;
params.run.fixation.windowRect       = params2change.fixation.windowRect;
params.run.fixation.dotSize          = params2change.fixation.dotSize;
params.run.fixation.dotColor         = params2change.fixation.dotColor;
params.run.fixation.dotOffset        = params2change.fixation.dotOffset;
params.run.fixation.isDotOn          = params2change.fixation.isDotOn;
params.run.fixation.isGridOn         = params2change.fixation.isGridOn;
params.run.fixation.coordinates      = params2change.fixation.coordinates;
params.run.fixation.isInWindow       = params2change.fixation.isInWindow;
params.run.fixation.isBroken         = params2change.fixation.isBroken;
params.run.fixation.breakStartIdx    = params2change.fixation.breakStartIdx;
params.run.fixation.breakTolerance   = params2change.fixation.breakTolerance;
params.run.fixation.log              = params2change.fixation.log;
if params.run.fixation.log(end) == 0
    params.run.fixation.log(end) = [];
end


%% Reward parameters
params.run.reward.TTL                = params2change.reward.TTL;
if isfield(params2change.reward, 'startFrequency')
    params.run.reward.startFrequency = params2change.reward.startFrequency;
else
    params.run.reward.startFrequency = params2change.reward.minFrequency;
end
params.run.reward.minFrequency       = params2change.reward.minFrequency;
params.run.reward.maxFrequency       = params2change.reward.maxFrequency;
params.run.reward.frequency          = params2change.reward.frequency;
params.run.reward.frequencyIncrement = params2change.reward.frequencyIncrement;
params.run.reward.interval           = params2change.reward.interval;
params.run.reward.count              = params2change.reward.count;
params.run.reward.maxCount           = params2change.reward.maxCount;


clear key subjectID params2change;

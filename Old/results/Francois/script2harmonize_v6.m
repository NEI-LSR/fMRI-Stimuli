clear runLog;
params2change = params;
clear params;


%% DataPixx parameters
params.datapixx.analogInRate         = params2change.DPx.analogInRate;
params.datapixx.analogOutRate        = params2change.DPx.analogOutRate;
params.datapixx.adcChannels          = params2change.DPx.adcChannels;
params.datapixx.dacChannels          = params2change.DPx.dacChannels;
params.datapixx.adcBufferAddress     = params2change.DPx.adcBufferAddress;
params.datapixx.dacBufferAddress     = params2change.DPx.dacBufferAddress;
params.datapixx.calibrationOffset    = params2change.calibration.offset;
params.datapixx.calibrationGain      = params2change.calibration.gain;
params.datapixx.calibrationSign      = params2change.calibration.sign;


%% Directories
subjectID                            = 'Francois';
params.directory.main                = params2change.expDir;
params.directory.stimuli             = params2change.stimDir(1:end-1);
params.directory.save                = params2change.saveDir(1:end-1);
params.directory.subject             = [params.directory.save '/' subjectID];


%% Display parameters
params.display.num                   = params2change.monitorNum;
params.display.viewingDistance       = params2change.viewingDistance;
params.display.size                  = params2change.monitorSize;
params.display.fps                   = params2change.monitorFps;
params.display.ifi                   = params2change.ifi;
params.display.resolution            = [1280 720];
params.display.windowRect            = params2change.windowRect;
params.display.expWindowRect         = params2change.expWindowRect;
params.display.monkWindowRect        = params2change.monkWindowRect;
params.display.expRectCenter         = params2change.expRectCenter;
params.display.monkRectCenter        = params2change.monkRectCenter;
params.display.expRect               = params2change.expRect;
params.display.monkRect              = params2change.monkRect;
params.display.pixPerCm              = params2change.pixPerCm;
params.display.pixPerDeg             = params2change.pixPerDeg;
params.display.grayBackground        = params2change.backgroundColor;
params.display.blackBackground       = [0 0 0];


%% Keyboard shortcuts
key                                  = params2change.keys;
key.names                            = key.names';
key.functions(1)                     = {'abortRun'};
key.functions                        = key.functions';
key.list                             = key.list';
key                                  = renameStructField(key, 'endRun', 'abortRun');
params.key                           = key;


%% Experiment parameters
params.run.startTime                 = [str2double(params2change.saveFilename(end-14:end-11)) str2double(params2change.saveFilename(end-10:end-9)) str2double(params2change.saveFilename(end-8:end-7)) str2double(params2change.saveFilename(end-5:end-4)) str2double(params2change.saveFilename(end-3:end-2)) str2double(params2change.saveFilename(end-1:end))+5];
if params.run.startTime(6) >= 60
    params.run.startTime(6) = params.run.startTime(6) - 60;
    params.run.startTime(5) = params.run.startTime(5) + 1;
end
if params.run.startTime(5) >= 60
    params.run.startTime(5) = params.run.startTime(5) - 60;
    params.run.startTime(4) = params.run.startTime(4) + 1;
end
params.run.endTime                   = params.run.startTime;
params.run.endTime(5)                = params.run.endTime(5) + floor(params2change.calibration.totalDuration/60);
params.run.endTime(6)                = params.run.endTime(6) + round(rem(params2change.calibration.totalDuration,60));
if params.run.endTime(6) >= 60
    params.run.endTime(6) = params.run.endTime(6) - 60;
    params.run.endTime(5) = params.run.endTime(5) + 1;
end
if params.run.endTime(5) >= 60
    params.run.endTime(5) = params.run.endTime(5) - 60;
    params.run.endTime(4) = params.run.endTime(4) + 1;
end

params.run.exactDuration             = round(length(params2change.calibration.log) * params.display.ifi, 1);
params.run.duration                  = params2change.calibration.totalDuration;
params.run.isAborted                 = 1;
params.run.isExperiment              = 0;
params.run.stimContrast              = 0;

params.run.frameIdx = length(params2change.calibration.log);
runLog(:,1) = params2change.calibration.log(:,1);
runLog(:,2) = params2change.calibration.log(:,5);
runLog(:,3) = 1/(params2change.calibration.stimDuration+params2change.calibration.isiDuration);
runLog(:,4) = params2change.calibration.fixWindowSize;
runLog(:,5) = params2change.calibration.stimDuration-params2change.calibration.minFixDuration;
runLog(:,6) = 1;
runLog(:,7) = params2change.calibration.log(:,3);
runLog(:,8) = params2change.calibration.log(:,2);
params.run.log = runLog;

fixWinSize = params2change.calibration.fixWindowSize;
endIdx = length(params2change.calibration.log);
for idx = length(params2change.calibration.keyLog):-1:1
    if params2change.calibration.keyLog(idx,2) == 31 || params2change.calibration.keyLog(idx,2) == 45
        startIdx = find(params2change.calibration.log(:,1)>params2change.calibration.keyLog(idx,1), 1,'first');
        params.run.log(startIdx:endIdx,4) = fixWinSize;
        endIdx = startIdx - 1;
    end
    if params2change.calibration.keyLog(idx,2) == 31
        fixWinSize = fixWinSize - 1;
    elseif params2change.calibration.keyLog(idx,2) == 45
        fixWinSize = fixWinSize + 1;
    end
    params.run.log(1:endIdx,4) = fixWinSize;
end

params.directory.session             = [params.directory.subject '/' datestr(params.run.startTime, 'yyyymmdd')];


%% Fixation parameters
params.run.fixation.eye2track        = params2change.eye2track;
params.run.fixation.windowSize       = params2change.calibration.fixWindowSize;
params.run.fixation.windowColor      = params2change.fixWindowColor;
params.run.fixation.windowRect       = params2change.calibration.fixWindowRect;
params.run.fixation.dotSize          = params2change.calibration.fixDotSize;
params.run.fixation.dotColor         = params2change.fixDotColor;
params.run.fixation.dotOffset        = [0 0];
params.run.fixation.isDotOn          = params2change.calibration.log(end,3);
params.run.fixation.isGridOn         = 1;
params.run.fixation.coordinates      = [];
params.run.fixation.isInWindow       = params2change.calibration.log(end,2);
params.run.fixation.isBroken         = 0;
params.run.fixation.breakStartIdx    = 0;
params.run.fixation.breakTolerance   = params2change.calibration.stimDuration-params2change.calibration.minFixDuration;
params.run.fixation.log              = 0;
[params.run.fixation.log, params.run.fixation.breakStartIdx, params.run.fixation.isBroken] = CalculateFixationDurationsOffline(params);


%% Reward parameters
params.run.reward.TTL                = params2change.DPx.rewardTTL;
params.run.reward.startFrequency     = 1 / (params2change.calibration.stimDuration+params2change.calibration.isiDuration);
params.run.reward.minFrequency       = params.run.reward.startFrequency;
params.run.reward.maxFrequency       = params.run.reward.startFrequency;
params.run.reward.frequency          = params.run.reward.startFrequency;
params.run.reward.frequencyIncrement = 0;
params.run.reward.interval           = 1 / params.run.reward.frequency;
params.run.reward.count              = params2change.calibration.log(end,5);
params.run.reward.maxCount           = params2change.calibration.log(end,4);


clear endIdx fixWinSize idx key runLog startIdx subjectID params2change;

function [session] = SummarizeSession(sessionDir, inputStr)
    
    sessionFiles = dir([sessionDir '/*.mat']);
    numFiles = length(sessionFiles);
    
    fields  = {'runNum', 'duration', 'numTrials', 'numRewards', 'performance', 'fixWindowSize', 'fixBreakTolerance', 'stimDuration', 'isiDuration'};
    values  = cell(length(fields), 1);
    session = cell2struct(values, fields);
    
    for idx = 1:numFiles
        load(sprintf('%s/%s_run%d.mat', sessionDir, inputStr, idx), 'params');
        if idx == 1
            session.subjectID = params.subjectID;
            session.date = params.date;
            eval(sprintf('session.startTime = params.%s.startTime;', inputStr));
        elseif idx == numFiles
            eval(sprintf('session.endTime = params.%s.endTime;', inputStr));
        end
        
        session.runNum                          = [session.runNum; idx];
        eval(sprintf('session.duration          = [session.duration; params.%s.totalDuration];', inputStr));
        eval(sprintf('session.numTrials         = [session.numTrials; params.%s.log(end,2)];', inputStr));
        eval(sprintf('session.numRewards        = [session.numRewards; params.%s.log(end,3)];', inputStr));
        eval(sprintf('session.performance       = [session.performance; (params.%s.log(end,3)/params.%s.log(end,2))*100];', inputStr, inputStr));
        eval(sprintf('session.fixWindowSize     = [session.fixWindowSize; round(mean(params.%s.log(:,4)))];', inputStr));
        eval(sprintf('session.fixBreakTolerance = [session.fixBreakTolerance; round(mean(params.%s.log(:,5)),1)];', inputStr));
        eval(sprintf('session.stimDuration      = [session.stimDuration; round(mean(params.%s.log(:,6)),1)];', inputStr));
        eval(sprintf('session.isiDuration       = [session.isiDuration; round(mean(params.%s.log(:,7)),1)];', inputStr));
    end
    
    session.runNum            = [session.runNum; 0];
    session.duration          = [session.duration; sum(session.duration(:))];
    session.numTrials         = [session.numTrials; sum(session.numTrials(:))];
    session.numRewards        = [session.numRewards; sum(session.numRewards(:))];
    session.performance       = [session.performance; mean(session.performance(:))];
    session.fixWindowSize     = [session.fixWindowSize; round(mean(session.fixWindowSize(:)))];
    session.fixBreakTolerance = [session.fixBreakTolerance; round(mean(session.fixBreakTolerance(:)),1)];
    session.stimDuration      = [session.stimDuration; round(mean(session.stimDuration(:)),1)];
    session.isiDuration       = [session.isiDuration; round(mean(session.isiDuration(:)),1)];
    
end % Function end

% % To add last summary line
% day11.runNum            = [day11.runNum; 0];
% day11.duration          = [day11.duration; sum(day11(:).duration)];
% day11.numTrials         = [day11.numTrials; sum(day11(:).numTrials)];
% day11.numRewards        = [day11.numRewards; sum(day11(:).numRewards)];
% day11.performance       = [day11.performance; mean(day11(:).performance)];
% day11.fixWindowSize     = [day11.fixWindowSize; round(mean(day11(:).fixWindowSize))];
% day11.stimDuration      = [day11.stimDuration; round(mean(day11(:).stimDuration))];
% day11.isiDuration       = [day11.isiDuration; round(mean(day11(:).isiDuration))];
% day11.fixBreakTolerance = [day11.fixBreakTolerance; mean(day11(:).fixBreakTolerance)];
% 
% % To multiplot
% numTrials = [day01.numTrials(end) day02.numTrials(end) day03.numTrials(end) day04.numTrials(end) day05.numTrials(end) day06.numTrials(end) day07.numTrials(end) day08.numTrials(end) day09.numTrials(end) day10.numTrials(end) day11.numTrials(end) day12.numTrials(end) day13.numTrials(end) day14.numTrials(end) day15.numTrials(end) day16.numTrials(end) day17.numTrials(end) day18.numTrials(end) day19.numTrials(end)];
% numRewards = [day01.numRewards(end) day02.numRewards(end) day03.numRewards(end) day04.numRewards(end) day05.numRewards(end) day06.numRewards(end) day07.numRewards(end) day08.numRewards(end) day09.numRewards(end) day10.numRewards(end) day11.numRewards(end) day12.numRewards(end) day13.numRewards(end) day14.numRewards(end) day15.numRewards(end) day16.numRewards(end) day17.numRewards(end) day18.numRewards(end) day19.numRewards(end)];
% performance = [day01.performance(end) day02.performance(end) day03.performance(end) day04.performance(end) day05.performance(end) day06.performance(end) day07.performance(end) day08.performance(end) day09.performance(end) day10.performance(end) day11.performance(end) day12.performance(end) day13.performance(end) day14.performance(end) day15.performance(end) day16.performance(end) day17.performance(end) day18.performance(end) day19.performance(end)];
% fixWindowSize = [day01.fixWindowSize(end) day02.fixWindowSize(end) day03.fixWindowSize(end) day04.fixWindowSize(end) day05.fixWindowSize(end) day06.fixWindowSize(end) day07.fixWindowSize(end) day08.fixWindowSize(end) day09.fixWindowSize(end) day10.fixWindowSize(end) day11.fixWindowSize(end) day12.fixWindowSize(end) day13.fixWindowSize(end) day14.fixWindowSize(end) day15.fixWindowSize(end) day16.fixWindowSize(end) day17.fixWindowSize(end) day18.fixWindowSize(end) day19.fixWindowSize(end)];
% fixBreakTolerance = [day01.fixBreakTolerance(end) day02.fixBreakTolerance(end) day03.fixBreakTolerance(end) day04.fixBreakTolerance(end) day05.fixBreakTolerance(end) day06.fixBreakTolerance(end) day07.fixBreakTolerance(end) day08.fixBreakTolerance(end) day09.fixBreakTolerance(end) day10.fixBreakTolerance(end) day11.fixBreakTolerance(end) day12.fixBreakTolerance(end) day13.fixBreakTolerance(end) day14.fixBreakTolerance(end) day15.fixBreakTolerance(end) day16.fixBreakTolerance(end) day17.fixBreakTolerance(end) day18.fixBreakTolerance(end) day19.fixBreakTolerance(end)];
% stimDuration = [day01.stimDuration(end) day02.stimDuration(end) day03.stimDuration(end) day04.stimDuration(end) day05.stimDuration(end) day06.stimDuration(end) day07.stimDuration(end) day08.stimDuration(end) day09.stimDuration(end) day10.stimDuration(end) day11.stimDuration(end) day12.stimDuration(end) day13.stimDuration(end) day14.stimDuration(end) day15.stimDuration(end) day16.stimDuration(end) day17.stimDuration(end) day18.stimDuration(end) day19.stimDuration(end)];
% isiDuration = [day01.isiDuration(end) day02.isiDuration(end) day03.isiDuration(end) day04.isiDuration(end) day05.isiDuration(end) day06.isiDuration(end) day07.isiDuration(end) day08.isiDuration(end) day09.isiDuration(end) day10.isiDuration(end) day11.isiDuration(end) day12.isiDuration(end) day13.isiDuration(end) day14.isiDuration(end) day15.isiDuration(end) day16.isiDuration(end) day17.isiDuration(end) day18.isiDuration(end) day19.isiDuration(end)];
% 
% day11.fixWindowSize(end,:) = [round(mean(day11.fixWindowSize(1:end-1,1))) round(mean(day11.fixWindowSize(1:end-1,2)))];
% day11.stimDuration(end,:) = [round(mean(day11.stimDuration(1:end-1,1))) round(mean(day11.stimDuration(1:end-1,2)))];
% day11.isiDuration(end,:) = [round(mean(day11.isiDuration(1:end-1,1))) round(mean(day11.isiDuration(1:end-1,2)))];
% day11.fixBreakTolerance(end,:) = [mean(day11.fixBreakTolerance(1:end-1,1)) mean(day11.fixBreakTolerance(1:end-1,2))];
% 
% 
% 
% % Manual edit for days 2-10
% sessionDir = '/Users/ocakb2/Library/Mobile Documents/com~apple~CloudDocs/Github/pRF_mapping/results/Francois/20200908';
% sessionFiles = dir(sessionDir);
% sessionFiles(1:2) = [];
% 
% fields  = {'runNum', 'duration', 'numTrials', 'numRewards', 'performance', 'fixWindowSize', 'fixBreakTolerance', 'stimDuration', 'isiDuration'};
% values  = cell(length(fields), 1);
% session = cell2struct(values, fields);
% session.subjectID = 'Francois';
% session.date      = '20200904';
% session.startTime = '150201';
% session.endTime   = '155247';
% 
% idx = 8;
% load([sessionFiles(idx).folder '/' sessionFiles(idx).name], 'params');
% test = diff(params.calibration.keyLog(:,1));
% 
% find(params.calibration.keyLog(:,2)==31)
% find(params.calibration.keyLog(:,2)==45)
% find(params.calibration.keyLog(:,2)==25)
% find(params.calibration.keyLog(:,2)==39)
% find(params.calibration.keyLog(:,2)==26)
% find(params.calibration.keyLog(:,2)==40)
% find(params.calibration.keyLog(:,2)==27)
% find(params.calibration.keyLog(:,2)==41)
% 
% session.runNum            = [session.runNum; idx];
% session.duration          = [session.duration; params.calibration.totalDuration];
% session.numTrials         = [session.numTrials; params.calibration.log(end,4)];
% session.numRewards        = [session.numRewards; params.calibration.log(end,5)];
% session.performance       = [session.performance; (params.calibration.log(end,5)/params.calibration.log(end,4))*100];
% session.fixWindowSize     = [session.fixWindowSize; 5];
% session.fixBreakTolerance = [session.fixBreakTolerance; 1.3];
% session.stimDuration      = [session.stimDuration; 3];
% session.isiDuration       = [session.isiDuration; 0];
% 
% session.runNum            = [session.runNum; 0];
% session.duration          = [session.duration; sum(session.duration(:))];
% session.numTrials         = [session.numTrials; sum(session.numTrials(:))];
% session.numRewards        = [session.numRewards; sum(session.numRewards(:))];
% session.performance       = [session.performance; mean(session.performance(:))];
% session.fixWindowSize     = [session.fixWindowSize; round(mean(session.fixWindowSize(:)))];
% session.fixBreakTolerance = [session.fixBreakTolerance; round(mean(session.fixBreakTolerance(:)),1)];
% session.stimDuration      = [session.stimDuration; round(mean(session.stimDuration(:)),1)];
% session.isiDuration       = [session.isiDuration; round(mean(session.isiDuration(:)),1)];

% 
% 
% 
% % Table
% struct2table(rmfield(day11, {'date' 'startTime' 'endTime'}))
























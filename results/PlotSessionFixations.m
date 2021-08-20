function [figureHandle] = PlotSessionFixations(sessionDate, subjectID)
    
    saveDir = fileparts(mfilename('fullpath'));
    sessionDir = [saveDir '/' subjectID '/' sessionDate];
    if ~exist(sessionDir, 'dir')
        error('Session files not found! Input 1 must be an existing session date, input 2 must be an existing subject ID.');
    end
    
    fixationDurations = [];
    for idx = 1:length(dir([sessionDir '/*.mat']))
        filename = [sessionDir '/' 'run' num2str(idx) '_calibration' '.mat'];
        if ~exist(filename, 'file')
            filename = [sessionDir '/' 'run' num2str(idx) '_experiment' '.mat'];
        end
        load(filename, 'params');
        fixationDurations = [fixationDurations; params.run.fixation.log(find(params.run.fixation.log(:,1)>1),1)];
        if idx == 1
            startTime = params.run.startTime;
        elseif idx == length(dir([sessionDir '/*.mat']))
            endTime   = params.run.endTime;
        end
    end
    
    subjectDir = [saveDir '/' subjectID];
    subjectSessions = dir([subjectDir '/20*']);
    sessionNum = find(strcmp({subjectSessions.name}, sessionDate));
    
    figureHandle = figure;
    histogram(fixationDurations, 'BinWidth', 10);
    xlim([0 300]);
    ylim([0 50]);
    xlabel('Seconds');
    ylabel('Count');
    xticks(0:10:300);
    yticks(0:5:50);
    title(sprintf('Distribution of fixation durations - Day %d (%d minutes)', sessionNum, round(etime(endTime,startTime)/60)));
    set(gca, 'fontsize', 14);
    
end % Function end

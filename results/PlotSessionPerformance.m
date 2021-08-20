function [figureHandle] = PlotSessionPerformance(subjectID, sessionDate)
    
    saveDir = fileparts(mfilename('fullpath'));
    sessionDir = [saveDir '/' subjectID '/' sessionDate];
    if ~exist(sessionDir, 'dir')
        error('Session files not found! Input 1 must be an existing subject ID and input 2 must be an existing session date.');
    end
    
    sessionPerformance = [];
    for idx = 1:length(dir([sessionDir '/*.mat']))
        filename = [sessionDir '/' 'run' num2str(idx) '_calibration' '.mat'];
        if ~exist(filename, 'file')
            filename = [sessionDir '/' 'run' num2str(idx) '_experiment' '.mat'];
        end
        load(filename, 'params');
        sessionPerformance = [sessionPerformance; (sum(params.run.fixation.log)/params.run.duration)*100];
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
    plot(1:length(sessionPerformance), sessionPerformance, '-s', 'LineWidth', 2, 'MarkerSize', 10);
    xlim([1 length(sessionPerformance)]);
    ylim([0 100]);
    xlabel('Run #');
    ylabel('Time in fixation window (%)');
    xticks(1:1:length(sessionPerformance));
    yticks(0:10:100);
    title(sprintf('Run performances - Session #%d (%d minutes)', sessionNum, round(etime(endTime,startTime)/60)));
    set(gca, 'fontsize', 14);
    
end % Function end

clear session;
saveDir = pwd;
allSessionsDir = dir([saveDir '/' 'Francois' '/' '20*']);

for idx = 1:length(allSessionsDir)-2
    sessionDir = dir([allSessionsDir(idx).folder '/' allSessionsDir(idx).name '/' '*_run*.mat']);
    for runIdx = 1:length(sessionDir)
        load([sessionDir(runIdx).folder '/' 'calibration_run' num2str(runIdx) '.mat'], 'params');
        session(idx).run(runIdx) = params;
    end
end
sessionDir = dir([allSessionsDir(end-1).folder '/' allSessionsDir(end-1).name '/' '*_run*.mat']);
for runIdx = 1:length(sessionDir)
    load([sessionDir(runIdx).folder '/' 'experiment_run' num2str(runIdx) '.mat'], 'params');
    session(length(allSessionsDir)-1).run(runIdx) = params;
end
sessionDir = dir([allSessionsDir(end).folder '/' allSessionsDir(end).name '/' '*_run*.mat']);
for runIdx = 1:length(sessionDir)
    load([sessionDir(runIdx).folder '/' 'experiment_run' num2str(runIdx) '.mat'], 'params');
    session(length(allSessionsDir)).run(runIdx) = params;
end


sessionsDurations = [];
sessionsRewards = [];
sessionsPerformance = [];
sessionsFixWindow = [];
sessionsBreakTolerance = [];
for idx = 1:length(session)
    sessionsDurations = [sessionsDurations round(etime(session(idx).run(end).run.endTime, session(idx).run(1).run.startTime)/60)];
    
    numRewards = [];
    performance = [];
    fixWin = [];
    breakTolerance = [];
    for idx2 = 1:length(session(idx).run)
        numRewards = [numRewards session(idx).run(idx2).reward.count];
        performance = [performance (sum(session(idx).run(idx2).fixation.log)/300)*100];
        fixWin = [fixWin round(mean(session(idx).run(idx2).run.log(:,4),'omitnan'))];
        breakTolerance = [breakTolerance mean(session(idx).run(idx2).run.log(:,5),'omitnan')];
    end
    sessionsRewards = [sessionsRewards sum(numRewards)];
    sessionsPerformance = [sessionsPerformance mean(performance)];
    sessionsFixWindow = [sessionsFixWindow round(mean(fixWin))];
    sessionsBreakTolerance = [sessionsBreakTolerance round(mean(breakTolerance),2)];
end

ylabels{1}='Minutes';
ylabels{2}='Reward count';
ylabels{3}='Degrees and seconds';
x1 = 20:length(session);
plotyyy({x1,sessionsDurations(20:end)}, {x1,sessionsRewards(20:end)}, {x1,sessionsFixWindow(20:end), x1,sessionsBreakTolerance(20:end)}, ylabels);



allPerformances = [];
for idx = 20:length(session)
    performance = NaN(1,12);
    for idx2 = 1:length(session(idx).run)
        performance(idx2) = (sum(session(idx).run(idx2).fixation.log)/session(idx).run(idx2).run.endDuration)*100;
    end
    allPerformances = [allPerformances; performance];
end

bar(1:12,allPerformances(9,:))
xlim([0 13]);
ylim([0 100]);
xlabel('Run');
ylabel('Percent of the run');
xticks(1:12);
yticks(0:10:100);
title(sprintf('Fixation performance - Day 28'));
set(gca, 'fontsize', 14);

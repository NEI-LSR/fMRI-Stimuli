function [params] = generateRunInfo(params)
    % Stuart J Duffield December 2022
    % A paired function for ShapeColorAttentionV3 that generates and saves
    % summary statistics and saves them 

    % Prep table variables
    Run = repmat(params.runNum,params.numblocks,1); % Create column vector of run number
    IMA = repmat(params.IMA,params.numblocks,1); % Create column vector of IMA number
    Subject = repmat(string(params.subject),params.numblocks,1); % Create column vector of subject
    Session = repmat(string(params.sessionDate),params.numblocks,1); % Create column vector of sessions
    Blocknumber = [1:params.numblocks]'; % Create column vector of block numbers
    Blocktype = params.blockNames'; % Create column vector of block types
    Stimulus = params.orderNames'; % Create column vector of stimulus names
    StimulusDuration = repmat(params.stimDur,params.numblocks,1); % Create column vector of stimulus durations
    GrayDuration = repmat(params.grayDur,params.numblocks,1); % Create column vector of gray durations
    ITIDuration = repmat(params.ITIdur,params.numblocks,1); % Create column vector of ITI durations
    ChoiceDuration = repmat(params.choiceSectionDur,params.numblocks,1); % Create column vector of choice durations
    ProbeTrial = params.probeArray'; % Column vector of the trial type: probe or not
    CorrectLocation = strings(params.numblocks,1); % Initialize column vector of correct locations
    choices = ["UpperRight","LowerRight","LowerLeft","UpperLeft"];
    CorrectLocation(params.probeArray) = choices(params.correctSideChoices); % Store location
    UpperRightChoice = strings(params.numblocks,1); UpperRightChoice(params.probeArray) = params.choiceStimuliNames(:,1); % What was the upper right choice
    LowerRightChoice = strings(params.numblocks,1); LowerRightChoice(params.probeArray) = params.choiceStimuliNames(:,2); % What was lower right choice
    LowerLeftChoice = strings(params.numblocks,1); LowerLeftChoice(params.probeArray) = params.choiceStimuliNames(:,3); % What was the lower left choice
    UpperLeftChoice = strings(params.numblocks,1); UpperLeftChoice(params.probeArray) = params.choiceStimuliNames(:,4); % What was the upper left choice
    CorrectChoiceStim = strings(params.numblocks,1); CorrectChoiceStim(params.probeArray) = params.correctChoiceStimuliNames; % What was the correct stimulus choice
    choices_withNone = ["None" choices];
    ChoiceLocation = choices_withNone(params.sideChoices + 1)'; % Chosen location
    choiceStimuli_withNone = [repmat("None",size(params.choiceStimuliNames,1),1) params.choiceStimuliNames];
    rows = [1:size(choiceStimuli_withNone,1)]'; columns = params.sideChoices+1;
    ChoiceStimuli = choiceStimuli_withNone(sub2ind(size(choiceStimuli_withNone),rows,columns)); % What were the chosen stimuli
    Correct = NaN(params.numblocks,1); Correct(params.probeArray) = (params.sideChoices==params.correctSideChoices); % Was the trial correct
    Complete = repmat(params.complete,params.numblocks,1);

    % Calculate percent fixation and save out eyetrace
    pixPerDeg = 1920/(rad2deg(atan(1/57))*38.2); % Calculate the true pixels per degree
    screenWidth = 1920; % Screen width
    screenHeight = 1080; % Screen height
    blocklength = params.blocklength;
    stimDur = params.stimDur;
    numTRs = ceil(params.runDur/params.TR);
    xdata = params.eyePosition(:,1);
    ydata = params.eyePosition(:,2);
    distance = hypot(xdata-(screenWidth/2),ydata-(screenHeight/2))/pixPerDeg;
    times = params.timeTracker;
    runnum = params.runNum;
    plot(times,distance);
    ylim([0,5]);
    ylabel('DvA from Fixation');
    xlabel('Time (s)');
    sessiondate = params.sessionDate;
    title([sessiondate ' Run ' num2str(runnum)]);
    saveas(gcf,params.eyeTraceSaveFile);

    fixation_TR = NaN(numTRs,1);
    fixation_stim = NaN(params.numblocks,1);
    median_dist_TR = NaN(numTRs,1);
    median_dist_stim = NaN(params.numblocks,1);
    TR_indices = ceil(times/params.TR);
    stim_indices = params.blockTracker(params.subBlockTracker == "Stimulus");
    for y = 1:numTRs
        distances_TR = distance(TR_indices == y);
        fixation_TR(y) = mean(distances_TR<1,'omitnan');
        median_dist_TR(y) = median(distances_TR,'omitnan');
    end
    for y = 1:params.numblocks
        distances_block = distance(stim_indices == y);
        fixation_stim(y) = mean(distances_block<1, 'omitnan');
        median_dist_stim(y) = median(distances_block,'omitnan');
    end
    
    PercentFixationStim = fixation_stim;
    MedianDistanceStim = median_dist_stim;

    summaryTable = table(Run,IMA,Subject,Session,Blocknumber,Blocktype,Stimulus,ProbeTrial,Correct,StimulusDuration,GrayDuration,ChoiceDuration,ITIDuration,CorrectLocation,UpperRightChoice,LowerRightChoice,LowerLeftChoice,UpperLeftChoice,CorrectChoiceStim,ChoiceLocation,ChoiceStimuli,PercentFixationStim,MedianDistanceStim,Complete);

    writetable(summaryTable,params.summaryTableSaveFile,'Delimiter',',');
    writetable(table(median_dist_TR,'VariableNames',{num2str(params.IMA)}),params.eyeTraceDistanceDMSaveFile,'Delimiter',',');
    writetable(table(fixation_TR,'VariableNames',{num2str(params.IMA)}),params.eyeTraceFixationDMSaveFile,'Delimiter',',');

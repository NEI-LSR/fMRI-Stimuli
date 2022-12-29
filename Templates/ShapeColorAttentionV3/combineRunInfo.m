function [params] = combineRunInfo(params)
    % Stuart J Duffield December 2022
    % Combines behavioral table data
    resultsFilesStruct = dir(fullfile(params.resultsDir,['*_Results.csv']));
    eyetraceFileStruct = dir(fullfile(params.resultsDir,['*_eyeDistance.csv']));
    eyefixationFileStruct = dir(fullfile(params.resultsDir,['*_eyeFixation.csv']));
    resultsFiles = extractfield(resultsFilesStruct,'name');
    eyetraceFiles = extractfield(eyetraceFileStruct,'name');
    eyefixationfiles = extractfield(eyefixationFileStruct,'name');

    if length(resultsFiles) > 1 
        resultTable = readtable(fullfile(params.resultsDir,resultsFiles{1}));

        for i = 2:length(resultsFiles)
            resultTable = vertcat(resultTable,readtable(fullfile(params.resultsDir,resultsFiles{i})));
        end
    else
        resultTable = readtable(fullfile(params.resultsDir,resultsFiles{1}));
    end

    if length(eyetraceFiles) > 1
        eyetraceTable = readtable(fullfile(params.resultsDir,eyetraceFiles{1}));
        for i = 2:length(eyetraceFiles)
            eyetraceTable = horzcat(eyetraceTable,readtable(fullfile(params.resultsDir,eyetraceFiles{i})));
        end
    else
        eyetraceTable = readtable(fullfile(params.resultsDir,eyetraceFiles{1}));
    end

    if length(eyefixationfiles) > 1
        eyefixationTable = readtable(fullfile(params.resultsDir,eyefixationfiles{1}));
        for i = 2:length(eyefixationfiles)
            eyefixationTable = horzcat(eyefixationTable,readtable(fullfile(params.resultsDir,eyefixationfiles{i})));
        end
    else
        eyefixationTable = readtable(fullfile(params.resultsDir,eyefixationfiles{1}));
    end

    writetable(resultTable,fullfile(params.resultsDir,'SessionResults.csv'));
    writetable(eyetraceTable,fullfile(params.resultsDir,'SessionEyetraces.csv'));
    writetable(eyefixationTable,fullfile(params.resultsDir,'SessionEyefixation.csv'));

    % Write out summary statistics
    disp('Summary of performance by stimulus type')
    groupsummary(resultTable(resultTable.Complete==1,:),["Blocktype","Stimulus"],["mean","sum"],'Correct')
    
    disp('Summary of performance by blocktype')
    groupsummary(resultTable(resultTable.Complete==1,:),"Blocktype",["mean","sum"],'Correct')



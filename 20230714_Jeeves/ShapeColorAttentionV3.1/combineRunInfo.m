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
        temptable = table2array(readtable(fullfile(params.resultsDir,eyetraceFiles{1})));
        IMAnum = char(string(temptable(1)));
        eyetraceTable = readtable(fullfile(params.resultsDir,eyetraceFiles{1}),'NumHeaderLines',1);
        eyetraceTable.Properties.VariableNames{1} = IMAnum;
        for i = 2:length(eyetraceFiles)
            temptable = table2array(readtable(fullfile(params.resultsDir,eyetraceFiles{i})));
            IMAnum = char(string(temptable(1)));
            eyetraceTable = horzcat(eyetraceTable,readtable(fullfile(params.resultsDir,eyetraceFiles{i}),'NumHeaderLines',1));
            eyetraceTable.Properties.VariableNames{i} = IMAnum;
        end
    else
        temptable = table2array(readtable(fullfile(params.resultsDir,eyetraceFiles{1})));
        IMAnum = char(string(temptable(1)));
        eyetraceTable = readtable(fullfile(params.resultsDir,eyetraceFiles{1}),'NumHeaderLines',1);
        eyetraceTable.Properties.VariableNames{1} = IMAnum;    
    end

    if length(eyefixationfiles) > 1
        temptable = table2array(readtable(fullfile(params.resultsDir,eyefixationfiles{1})));
        IMAnum = char(string(temptable(1)));
        eyefixationTable = readtable(fullfile(params.resultsDir,eyefixationfiles{1}),'NumHeaderLines',1);
        eyefixationTable.Properties.VariableNames{1} = IMAnum;
        for i = 2:length(eyefixationfiles)
            temptable = table2array(readtable(fullfile(params.resultsDir,eyefixationfiles{i})));
            IMAnum = char(string(temptable(1)));
            eyefixationTable = horzcat(eyefixationTable,readtable(fullfile(params.resultsDir,eyefixationfiles{i}),'NumHeaderLines',1));
            eyefixationTable.Properties.VariableNames{i} = IMAnum;
        end
    else
        temptable = table2array(readtable(fullfile(params.resultsDir,eyefixationfiles{1})));
        IMAnum = char(string(temptable(1)));
        eyefixationTable = readtable(fullfile(params.resultsDir,eyefixationfiles{1}),'NumHeaderLines',1);
        eyefixationTable.Properties.VariableNames{1} = IMAnum;    
    end

    params.resultTable = resultTable; % Send this back as a parameter so you can actually view all the details

    writetable(resultTable,fullfile(params.resultsDir,'SessionResults.csv'));
    writetable(eyetraceTable,fullfile(params.resultsDir,'SessionEyetraces.csv'));
    writetable(eyefixationTable,fullfile(params.resultsDir,'SessionEyefixation.csv'));

    % Write out summary statistics
    disp('Summary of performance by stimulus type')
    groupsummary(resultTable(resultTable.Complete==1,:),["Blocktype","Stimulus"],["mean","sum"],'Correct')
    
    disp('Summary of performance by blocktype')
    groupsummary(resultTable(resultTable.Complete==1,:),"Blocktype",["mean","sum"],'Correct')



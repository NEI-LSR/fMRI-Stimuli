function combineDMs(params)
% Combines all the DMs in the Data Directory
warning('off','all');
DMs = dir(fullfile(params.dataDir,[params.subject '*_DM.txt']));
if length(DMs) > 0
    DM_files = extractfield(DMs,'name');
    DM = readtable(fullfile(params.dataDir,DM_files{1}),"NumHeaderLines",0,"Delimiter","\t");
    for i = 2:length(DM_files)
        DM = [DM readtable(fullfile(params.dataDir,DM_files{i}),"NumHeaderLines",0,"Delimiter","\t")];
    end
    writetable(DM,fullfile(params.dataDir,"DM.txt"),"Delimiter","\t")
else
    disp('No DM files. Continuing.')
end
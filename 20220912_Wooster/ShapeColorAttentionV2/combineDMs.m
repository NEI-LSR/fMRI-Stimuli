function combineDMs(params)
% Combines all the DMs in the Data Directory

params.dataDir = 'C:\Users\duffieldsj\Documents\GitHub\fMRI-Stimuli\20220912_Wooster\ShapeColorAttentionV2\Data'
DMs = dir(fullfile(params.dataDir,[params.subject '*_DM.txt']));
DM_files = extractfield(DMs,'name');
DM = readtable(fullfile(params.dataDir,DM_files{1}));
for i = 2:length(DM_files)
    DM = [DM readtable(fullfile(params.dataDir,DM_files{i}),"NumHeaderLines",0,"Delimiter","\t")];
end
params.dataDir = 'C:\Users\duffieldsj\Documents\GitHub\fMRI-Stimuli\20220912_Wooster\ShapeColorAttentionV2\Data'
writetable(DM,fullfile(params.dataDir,"DM.txt"),"Delimiter","\t")
function combineDMs_noparams(directory)
% Combines all the DMs in the Data Directory
datadir = fullfile(directory,'Data')

DMs = dir(fullfile(datadir,['*_DM.txt']));
DM_files = extractfield(DMs,'name');
DM = readtable(fullfile(datadir,DM_files{1}));
for i = 2:length(DM_files)
    DM = [DM readtable(fullfile(datadir,DM_files{i}),"NumHeaderLines",0,"Delimiter","\t")];
end
writetable(DM,fullfile(datadir,"DM.txt"),"Delimiter","\t")
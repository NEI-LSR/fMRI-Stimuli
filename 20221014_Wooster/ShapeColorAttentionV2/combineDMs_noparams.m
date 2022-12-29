function combineDMs_noparams(directory)
% Combines all the DMs in the Data Directory
datadir = fullfile(directory,'Data')

DMs = dir(fullfile(datadir,['*_DM.txt']));
DM_files = extractfield(DMs,'name');
DM = readtable(fullfile(datadir,DM_files{1}),"NumHeaderLines",0,"Delimiter","\t");
disp(['IMA ' num2str(2) ' has ' num2str(size(DM,1)) ' TRs'])
for i = 2:length(DM_files)
    temp = readtable(fullfile(datadir,DM_files{i}),"NumHeaderLines",0,"Delimiter","\t");
    disp(['IMA ' num2str(i+1) ' has ' num2str(size(temp,1)) ' TRs'])
    DM = [DM temp];
    
end
writetable(DM,fullfile(datadir,"DM.txt"),"Delimiter","\t")
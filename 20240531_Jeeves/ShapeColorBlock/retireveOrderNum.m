% Finding out what order it is for each run
blockorders = csvread('block_design.csv');
di = pwd;
ddi = fullfile(di,"Data");
files = dir(ddi);
names = extractfield(files,'name');
for i = 1:length(names)
    if contains(names(i),'.mat');
        load(fullfile(ddi,names(i)));
        ordernum = find(all((blockorder+1) == blockorders,2));
        disp([names{i} ' ' num2str(ordernum)])
    end
end




di = pwd;
erdi = fullfile(di,"EyeRecords");
files = dir(erdi);
for i = 1:length(files)
    if contains(files(i).name,'.mat')
        load(fullfile(erdi,files(i).name));
        figure()
        plot(eyeRecord.time,eyeRecord.x);
        hold on
        plot(eyeRecord.time,eyeRecord.y);
    end
end


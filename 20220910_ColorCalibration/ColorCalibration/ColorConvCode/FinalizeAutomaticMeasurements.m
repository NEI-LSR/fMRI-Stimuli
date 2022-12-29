folder = 'C:\Users\duffieldsj\Documents\GitHub\fMRI-Stimuli\20220910_ColorCalibration\ColorCalibration\ColorConvCode\automaticMeasurements';
saveDir = 'C:\Users\duffieldsj\Documents\GitHub\fMRI-Stimuli\20220910_ColorCalibration\ColorCalibration\ColorConvCode\finalValues';
file = '10-Sep-2022_14_22_39';
extension = 'DKL8ColorBiasedRegionLocalizerColors_Lumcontrast'
load(fullfile(folder,[file '.mat']));

if ~isfolder(saveDir)
    mkdir(saveDir);
end

finalMeasurements = measurements([]);

colorNumbers = extractfield(measurements,'colorNumber');
magnitudeDiffs= extractfield(measurements,'magnitudeDiff');

for i = 1:max(colorNumbers)
    selectedMagDiffs = magnitudeDiffs(colorNumbers==i);
    [~,index_color] = min(selectedMagDiffs);
    index = index_color+min(find(colorNumbers==i))-1;
    finalMeasurements(i) = measurements(index);
end

save(fullfile(folder,[file '_BestMeasures.mat']));
LMS = reshape(extractfield(finalMeasurements, 'LMS'),[],length(finalMeasurements))';
xyYJudd = reshape(extractfield(finalMeasurements, 'xyYJudd'),[],length(finalMeasurements))';
XYZJudd = reshape(extractfield(finalMeasurements, 'XYZJudd'),[],length(finalMeasurements))';

csvwrite([saveDir '\' extension '_Final_LMS.csv'],LMS);
csvwrite([saveDir '\' extension '_Final_xyYJudd.csv'],xyYJudd);
csvwrite([saveDir '\' extension '_Final_XYZJudd.csv'],XYZJudd);




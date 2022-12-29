%% Plot DKL
measurementDir = 'manualMeasurements\'
measurementFile = '03-Feb-2022_17_31_26.mat'
precisionFile = '03-Feb-2022_19_16_22.mat'
load([measurementDir precisionFile]);
precisions = measurements;
load([measurementDir measurementFile]);

mNums_09 = [16 34 49 60 72 100 111 117];
mNums_05 = [122 133 147 155 167 182 195 215];



LMS = reshape(extractfield(measurements, 'LMS'),3,[]);
LMS_gray = reshape(extractfield(precisions, 'LMS'),3,[]);
LMS_09 = LMS(:,mNums_09);
LMS_05 = LMS(:,mNums_05);
LMS_09_targ = lms_nums;
DKL_09 = M_ConeIncToDKL*LMS_09;
DKL_05 = M_ConeIncToDKL*LMS_05;
DKL_gray = M_ConeIncToDKL*LMS_gray;
DKL_09_targ = M_ConeIncToDKL*LMS_09_targ';


scatter(DKL_09(2,:),DKL_09(3,:))
hold on
scatter(DKL_05(2,:),DKL_05(3,:))
scatter(DKL_gray(2,:),DKL_gray(3,:))
scatter(DKL_09_targ(2,:),DKL_09_targ(3,:))


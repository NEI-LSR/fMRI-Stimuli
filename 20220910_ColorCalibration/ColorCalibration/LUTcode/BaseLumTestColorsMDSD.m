function [LumValues] = BaseLumMD()
global windowPTR bitDepth fileroot values

% from the BaseLum255 code but adapted for 16 bits as well

% Runs through R G B gun values and takes luminance values, returns array with values
% Use in first steps of Calibration 

whichScreen= 0%max(Screen('Screens')); %0

Screen('Preference', 'SkipSyncTests', 1);

[windowPTR ,screenRect] = Screen('Openwindow',whichScreen,round(((2^bitDepth)-1)/2),[],32,2);
%[windowPTR,screenRect] = Screen('Openwindow',whichScreen,round(((2^bitDepth)-1)/2),[0 0 400 400],32,2);

LumValues = [];
for i = 1:size(values,1)
    [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([values(i,:)]);
    LumValues.colors(i,1).gunValues = [values(i,:)];
	LumValues.colors(i,1).xyYcie = xyYcie;
	LumValues.colors(i,1).xyYJudd = xyYJudd;
	LumValues.colors(i,1).Spectrum = Spectrum;
end
[xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([255,255,255]);
LumValues.white(1,1).gunValues = [255,255,255];
LumValues.white(1,1).xyYcie = xyYcie;
LumValues.white(1,1).xyYJudd = xyYJudd;
LumValues.white(1,1).Spectrum = Spectrum;

[xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([0,0,0]);
LumValues.black(1,1).gunValues = [0,0,0];
LumValues.black(1,1).xyYcie = xyYcie;
LumValues.black(1,1).xyYJudd = xyYJudd;
LumValues.black(1,1).Spectrum = Spectrum;
disp(LumValues)


save([fileroot, '.mat'], 'LumValues');
Screen('CloseAll');
PR655close()

end 
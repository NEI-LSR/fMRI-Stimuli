function [LumValues] = BaseLumMD()
global windowPTR bitDepth fileroot values

% from the BaseLum255 code but adapted for 16 bits as well

% Runs through R G B gun values and takes luminance values, returns array with values
% Use in first steps of Calibration 
try
    whichScreen=max(Screen('Screens')); %0

    Screen('Preference', 'SkipSyncTests', 1);

    [windowPTR ,screenRect] = Screen('Openwindow',whichScreen,round(((2^bitDepth)-1)/2),[],32,2);
    %[windowPTR,screenRect] = Screen('Openwindow',whichScreen,round(((2^bitDepth)-1)/2),[0 0 400 400],32,2);

    LumValues = [];
    for g = 1:4
    reading = 1;
        for i = 1:numel(values)
            if g == 1
            [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([values(i) 0 0]);
            LumValues.red(reading,1).gunValue = values(i);
            LumValues.red(reading,1).xyYcie = xyYcie;
            LumValues.red(reading,1).xyYJudd = xyYJudd;
            LumValues.red(reading,1).Spectrum = Spectrum;

            elseif g == 2
            [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([0 values(i) 0]);
            LumValues.green(reading,1).gunValue = values(i);
            LumValues.green(reading,1).xyYcie = xyYcie;
            LumValues.green(reading,1).xyYJudd = xyYJudd;
            LumValues.green(reading,1).Spectrum = Spectrum;

            elseif g == 3
            [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([0 0 values(i)]);
            LumValues.blue(reading,1).gunValue = values(i);
            LumValues.blue(reading,1).xyYcie = xyYcie;
            LumValues.blue(reading,1).xyYJudd = xyYJudd;
            LumValues.blue(reading,1).Spectrum = Spectrum;

            elseif g == 4
            [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([values(i) values(i) values(i)]);
            LumValues.white(reading,1).gunValue = values(i);
            LumValues.white(reading,1).xyYcie = xyYcie;
            LumValues.white(reading,1).xyYJudd = xyYJudd;
            LumValues.white(reading,1).Spectrum = Spectrum;

            end
            reading = reading + 1;
            disp(LumValues)
        end
    end
catch me
    sca
    rethrow(me)
end
save([fileroot, '.mat'], 'LumValues');
Screen('CloseAll');
PR655close()

end 
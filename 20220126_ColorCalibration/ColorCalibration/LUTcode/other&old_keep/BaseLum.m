function [LumValues] = BaseLumNew
global windowPTR gray PRport
% Runs through R G B gun values and takes luminance values, returns array with values
% Use in first steps of Calibration


dbstop if error
PRport = 'COM4';
gray = [49360 49581 49849];
Screen('Preference', 'SkipSyncTests', 1);
whichScreen= max(Screen('Screens'));
loadLUT = 0;

[file,path] = uiputfile; 

if loadLUT 
	load('LUT.mat');
	eightBitMode = false;
else
	eightBitMode = true;
end

[windowPTR,screenRect] = Screen('Openwindow',whichScreen,32768,[],32,2);
LumValues = [];
for g = 1:3
    reading = 1;
    for i = 0:2500:65535 
        switch g
            case 1
				if ~eightBitMode
					[xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([LUT(i+1,1) 0 0]);
					LumValues.red(reading,1).gunValue = [LUT(i+1,1)];
				else
					LumValues.red(reading,1).gunValue = i;
				end
					
                
                LumValues.red(reading,1).xyYcie = xyYcie;
                LumValues.red(reading,1).xyYJudd = xyYJudd;
                LumValues.red(reading,1).Spectrum = Spectrum;
                if i == 65000
                    [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([LUT(65536,1) 0 0]);
                    LumValues.red(reading+1,1).gunValue = 65535;
                    LumValues.red(reading+1,1).xyYcie = xyYcie;
                    LumValues.red(reading+1,1).xyYJudd = xyYJudd;
                    LumValues.red(reading+1,1).Spectrum = Spectrum;
                end
            case 2
                [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([0 LUT(i+1,2) 0]);
                LumValues.green(reading,1).gunValue = [LUT(i+1,2)];
                LumValues.green(reading,1).xyYcie = xyYcie;
                LumValues.green(reading,1).xyYJudd = xyYJudd;
                LumValues.green(reading,1).Spectrum = Spectrum;
                if i == 65000
                    [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([0 LUT(65536,1) 0]);
                    LumValues.green(reading+1,1).gunValue = 65535;
                    LumValues.green(reading+1,1).xyYcie = xyYcie;
                    LumValues.green(reading+1,1).xyYJudd = xyYJudd;
                    LumValues.green(reading+1,1).Spectrum = Spectrum;
                end
            case 3
                [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([0 0 LUT(i+1,3)]);
                LumValues.blue(reading,1).gunValue = [LUT(i+1,3)];
                LumValues.blue(reading,1).xyYcie = xyYcie;
                LumValues.blue(reading,1).xyYJudd = xyYJudd;
                LumValues.blue(reading,1).Spectrum = Spectrum;
                if i == 65000
                    [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([0 0 LUT(65536,1)]);
                    LumValues.blue(reading+1,1).gunValue = 65535;
                    LumValues.blue(reading+1,1).xyYcie = xyYcie;
                    LumValues.blue(reading+1,1).xyYJudd = xyYJudd;
                    LumValues.blue(reading+1,1).Spectrum = Spectrum;
                end
                %{
            case 4
                 [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([i i i]);
                LumValues.white(reading,1).gunValue = i;
                LumValues.white(reading,1).xyYcie = xyYcie;
                LumValues.white(reading,1).xyYJudd = xyYJudd;
                LumValues.white(reading,1).Spectrum = Spectrum;
                if i == 65000
                    [xyYcie, xyYJudd, Spectrum] = JoshCalibforBL([65535 65535 65535]);
                    LumValues.white(reading+1,1).gunValue = i;
                    LumValues.white(reading+1,1).xyYcie = xyYcie;
                    LumValues.white(reading+1,1).xyYJudd = xyYJudd;
                    LumValues.white(reading+1,1).Spectrum = Spectrum;
                end
             %}   
        end
        reading = reading + 1;
        disp(LumValues)
    end
end

save([path, date, '_', file], 'LumValues');
Screen('CloseAll'); 

end 
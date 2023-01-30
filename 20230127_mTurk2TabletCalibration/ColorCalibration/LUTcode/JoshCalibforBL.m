function [xyYcie, xyYJudd, spec] = JoshCalibforBL(colors)
% Josh's combined calibration scripts.
% displays colors on screen, measures using PR, reads data from PR, calls modified s2j script and returns xyY values
global PRport bitDepth
% Make sure we're connected to the device. Connect if we're not
try 
	PR655getsyncfreq
catch
	PR655init(PRport)
end

% Call colorpatch program
switch bitDepth
	case 8
		bsuccess = CPforBL255(colors);
	case 16
		bsuccess = CPforBL(colors);

end


if bsuccess == 1
	%spec = PR655measspd([],[380 5 81]);
	PR655write('M5')
else
	disp('something broke. oops')
end

clear spd;
[spec] = getPRValues();

%disp(psd)
spec = PR655parsespdstrJ(spec);
%rawSpec = spec;
clear xyYJudd 
clear xyYcie
[xyYJudd] = s2jJudd(spec);
[xyYcie] = s2jcie(spec);

%Screen('CloseAll');
%close all; 
clear spd;

%function [spec] = getSpecFromPR
%spec = PR655read;
return;

function [spec] = getPRValues(spec)

spec = [];
while isempty(spec)
	
	spec = PR655rawspd(50);
	

    if numel(spec) < 10
        spec = [];

    end
end

return;

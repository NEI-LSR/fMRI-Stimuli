function [xyYcie, xyYJudd, spec] = JoshCalibforBL(colors)
% Josh's combined calibration scripts.
% displays colors on screen, measures using PR, reads data from PR, calls modified s2j script and returns xyY values
global PRport bitDepth PR
% Make sure we're connected to the device. Connect if we're not
switch PR 
    case '655'
        try 
	        PR655getsyncfreq
        catch
	        PR655init(PRport)
        end
    case '670'
        try 
	        PR670getsyncfreq
        catch
	        PR670init(PRport)
        end   
end

% Call colorpatch program
switch bitDepth
	case 8
		bsuccess = CPforBL255(colors);
	case 16
		bsuccess = CPforBL(colors);

end


if bsuccess == 1
    switch PR
        case '655'
            clear spd;
            spd = PR655measspd([380 4 101]);
            wav = linspace(380,780,101);
            spec = NaN(101,2);
            for k = 1:101
                spec(k,1) = wav(k);
                spec(k,2) = spd(k);
            end
	        %spec = PR655measspd([],[380 5 81]);
% 	        PR655write('M5')
%             clear spd;
%             [spec] = getPRValues();
%             spec = PR655parsespdstrJ(spec);
        case '670'
            clear spd;
            spd = PR670measspd([380 4 101]);
            wav = linspace(380,780,101);
            spec = NaN(101,2);
            for k = 1:101
                spec(k,1) = wav(k);
                spec(k,2) = spd(k);
            end
    end
else
	disp('something broke. oops')
end


clear xyYJudd 
clear xyYcie
[xyYJudd] = s2jJudd(spec);
[xyYcie] = s2jcie(spec);

%Screen('CloseAll');
%close all; 
clear spd;


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

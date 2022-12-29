function [xyYcie, XYZcie, xyYJudd, XYZjudd, LMS, spec] = getPR655
% Josh's combined calibration scripts. Edited by SJD 1/26/2022 to just get
% information from PR without displaying color patch.
% measures using PR, reads data from PR, calls modified s2j script and returns xyY values
global PRport
% Make sure we're connected to the device. Connect if we're not
try 
	PR655getsyncfreq
catch
	PR655init(PRport)
end


PR655write('M5');


[spec] = getPRValues();

%disp(psd)
spec = PR655parsespdstrJ(spec);
%rawSpec = spec;clear spd;

clear xyYJudd 
clear xyYcie
clear XYZjudd
clear XYZcie
clear LMS
[xyYJudd] = s2jJudd(spec);
[xyYcie] = s2jcie(spec);
[XYZjudd] = spectra2XYZ(spec,'Judd');
[XYZcie] = spectra2XYZ(spec,'cie1931');
[LMS] = spectra2LMS(spec,'LMS');


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

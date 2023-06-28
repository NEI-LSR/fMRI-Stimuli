function [xyYcie, XYZcie, xyYJudd, XYZjudd, LMS, spec] = getPR
% Josh's combined calibration scripts. Edited by SJD 1/26/2022 to just get
% information from PR without displaying color patch.
% measures using PR, reads data from PR, calls modified s2j script and returns xyY values
global PRport PR
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


switch PR
    case '655'
        clear spd;
        clear spd;
        spd = MeasSpd([380 1 401],4);
        wav = linspace(380,780,401);
        spec = NaN(401,2);
        for k = 1:401
            spec(k,1) = wav(k);
            spec(k,2) = spd(k);
        end
    case '670'
        clear spd;
        spd = MeasSpd([380 1 401],5);

        %spd = PR670measspd([380 4 101]);
        wav = linspace(380,780,401);
        spec = NaN(401,2);
        for k = 1:401
            spec(k,1) = wav(k);
            spec(k,2) = spd(k);
        end
end


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


clear spd;


return;


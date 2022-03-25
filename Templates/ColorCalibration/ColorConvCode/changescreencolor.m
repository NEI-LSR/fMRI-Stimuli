% Changes Screen Color
% Stuart J Duffield 2021-12-14
global PRport
PRport = 'COM3';
StepSize = 1;
ScreenSize = [];
KbName('UnifyKeyNames');
Screen('Preference', 'SkipSyncTests', 1); 
Screen('Preference', 'VisualDebugLevel', 0);
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SuppressAllWarnings', 1);
color = [0 0 0];
textcolor = [255 255 255] - color;
screen = max(Screen('Screens'));
[Window, Rect] = Screen('OpenWindow', screen, color, ScreenSize);
Screen('DrawText', Window, num2str(color),[],[],textcolor);
Screen('Flip',Window);
mNum = 1; % Measure Number
measurements = struct('gunVals',{},'xyY',{},'XYZ',{},'xyYJudd',{},'XYZJudd',{},'LMS',{},'spectra',{});
date_time=strrep(strrep(datestr(datetime),' ','_'),':','_')

saveFile = ['manualMeasurements\' date_time];

while true
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(KbName('q')) && color(1) < 255
        color(1) = min(color(1)+StepSize,255);
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);
        disp(color)
        pause(0.1)
    elseif keyCode(KbName('a')) && color(1) > 0
        color(1) = max(color(1)-StepSize,0);
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);
        disp(color)
        pause(0.1)
    elseif keyCode(KbName('w')) && color(2) < 255
        color(2) = min(color(2)+StepSize,255);
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);  
        disp(color)
        pause(0.1)
    elseif keyCode(KbName('s')) && color(2) > 0
        color(2) = max(color(2)-StepSize,0);
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);  
        disp(color)
        pause(0.1)
    elseif keyCode(KbName('e')) && color(3) < 255
        color(3) = min(color(3)+StepSize,255);
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);  
        disp(color)
        pause(0.1)
    elseif keyCode(KbName('d')) && color(3) > 0
        color(3) = max(color(3)-StepSize,0);
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);
        disp(color)
        pause(0.1)
    elseif keyCode(KbName('r')) && StepSize < 64
        StepSize = StepSize*2;
        pause(0.5)
    elseif keyCode(KbName('f')) && StepSize > 1
        StepSize = StepSize/2;
        pause(0.5)
    elseif keyCode(KbName('return'))
        [xyYcie, XYZcie, xyYJudd, XYZJudd, LMS, spec] = getPR655;
        disp(['xyY1931 Values are: ' num2str(xyYcie)])
        disp(['XYZ1931 Values are: ' num2str(XYZcie)])
        disp(['xyY Judd Values are: ' num2str(xyYJudd)])
        disp(['XYZJudd Values are: ' num2str(XYZJudd)])
        disp(['LMS Values are: ' num2str(LMS)])
        measurements(mNum).gunVals = color;
        measurements(mNum).xyY = xyYcie;
        measurements(mNum).XYZ = XYZcie;
        measurements(mNum).xyYJudd = xyYJudd;
        measurements(mNum).XYZJudd = XYZJudd;
        measurements(mNum).LMS = LMS;
        measurements(mNum).spectra = spec;
        disp(mNum)
        mNum = mNum + 1;
        pause(0.5)
    elseif keyCode(KbName('v'))
        disp(color)
        disp(['Stepsize is ' num2str(StepSize)])
        pause(0.1)
    elseif keyCode(KbName('p'))
        sca;
        save(saveFile, 'measurements');
        break
    end
end
        
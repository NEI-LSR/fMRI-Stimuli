% Changes Screen Color
% Stuart J Duffield 2021-12-14
StepSize = 16;
KbName('UnifyKeyNames');
Screen('Preference', 'SkipSyncTests', 1); 
Screen('Preference', 'VisualDebugLevel', 0);
Screen('Preference', 'Verbosity', 0);
Screen('Preference', 'SuppressAllWarnings', 1);
color = [0 0 0];
textcolor = [255 255 255] - color;
screen = max(Screen('Screens'));
[Window, Rect] = Screen('OpenWindow', screen, color, [0 0 500 500]);
Screen('DrawText', Window, num2str(color),[],[],textcolor);
Screen('Flip',Window);

while true
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(KbName('q')) && color(1) < 255
        color(1) = color(1)+StepSize;
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);
        pause(0.5)
    elseif keyCode(KbName('a')) && color(1) > 0
        color(1) = color(1)-StepSize;
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);
        pause(0.5)
    elseif keyCode(KbName('w')) && color(2) < 255
        color(2) = color(2)+StepSize;
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);  
        pause(0.5)
    elseif keyCode(KbName('s')) && color(2) > 0
        color(2) = color(2)-StepSize;
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);  
        pause(0.5)
    elseif keyCode(KbName('e')) && color(3) < 255
        color(3) = color(3)+StepSize;
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);  
        pause(0.5)
    elseif keyCode(KbName('d')) && color(3) > 0
        color(3) = color(3)-StepSize;
        textcolor = [255 255 255] - color;
        Screen('FillRect',Window,color);
        Screen('DrawText', Window, num2str(color),0,0,textcolor);
        Screen('Flip',Window);
        pause(0.5)
    elseif keyCode(KbName('p'))
        sca;
        break
    end
end
        
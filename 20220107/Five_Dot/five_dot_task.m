function [gain,output,eyeRecord,Vcent,Vcent2] = five_dot_task()
%To do: determine frameRect size based on degrees of visual field
%To do: put all the variables or important ones in one struct that will be
%global
    clear Screen
    clear PsychSerial
    clear all
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 0);
    
    
    saveData = 1;
    curdir = pwd;
    mkdir 'EyeData';
   
    %WaitSecs;
    fnDAQNI('Init',0)
    global Vcent Vcent2 Quit doRunTrial doDisplayEyePos dotNum gain channels port frameRects1 start manualJuiceStart
    global dotSize rects
    gain{1} = -400;    
    gain{2} = 400;
    %gain{1} = 200; 
    %gain{2} = 400;
    channels = [1 2];
    port = 1;  
    Quit = 0;
    start = 0;
    doRunTrial = 0;
    manualJuiceStart = 0;
    doDisplayEyePos = 0;
    dotNum = 1;
    Vcent = [0 0];
    Vcent(1) = 0;
    Vcent(2) = 0;
    Vcent2 = Vcent;
    dotTime = 1.5;
    juiceTime = 0.02;
    juiceInterval = 0.5;


    fixDot = 4;
    dotSize = 12;
    frameSizeDiv = 15; %determine this based on degrees of vision
    backgroundRGB = [255 255 255];
    whichScreen = 2;
    whichScreen2 = 2;
    [window, screenRect] = Screen('OpenWindow', whichScreen, backgroundRGB, [], 32);
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    W2 = 1200;
    H2 = screenRect(4) / screenRect(3) * W2;
    [window2,screenRect2] = Screen('OpenWindow', whichScreen2, backgroundRGB, [0,0,W2,H2], 32);
    [screenXpixels2, screenYpixels2] = Screen('WindowSize', window2);
    %baseRect = [0 0 screenXpixels/32 screenXpixels/32];
    baseRect = [0 0 dotSize dotSize];
    frameRect = [0 0 screenXpixels screenXpixels] ./ frameSizeDiv;
    eyetraceRect = [0 0 screenXpixels/128 screenXpixels/128];
    [xCenter, yCenter] = RectCenter(screenRect);
    div = 8;
    upperLeftCentX = xCenter - screenXpixels / div;
    upperLeftCentY = yCenter - screenYpixels / div;
    upperRightCentX = xCenter + screenXpixels / div;
    upperRightCentY = yCenter - screenYpixels / div;
    lowerLeftCentX = xCenter - screenXpixels / div;
    lowerLeftCentY = yCenter + screenYpixels / div;
    lowerRightCentX = xCenter + screenXpixels / div;
    lowerRightCentY = yCenter + screenYpixels / div;
    dotCenters = [xCenter,yCenter; ...
               upperLeftCentX,upperLeftCentY; ...
               upperRightCentX,upperRightCentY; ...
               lowerLeftCentX,lowerLeftCentY; ...
               lowerRightCentX,lowerRightCentY];
    centerDot = CenterRectOnPointd(baseRect,xCenter,yCenter);
    upperLeftDot = CenterRectOnPointd(baseRect,upperLeftCentX,upperLeftCentY);
    upperRightDot = CenterRectOnPointd(baseRect,upperRightCentX,upperRightCentY);
    lowerLeftDot = CenterRectOnPointd(baseRect,lowerLeftCentX,lowerLeftCentY);
    lowerRightDot = CenterRectOnPointd(baseRect,lowerRightCentX,lowerRightCentY);
    rects = [centerDot; upperLeftDot; upperRightDot; lowerLeftDot; lowerRightDot];
    centerFrame = CenterRectOnPointd(frameRect,xCenter,yCenter);
    upperLeftFrame = CenterRectOnPointd(frameRect,upperLeftCentX,upperLeftCentY);
    upperRightFrame = CenterRectOnPointd(frameRect,upperRightCentX,upperRightCentY);
    lowerLeftFrame = CenterRectOnPointd(frameRect,lowerLeftCentX,lowerLeftCentY);
    lowerRightFrame = CenterRectOnPointd(frameRect,lowerRightCentX,lowerRightCentY);
    frameRects = [centerFrame; upperLeftFrame; upperRightFrame; lowerLeftFrame; lowerRightFrame];
    
    %second screen
    baseRect2 = [0 0 dotSize dotSize];
    eyetraceRect2 = [0 0 fixDot fixDot];
    [xCenter2, yCenter2] = RectCenter(screenRect2);
    upperLeftCentX2 = xCenter2 - screenXpixels2 / 8;
    upperLeftCentY2 = yCenter2 - screenYpixels2 / 8;
    upperRightCentX2 = xCenter2 + screenXpixels2 / 8;
    upperRightCentY2 = yCenter2 - screenYpixels2 / 8;
    lowerLeftCentX2 = xCenter2 - screenXpixels2 / 8;
    lowerLeftCentY2 = yCenter2 + screenYpixels2 / 8;
    lowerRightCentX2 = xCenter2 + screenXpixels2 / 8;
    lowerRightCentY2 = yCenter2 + screenYpixels2 / 8;
    dotCenters2 = [xCenter2,yCenter2; ...
               upperLeftCentX2,upperLeftCentY2; ...
               upperRightCentX2,upperRightCentY2; ...
               lowerLeftCentX2,lowerLeftCentY2; ...
               lowerRightCentX2,lowerRightCentY2];

    centerDot2 = CenterRectOnPointd(baseRect2,xCenter2,yCenter2);
    upperLeftDot2 = CenterRectOnPointd(baseRect2,upperLeftCentX2,upperLeftCentY2);
    upperRightDot2 = CenterRectOnPointd(baseRect2,upperRightCentX2,upperRightCentY2);
    lowerLeftDot2 = CenterRectOnPointd(baseRect2,lowerLeftCentX2,lowerLeftCentY2);
    lowerRightDot2 = CenterRectOnPointd(baseRect2,lowerRightCentX2,lowerRightCentY2);
    rects2 = [centerDot2; upperLeftDot2; upperRightDot2; lowerLeftDot2; lowerRightDot2];
    centerFrame = CenterRectOnPointd(frameRect,xCenter2,yCenter2);
    upperLeftFrame = CenterRectOnPointd(frameRect,upperLeftCentX2,upperLeftCentY2);
    upperRightFrame = CenterRectOnPointd(frameRect,upperRightCentX2,upperRightCentY2);
    lowerLeftFrame = CenterRectOnPointd(frameRect,lowerLeftCentX2,lowerLeftCentY2);
    lowerRightFrame = CenterRectOnPointd(frameRect,lowerRightCentX2,lowerRightCentY2);
    frameRects1 = [centerFrame; upperLeftFrame; upperRightFrame; lowerLeftFrame; lowerRightFrame];
    circleColor = [0 0 0];
    eyetraceColor = [255 0 0];
    
    f = figure('Visible', 'on','Position', [1200 400 300 150]);
    recenterBtn = uicontrol('Position',[40 100 70 25],'String',num2str(Vcent));
    recenterBtn.Callback = @(src,event)recenter(dotCenters,dotCenters2,recenterBtn); %change what this fnc does because right now its from my test
    quitBtn = uicontrol('Position',[190 100 70 25],'String','Quit');
    quitBtn.Callback = @(src,event)quitLoop();
    pauseBtn = uicontrol('Position',[40 75 70 25],'String','Pause');
    pauseBtn.Callback = @(src,event)pauseDots();
    nextDotBtn = uicontrol('Position',[190 75 70 25],'String','Next Dot');
    nextDotBtn.Callback = @(src,event)nextDot(window,window2,circleColor,rects,rects2);
    startBtn = uicontrol('Position',[115 75 70 25],'String','Start');
    startBtn.Callback = @(src,event)startDots();
    juiceBtn = uicontrol('Position',[115 100 70 25],'String','Juice');
    juiceBtn.Callback = @(src,event)deliverJuice();
    xGainText = uicontrol('Style','text','Position',[270,30,25,12],...
        'String',num2str(gain{1}),'BackgroundColor',f.Color);
    yGainText = uicontrol('Style','text','Position',[270,15,25,12],...
        'String',num2str(gain{2}),'BackgroundColor',f.Color);
    dotSizeText = uicontrol('Style','text','Position',[270,45,25,12],...
        'String',num2str(dotSize),'BackgroundColor',f.Color);
    sliderX = uicontrol('Style','slider','Position',[10 30 250 12],'value',gain{1},'min',-10000,'max',800); 
    sliderY = uicontrol('Style','slider','Position',[10 15 250 12],'value',gain{2},'min',-800,'max',800); 
    sliderX.Callback = @(es,ed) updateXgain(es,ed,xGainText,dotCenters,dotCenters2);
    sliderY.Callback = @(es,ed) updateYgain(es,ed,yGainText,dotCenters,dotCenters2);
    sliderSize = uicontrol('Style','slider','Position',[10 45 250 12],'value',dotSize,'min',4,'max',40); 
    sliderSize.Callback = @(es,ed) updateDotSize(es,ed,dotSizeText,window,screenRect);
    
    startTime = GetSecs;
    juiceTimer = GetSecs;
    manualJuiceTimer = GetSecs;
    gazeStart = 0;
    gazeTimer = 0;
    juicing = 0;
    manualJuicing = 0;
    topPriorityLevel = MaxPriority(window);
    Priority(topPriorityLevel);
    output.x = [];
    output.y = [];
    eyeRecord = [];
    eyeRecord.x = [];
    eyeRecord.y = [];
    eyeRecord.time = [];
    while (~Quit)
        pause(0.0001); 
        if doRunTrial
            %gain{1} = str2double(inputdlg('enter x gain'));
            %gain{2} = str2double(inputdlg('enter y gain'));
            %Screen('FillOval',window,circleColor,rects(dotNum,:));
            %eyePosRect = drawEyePos(gain,eyetraceRect,dotCenters);
            %Screen('FillOval',window,eyetraceColor,eyePosRect)
            %Screen('Flip',window);
            doRunTrial = 0;
        end
        
        %this was when I could only manually display the eye position
%         if doDisplayEyePos
%             eyePosRect = drawEyePos(gain,eyetraceRect,dotCenters);
%             Screen('FillOval',window,circleColor,rects(dotNum,:));
%             Screen('FillOval',window,eyetraceColor,eyePosRect)
%             Screen('Flip',window);
%             doDisplayEyePos = 0;
%         end
        if start && GetSecs - startTime > dotTime
           nextDot(window,window2,circleColor,rects,rects2);
           disp(dotSize);
           startTime = GetSecs;
        end
        
        %this was for if juice is constantly being delivered regardless of
        %where monkey is looking
%         if GetSecs - juiceTimer > juiceInterval
%             fnDAQNI('SetBit',port,1);
%             juicing = 1;
%             juiceTimer = GetSecs;
%         end
%         if juicing && GetSecs - juiceTimer > juiceTime
%             fnDAQNI('SetBit',port,0);
%             juicing = 0;
%             juiceTimer = GetSecs;
%         end

        if manualJuiceStart
            fnDAQNI('SetBit',port,1);
            pause(juiceTime);
            fnDAQNI('SetBit',port,0);
            manualJuiceTimer = GetSecs;
            manualJuicing = 1;
            manualJuiceStart = 0;

        end
%         if manualJuicing && GetSecs - manualJuiceTimer > juiceTime
%             fnDAQNI('SetBit',port,0);
%             manualJuicing = 0;
%         end
        
        [Xpos,Ypos,Xpos1,Ypos1,~,eyePosRect2] = drawEyePos(gain,eyetraceRect,eyetraceRect2,dotCenters,dotCenters2);
        Vraw = fnDAQNI('GetAnalog',channels);
        output.x = [output.x Vraw(1)];
        output.y = [output.y Vraw(2)];
        
        eyeRecord.time = [eyeRecord.time GetSecs];
        eyeRecord.x = [eyeRecord.x Xpos];
        eyeRecord.y = [eyeRecord.y Ypos];
        
        Screen('FillOval',window,circleColor,rects(dotNum,:));
        %Screen('FillOval',window,eyetraceColor,eyePosRect);
        Screen('FillOval',window2,circleColor,rects2(dotNum,:));
        Screen('FillOval',window2,eyetraceColor,eyePosRect2);
        Screen('FrameRect',window2,circleColor,frameRects1(dotNum,:));
        Screen('Flip',window);
        Screen('Flip',window2);
        
        if checkEyeInBox([Xpos1,Ypos1],frameRects1(dotNum,:))
           gazeTimer = GetSecs - gazeStart;
        else
           gazeStart = GetSecs;
           gazeTimer = 0;
        end
%         if ~juicing && gazeTimer >= juiceInterval
%            fnDAQNI('SetBit',port,0);
%            fnDAQNI('SetBit',port,1);
%            pause(0.018);
%            fnDAQNI('SetBit',port,0);
%            Beeper(500);
%            juiceStart = GetSecs;
%            juicing = 1;
%            gazeTimer = 0;
%         end
%        
        if juicing && (GetSecs - juiceStart >= juiceTime)
            fnDAQNI('SetBit',port,0);
            Beeper(400);
            juicing = 0;
            gazeStart = GetSecs; %this should either be here or in the if statement above
        end
        
        %check for key press indicating manual juicing or grabbing
        %attention 
        [keyIsDown,secs,keyCode] = KbCheck;
        if keyIsDown && keyCode(74) %j for juice
            manualJuiceStart = 1;
        end
        if keyIsDown && keyCode(65) %a to grab attention
            grabAttention(window,screenRect,0.5);
        end
    end
    
    out = [gain{1},gain{2}];
    sca;
    fnDAQNI('SetBit',port,0);
    close all; 
    save([curdir '/EyeData/EyeData']);
    %print(Vraw(1), '_', Vraw(2));
end

function quitLoop()
    
    global Quit
    Quit = 1;
end

function pauseDots()
    global start
    start = 0;
end

function startDots()
    global start
    start = 1;
end

function displayEyePos()
    global doDisplayEyePos;
    doDisplayEyePos = 1;
end

function nextDot(window,window2,circleColor,rect,rect2)
    global dotNum frameRects1
    dotNum = mod(dotNum,5) + 1;
    Screen('FillOval',window,circleColor,rect(dotNum,:));
    Screen('FillOval',window2,circleColor,rect2(dotNum,:));
    Screen('FrameRect',window2,circleColor,frameRects1(dotNum,:));
    Screen('Flip',window);
    Screen('Flip',window2);
end

function deliverJuice()
    global manualJuiceStart channels
    manualJuiceStart = 1;
    fnDAQNI('GetAnalog',channels);
end

% function calcGain(center,dotCenters)
%     global channels Vcent dotNum gain
%     Vraw = fnDAQNI('GetAnalog',channels);
%     gainXcalc = (dotCenters(dotNum,1)-center(1)) / (Vraw(1)-Vcent(1));
%     gainYcalc = (dotCenters(dotNum,2)-center(2)) / (Vraw(2)-Vcent(2));
%     disp(['dot ', num2str(dotNum)]);
%     disp(['gainX: ',num2str(gainXcalc)]);
%     disp(['gainY: ',num2str(gainYcalc)]);
%     gain{1} = gainXcalc;
%     gain{2} = gainYcalc;
% end

function [Xpos,Ypos,Xpos2,Ypos2,eyePosRect,eyePosRect2] = drawEyePos(gain,baseRect,baseRect2,dotCenters,dotCenters2)
    global channels Vcent Vcent2 dotNum
    Vraw = fnDAQNI('GetAnalog',channels);
    %disp(Vraw);
    %can condense into one line
    Xpos = (Vraw(1) - Vcent(1))*gain{1} + dotCenters(1,1);
    Ypos = (Vraw(2) - Vcent(2))*gain{2} + dotCenters(1,2);
    Xpos2 = (Vraw(1) - Vcent2(1))*gain{1} + dotCenters2(1,1);
    Ypos2 = (Vraw(2) - Vcent2(2))*gain{2} + dotCenters2(1,2);
    eyePosRect = CenterRectOnPointd(baseRect,Xpos,Ypos);
    eyePosRect2 = CenterRectOnPointd(baseRect2,Xpos2,Ypos2);
    %disp(['dot x: ',num2str(dotCenters(dotNum,1))]);
    %disp(['Vx diff: ',num2str(Vraw(1) - Vcent(1))]);
    %disp(['center x: ',num2str(center(1))]);
    %disp(['dot y: ',num2str(dotCenters(dotNum,2))]);
    %disp(['Vy diff: ',num2str(Vraw(2) - Vcent(2))]);
    %disp(['center y: ',num2str(center(2))]);
end

function recenter(dotCenters,dotCenters2,recenterBtn)
    global gain Vcent Vcent2 dotNum channels
    gains = [gain{1} gain{2}];
    Vraw = fnDAQNI('GetAnalog',channels);
    Vcent = Vraw - (dotCenters(dotNum,:) - dotCenters(1,:)) ./ gains;
    Vcent2 = Vraw - (dotCenters2(dotNum,:) - dotCenters2(1,:)) ./ gains;
    recenterBtn.String = num2str(Vcent);
end

function updateXgain(es,ed,xGainText,dotCenters,dotCenters2)
    global gain Vcent Vcent2 channels dotNum 
    gain{1} = es.Value
    gains = [gain{1} gain{2}];
    Vraw = fnDAQNI('GetAnalog',channels);
    Vcent = Vraw - (dotCenters(dotNum,:) - dotCenters(1,:)) ./ gains;
    Vcent2 = Vraw - (dotCenters2(dotNum,:) - dotCenters2(1,:)) ./ gains;
    xGainText.String = num2str(gain{1});
end
function updateYgain(es,ed,yGainText,dotCenters,dotCenters2)
    global gain Vcent Vcent2 channels dotNum
    gain{2} = es.Value
    gains = [gain{1} gain{2}];
    Vraw = fnDAQNI('GetAnalog',channels);
    Vcent = Vraw - (dotCenters(dotNum,:) - dotCenters(1,:)) ./ gains;
    Vcent2 = Vraw - (dotCenters2(dotNum,:) - dotCenters2(1,:)) ./ gains;
    yGainText.String = num2str(gain{2});
end

function gazeInBox = checkEyeInBox(eyePos,centerRect)
    if eyePos(1)>centerRect(1) && eyePos(1) < centerRect(3)...
            && eyePos(2)>centerRect(2) && eyePos(2)<centerRect(4)
       gazeInBox = 1;
    else
       gazeInBox = 0;
    end
end

function grabAttention(window,windowRect,duration)
    ifi = Screen('GetFlipInterval', window);
    vbl = Screen('Flip', window);
    waitframes = 1;
    maxDotSize = 925;
    [xCenter, yCenter] = RectCenter(windowRect);
    amplitude = 1;
    frequency = 2;
    angFreq = 2 * pi * frequency;
    startPhase = 0;
    time = 0;
    while time < duration
       scaleFactor = abs(amplitude * sin(angFreq * time + startPhase));
       size = maxDotSize * scaleFactor;
       baseRect = [0 0 size size];
       dot = CenterRectOnPointd(baseRect,xCenter,yCenter);
       Screen('FillOval',window,[0 0 0],dot);
       Screen('Flip',window,vbl + (waitframes - 0.5) * ifi);
       time = time + ifi;
    end
end

%make this function smaller when I have a global struct
function updateDotSize(es,ed,dotSizeText,window,screenRect)
    global dotSize rects
    dotSize = es.Value;
    dotSizeText.String = num2str(dotSize);
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    baseRect = [0 0 dotSize dotSize];
    [xCenter, yCenter] = RectCenter(screenRect);
    upperLeftCentX = xCenter - screenXpixels / 8;
    upperLeftCentY = yCenter - screenYpixels / 8;
    upperRightCentX = xCenter + screenXpixels / 8;
    upperRightCentY = yCenter - screenYpixels / 8;
    lowerLeftCentX = xCenter - screenXpixels / 8;
    lowerLeftCentY = yCenter + screenYpixels / 8;
    lowerRightCentX = xCenter + screenXpixels / 8;
    lowerRightCentY = yCenter + screenYpixels / 8;
    centerDot = CenterRectOnPointd(baseRect,xCenter,yCenter);
    upperLeftDot = CenterRectOnPointd(baseRect,upperLeftCentX,upperLeftCentY);
    upperRightDot = CenterRectOnPointd(baseRect,upperRightCentX,upperRightCentY);
    lowerLeftDot = CenterRectOnPointd(baseRect,lowerLeftCentX,lowerLeftCentY);
    lowerRightDot = CenterRectOnPointd(baseRect,lowerRightCentX,lowerRightCentY);
    rects = [centerDot; upperLeftDot; upperRightDot; lowerLeftDot; lowerRightDot];
end


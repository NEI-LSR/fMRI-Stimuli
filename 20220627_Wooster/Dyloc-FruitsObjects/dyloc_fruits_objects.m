function dyloc_fruits_objects(subj_id, counterbalance_idx, acquisition_num)
% originally written by rebecca saxe, edited by jason webster, josh julian, etc.
% 
% i modified this just to include fixation, objects, and scrambled -- to localize object regions only
%
% plays 3 second long movies of objects, movies of grid-scrambled objects, and color fields
%
% 	sequence is the order of designs, any order of numbers 1:6
% 	randseed can be any number - controls item counterbalancing
% 	run counts up from 1

%% setup DAQ stuff
fnDAQNI('Init',0); 
%eye tracking info
global channels port
channels = [1,2];
port = 1;
global gain Vcent; %set this after 5 dot task

gain(1) = -500;
gain(2) = 700;
Vcent(1) = -.84;
Vcent(2) = -.32;

global manualJuiceStart
manualJuiceStart = 0;

juiceInterval = 1.8; %seconds before juice reward
juiceTime = 0.08;

disp(['Juice Interval is: ' num2str(juiceInterval)])
keyboard

dataDir = ([pwd filesep subj_id filesep])
thisExpDir = [dataDir date filesep]
if ~exist(thisExpDir)
   mkdir(thisExpDir) 
end

ima = input('Enter IMA number');
thisFileName = ['data_' num2str(ima) '.mat'];
thisFilePath = [thisExpDir thisFileName]

%%

AssertOpenGL;
Screen('Preference', 'SkipSyncTests', 1);%RLS

global rootDir
rootDir = pwd;
if ~isdir('EyeRecords');
    mkdir EyeRecords;
end
cd EyeRecords;
eyeRecordRun = length(dir('EyeRecord*')) + 1;
data_dir = fullfile(rootDir, 'data');
cd(rootDir);

TR = 3;
STIM_DURATION = 3;
STIM_PER_BLOCK = 10;

stim_dir = 'C:\Users\Admin\Documents\dyloc_stimuli\';

KbName('UnifyKeyNames'); 


CONDITION_NAMES ={'Fruit','Objects','Fruit_scrambled','Scrambled15G','Fruit_bw','Objects_bw','Fruit_scrambled_bw','Scrambled15GBW',};% 
STIM_SUB_DIRS = {fullfile(stim_dir,CONDITION_NAMES{1}), fullfile(stim_dir, CONDITION_NAMES{2}), fullfile(stim_dir, CONDITION_NAMES{3}), fullfile(stim_dir, CONDITION_NAMES{4}), fullfile(stim_dir, CONDITION_NAMES{5}), fullfile(stim_dir, CONDITION_NAMES{6}), fullfile(stim_dir, CONDITION_NAMES{7}), fullfile(stim_dir, CONDITION_NAMES{8})};
warning('off','MATLAB:dispatcher:InexactMatch');
onExit='execution halted by experimenter';


designs = [
     0 1     2     8     3     7     4     6     5 0;
     0 2     3     1     4     8     5     7     6 0;
     0 3     4     2     5     1     6     8     7 0;
     0 4     5     3     6     2     7     1     8 0;
     0 5     6     4     7     3     8     2     1 0;
     0 6     7     5     8     4     1     3     2 0;
     0 7     8     6     1     5     2     4     3 0;
     0 8     1     7     2     6     3     5     4 0;
           
           
];

design = designs(counterbalance_idx,:);
numconds = max(design);

blocksPerRun = length(design);
blockDur = STIM_DURATION*STIM_PER_BLOCK;
tStartLoad=.5; tFinishLoad=1;
rand('twister', sum(100*clock));
KbName('UnifyKeyNames');
index = zeros(numconds,1);
movieNames={};
rate=1;

planfp=fopen([data_dir filesep subj_id '-dyn-' int2str(acquisition_num) '-' int2str(counterbalance_idx) '-plan.txt'],'wt');
parafp=fopen([data_dir filesep subj_id '-dyn-' int2str(acquisition_num) '-' int2str(counterbalance_idx) '-para.txt'],'wt');
    
% HideCursor;   
%%%%% open window, etc
%Screen('Preference', 'Verbosity', 1);
%Screen('Preference', 'VisualDebuglevel', 3);


try
    screens = Screen('Screens');
    screenNumber = 2;  %Highest screen number is most likely correct display
%     [window, rect] = Screen('OpenWindow', screenNumber,[0,0,0],[400,0,1500,800]);
%    [window, rect] = Screen('OpenWindow', screenNumber,[0,0,0],[2320,0,3420,800]);
    [window, rect] = Screen('OpenWindow', screenNumber,[0,0,0]);


    [x0,y0] = RectCenter(rect); %sets Center for screenRect (x,y)
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);

    
    CX = x0;
    CY = y0;
    
    AssertOpenGL;
    ifi = Screen('GetFlipInterval', window);
    
    
    imp=150;
    locDur          = 2.5;    %%    Time at each calibration point
    spatialFreq   =  4;    %%   Number of rings that will be displayed
    tempFreq     =  3;     %%   number of crest to crest passing a point in 1 second
    stimSize  = y0/4
    tPixFreq=(stimSize/spatialFreq)*tempFreq
    colorsPerRun=(tempFreq*blockDur+spatialFreq-1);
    
    for d=1:stimSize
        thisSize=[0 0 d d];
        ringGroup(:,stimSize+1-d)=CenterRect(thisSize,rect)';
    end;

    fudgeFactor=4; %DEVNOTE: ifi fractional - matrix inidices not

colors=[     0,     0,     0;
                255,255,255;
                255,     0,    0;
                0,     255,    0;
                0,         0,255;];
    thisColor=1; lastColor=-1;
    ringColors=[];
    for c=1:colorsPerRun+fudgeFactor
        while thisColor==lastColor
            thisColor=ceil(rand*length(colors));
        end;              lastColor=thisColor;
        ringColors=[ringColors colors(thisColor,:)'*ones(1,ceil(stimSize/spatialFreq))];
    end
    
    Upper=-((3.5-1.5)/3.5)*y0; Left   =-((5-2)/5)*x0;  %use Xcalibration.def
    Lower= ((3.5-1.5)/3.5)*y0;  Right= ((5-2)/5)*x0;
    moveUnit=(5*locDur/6)/(4*(1+sqrt(2)));

    when =[ 0;
                      .5*locDur+ 0;
                    1.5*locDur+(0+    sqrt(2))*moveUnit;
                    2.5*locDur+(2+    sqrt(2))*moveUnit;
                    3.5*locDur+(2+3*sqrt(2))*moveUnit;
                    4.5*locDur+(4+3*sqrt(2))*moveUnit;]
            
    ringSetCC=ringGroup;
    ringSetUL(2,:)=ringGroup(2,:)+Upper;    ringSetUL(4,:)=ringGroup(4,:)+Upper;
    ringSetUL(1,:)=ringGroup(1,:)+Left;        ringSetUL(3,:)=ringGroup(3,:)+Left;
    ringSetUR(2,:)=ringGroup(2,:)+Upper;   ringSetUR(4,:)=ringGroup(4,:)+Upper;
    ringSetUR(1,:)=ringGroup(1,:)+Right;       ringSetUR(3,:)=ringGroup(3,:)+Right;
    ringSetLL(2,:)=ringGroup(2,:)+Lower;    ringSetLL(4,:)=ringGroup(4,:)+Lower;
    ringSetLL(1,:)=ringGroup(1,:)+Left;        ringSetLL(3,:)=ringGroup(3,:)+Left;
    ringSetLR(2,:)=ringGroup(2,:)+Lower;   ringSetLR(4,:)=ringGroup(4,:)+Lower;
    ringSetLR(1,:)=ringGroup(1,:)+Right;       ringSetLR(3,:)=ringGroup(3,:)+Right;


    %create lists of all the movie items in the directories
    for c = 1:numconds
        cd(deblank(STIM_SUB_DIRS{c}));
        d = dir('*.mov');
        if isempty(d)
            d = dir('*.avi');
        end
        [numitems junk] = size(d);
%         eval(sprintf('[movlist%d{1:numitems}] = deal(d.name);', c));
        [movlist.(['mov' num2str(c)]){1:numitems}] = deal(d.name);
        movlistn{c,:} = randperm(numitems);
    end
    cd(rootDir);  
    
    
    % create plan & para files, select all images before acquisitions
    for theblock = 1:blocksPerRun   
        cond = design(theblock);  

        if cond     % load the stimuli movie locations
            movieCond=cond;
            myitems=movlistn{movieCond}(STIM_PER_BLOCK*index(movieCond)+1:STIM_PER_BLOCK*index(movieCond)+STIM_PER_BLOCK);
            cd(deblank(STIM_SUB_DIRS{movieCond}));    index(movieCond)=index(movieCond)+1;
%             list_cmd=sprintf('itemlist = movlist%d;',movieCond);        eval(list_cmd);
            itemlist = movlist.(['mov' num2str(movieCond)]);
            for theitem=1:STIM_PER_BLOCK
                moviename=[STIM_SUB_DIRS{movieCond} filesep itemlist{myitems(theitem)}]; 
                movieNames=[movieNames moviename];
                nTrial=(theblock-1)*blockDur+(theitem-1)*STIM_DURATION;
                fprintf(planfp,'%6.1f \t %6.0f \t %s\n',nTrial,cond,moviename);
                fprintf(parafp,'%6.1f \t %6.0f \n'     ,nTrial,cond);
            end
        else    % fixation
            theblock
            nTrial=(theblock-1)*blockDur;
            fprintf(planfp,'%6.1f \t %6.0f \t %s\n',nTrial,cond,'fix');
            fprintf(parafp,'%6.1f \t %6.0f \n'     ,nTrial,cond);
        end
    end
    fclose(planfp); 
    fclose(parafp);
    
    Screen('DrawText', window, 'Ready', x0-55, y0, 255);
    Screen('Flip', window);

    disp(sprintf('ips:  %3.0f', (blocksPerRun*blockDur)/TR))
    disp(sprintf('expected run time:  %3.2f',blocksPerRun*blockDur))
 
    % reset all keys, wait for trigger pulse 
    
    %while 1
    %    FlushEvents;    trig = GetChar;    if trig == '+ ', break;  end
    %end

    
%% setup secondary screen

fixationSize = 300;
fixationBaseRect = [0 0 fixationSize fixationSize];
fixationRect = CenterRectOnPointd(fixationBaseRect,CX,CY);

whichScreen2 = 1;
width2 = 1200;
height2 = rect(4) / rect(3) * width2;
bcolor = [0 0 0];
[window2,rect2] = PsychImaging('OpenWindow', whichScreen2, bcolor, [400,0,1500,800], 32);

[screenXpixels2, screenYpixels2] = Screen('WindowSize', window2);
[xCenter2, yCenter2] = RectCenter(rect2);
C2 = convertPixelCoords([CX,CY],...
        [rect(3),rect(4)],[screenXpixels2,screenYpixels2],...
        [CX,CY],[xCenter2,yCenter2]);
CX2 = C2(1); CY2 = C2(2);
fixationBaseRect2 = convertPixelCoords([fixationSize,fixationSize],...
        [screenXpixels,screenYpixels],[screenXpixels2,screenYpixels2],...
        [x0,y0],[xCenter2,yCenter2]);
fixationBaseRect2 = [0,0,fixationBaseRect2];
fixationRect2 = CenterRectOnPointd(fixationBaseRect2,CX2,CY2);

L = 12;
W = 12;

fixbarAcross2 = [CX2 - L/4, CY2 - W/4, CX2 + L/4, CY2 + W/4];
fixbarDown2 = [CX2 - W/4, CY2 - L/4, CX2 + W/4, CY2 + L/4];
%fixation area to display on second screen
eyePosDotSize = 4;
eyetraceBaseRect = [0 0 eyePosDotSize eyePosDotSize];

BarColor = [1 0 0];
BarColor2 = [255 0 0];

%% 5 dot (skipped because beginNow = 1)
    beginNow=1;
    [keyIsDown, secs, keyCode] = KbCheck;
    while ( ~keyCode(KbName('=+')) && ~keyCode(KbName('+')) &&~beginNow) 
        if beginNow, break; end;
        blockStart=GetSecs;
        nextTime=blockStart+ifi;
        blockEnd=blockStart+blockDur;
        colorInd=length(ringColors)-stimSize;
        while GetSecs<blockEnd-ifi
            colorTrip=ringColors(:,colorInd:colorInd-1+stimSize);
            tNow=GetSecs-blockStart;
            switch find(when<tNow,1,'last')
                case 1; target=ringSetCC;  rate=imp*moveUnit*sqrt(2);
                case 2; target=ringSetUL;   rate=imp*moveUnit*sqrt(2);
                case 3; target=ringSetUR;  rate=imp*moveUnit*2;
                case 4; target=ringSetLL;   rate=imp*moveUnit*2*sqrt(2);
                case 5; target=ringSetLR;   rate=imp*moveUnit*2;
                case 6; target=ringSetCC;   rate=imp*moveUnit*sqrt(2);
            end
            distance=(target-ringGroup);
            ringGroup=ringGroup+distance./(target/rate);       
            Screen('FillOval', window, colorTrip, ringGroup,stimSize); 
            
            [keyDown, keySeconds, keyCode] = KbCheck();
            if keyDown,
                disp(keyCode)
                disp(find(keyCode, 1, 'first'))
                response= find(keyCode, 1, 'first');
                response
                disp(['problem with ' response])
                beginNow=1;break;
                if response=='+',beginNow=1;break;end;
            end
            if  keyCode(KbName('=+')) || keyCode(KbName('+')), break, end;
            assert(~keyCode(KbName('Escape')),onExit);
            
            colorInd=colorInd-1;  
            Screen('flip',window,nextTime); 
            nextTime=nextTime+ifi;  
        end % end while 
    end

%% wait for MRI trigger
    currDir = pwd;
    cd(rootDir)
    signal_init = fnDAQNI('GetAnalog',7);
    skip=0;
    while 1
        [keyIsDown, secs, keyCode] = KbCheck;
        %if keyCode(13) break; % start only when "return" key is pressed (keyCode for "return" is 13)
        if keyIsDown && keyCode(32)
            break; % start when space key is pressed
        end
        if keyIsDown && keyCode(13)	% enter
            theorder = mod(theorder, NumOrders) + 1;
            display_order(window, blankscreen, theorder, rect, fcolor);
        end
        if keyIsDown && keyCode(27)	% escape
            Quit = 1;
            break;
        end
        signal_current = fnDAQNI('GetAnalog',7);
        if abs(signal_current-signal_init) > 0.4
            break;
        end
        if skip ==1
            break
        end
    end
    %
    Priority(1);
    cd(currDir)
%% start the experiment

    % juice and eyetracker timing things
    experimentStart = GetSecs;
    gazeTimer = 0; %keeps track of how long monkey looks at shape
    gazeStart = GetSecs;
    eyeTime = GetSecs;
    eyeRecord = [];
    eyeRecord.x = [];
    eyeRecord.y = [];
    eyeRecord.time = [];
    eyeRecordInterval = 0.15; %give the monkey a little wiggle room for blinks 

    expStart = GetSecs;
    for block = 1:blocksPerRun
        blockStart = GetSecs; 
        blockEnd=expStart+block*blockDur;
        cond = design(block);   thiscond=cond;
       
        if cond == 0
            trialStart=GetSecs;   nextTime=trialStart+ifi; 
            isLoading=0;  isLoaded=0;
            fixTrialDur=(block*blockDur-(GetSecs-expStart))/STIM_PER_BLOCK;
            for trial = 1: STIM_PER_BLOCK
                colors=[round(rand*191) round(rand*191) round(rand*191)];
                colors( ceil (rand*3) ) = 0;
                %colors
                colors = [20 20 20]; %added by RLS 12/8/2013 to make fix gray
                Screen(window,'FillRect',colors);
                
                fixbar = [CX - L/2, CY - L/2, CX + L/2, CY + L/2];    
                Screen(window, 'FillRect', [1 0 0], fixbar);        
                fixbar = [CX - L/4, CY - W/4, CX + L/4, CY + W/4];                
                Screen(window, 'FillRect', [1 0 0], fixbar);           
                fixbar = [CX - W/4, CY - L/4, CX + W/4, CY + L/4];                
                Screen(window, 'FillRect', [1 0 0], fixbar);  
                
                Screen('Flip', window,nextTime);
                nextTime=nextTime+fixTrialDur;
                trialEnd=expStart+(block-1)*blockDur+trial*STIM_DURATION;
                while GetSecs<trialEnd
                    if GetSecs>trialStart+tStartLoad && ~isLoading && block~=blocksPerRun
                        isLoading=1;
                        nextblock=block+1;
                        thiscond=design(nextblock);
                        cd(deblank(STIM_SUB_DIRS{thiscond}));
                        moviename=movieNames{1};  movieNames(1)=[];  
                        Screen('OpenMovie', window, moviename,1); 
                    end
                    if GetSecs > blockEnd-tFinishLoad && ~isLoaded && block~=blocksPerRun
                        [movie(nextblock,1) movDur fps imgw imgh] = Screen('OpenMovie', window, moviename,0);
                        if imgw/imgh<x0/y0, mag=(rect(4)/imgh)/2;  else  mag=(rect(3)/imgw)/2; end
                        nextDispSize=[x0-imgw*mag y0-imgh*mag x0+imgw*mag y0+imgh*mag];
                        isLoaded=1;   %if movie(nextblock,1), isLoaded=1; end
                    end
                    [keyDown, secs, keyCode] = KbCheck();
                    assert(~keyCode(KbName('Escape')),onExit);
                                            
                    cd(rootDir)
                    eyeTrackingBlock()
                end
            end        
            Screen(window,'FillRect',0);  Screen('flip',window);
        else
            for trial = 1: STIM_PER_BLOCK
                trialStart=GetSecs;
                isLoading=0;  isLoaded=0;
                thisTrialEnd=expStart+(block-1)*blockDur+trial*STIM_DURATION;
                Screen('SetMovieTimeIndex', movie(block,trial), 0);
                Screen('PlayMovie', movie(block,trial),1, 0, 0);
                dispSize=nextDispSize;
                while(GetSecs<thisTrialEnd)
                    [tex pts] = Screen('GetMovieImage', window, movie(block,trial), 1);  if tex<=0,break;end;
                    Screen('DrawTexture', window, tex, [], dispSize);
                    
                    fixbar = [CX - L/2, CY - L/2, CX + L/2, CY + L/2];    
                    Screen(window, 'FillRect', [1 0 0], fixbar);        
                    fixbar = [CX - L/4, CY - W/4, CX + L/4, CY + W/4];                
                    Screen(window, 'FillRect', [1 0 0], fixbar);           
                    fixbar = [CX - W/4, CY - L/4, CX + W/4, CY + L/4];                
                    Screen(window, 'FillRect', [1 0 0], fixbar);   
                    Screen('Flip', window);
                    
                    if GetSecs>trialStart+tStartLoad && ~isLoading
                        if trial==STIM_PER_BLOCK
                            nexttrial=1;
                            nextblock=block+1;
                            thiscond=design(nextblock);
                            if thiscond, cd(deblank(STIM_SUB_DIRS{thiscond})); end;
                        else  nexttrial=trial+1;
                        end
                        if thiscond, 
                            isLoading=1;
                            moviename=movieNames{1};  movieNames(1)=[];  
                            Screen('OpenMovie', window, moviename,1); 
                        end; 
                    end
                    [keyDown, secs, keyCode] = KbCheck();
                    assert(~keyCode(KbName('Escape')),onExit);
                    if GetSecs > thisTrialEnd-tFinishLoad && ~isLoaded 
                        if thiscond,
                            [movie(nextblock,nexttrial) movDur fps imgw imgh] = Screen('OpenMovie', window, moviename,0);
                            if imgw/imgh<x0/y0, mag=(rect(4)/imgh)/2;  else  mag=(rect(3)/imgw)/2; end
                            nextDispSize=[x0-imgw*mag y0-imgh*mag x0+imgw*mag y0+imgh*mag];
                        end
                        isLoaded=1;
                    end
                    Screen('Close', tex);  
                    
                    cd(rootDir)
                    eyeTrackingBlock()
                        
                end % end while
                Screen('CloseMovie', movie(block,trial));
            end
            while GetSecs < blockEnd; end
        end
    end

    disp(sprintf('   actual run time:  %3.5f', GetSecs - expStart))

    cd(rootDir);    
    Screen('CloseAll');
    cd EyeRecords;
    savefile = ['EyeRecord_' num2str(eyeRecordRun) '.mat']; 
    save(savefile, 'eyeRecord');
    cd(rootDir);
%     ShowCursor;
    save(thisFilePath);
    fixationCheck(eyeRecord.x,eyeRecord.y,CX,CY)
    
    clear all
catch
    cd(rootDir);
    ShowCursor;
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end 

function eyeTrackingBlock()
% eyetracking and display on secondary screen 
    eyePos = getEyePos(gain,Vcent,[CX, CY]); %will recenter based on fixation cross, not screen center
    eyePos2 = convertPixelCoords([eyePos(1),eyePos(2)],...
        [screenXpixels,screenYpixels],[screenXpixels2,screenYpixels2],...
        [CX,CY],[xCenter2,yCenter2]);
    eyePosRect = CenterRectOnPointd(eyetraceBaseRect,eyePos2(1),eyePos2(2));
    Screen('FillOval',window2,BarColor2,eyePosRect);
    Screen('FrameRect',window2,BarColor2,fixationRect2);
    Screen('Flip',window2);

    %block for checking eye position and giving juice accordingly 
    if GetSecs - eyeTime >= eyeRecordInterval
        eyePos = getEyePos(gain,Vcent,[CX, CY]); %will recenter based on fixation cross, not screen center
        eyePos2 = convertPixelCoords([eyePos(1),eyePos(2)],...
            [screenXpixels,screenYpixels],[screenXpixels2,screenYpixels2],...
            [CX,CY],[xCenter2,yCenter2]);
        eyePosRect = CenterRectOnPointd(eyetraceBaseRect,eyePos2(1),eyePos2(2));
        Screen('FillOval',window2,BarColor2,eyePosRect);
        Screen('FrameRect',window2,BarColor2,fixationRect2);
        Screen('Flip',window2);
        if checkEyeInBox(eyePos,fixationRect)
           gazeTimer = GetSecs - gazeStart;
           BarColor2 = [0 255 0];
        else
           gazeStart = GetSecs;
           gazeTimer = 0;
           BarColor2 = [255 0 0];
        end
        eyeRecord.time = [eyeRecord.time GetSecs];
        eyeRecord.x = [eyeRecord.x eyePos(1)];
        eyeRecord.y = [eyeRecord.y eyePos(2)];
        eyeTime = GetSecs;
    end

    if gazeTimer >= juiceInterval
       fnDAQNI('SetBit',port,1);
       WaitSecs(juiceTime);
       fnDAQNI('SetBit',port,0);
       gazeTimer = 0;
       gazeStart = GetSecs;
    end
    if manualJuiceStart
        fnDAQNI('SetBit',port,1);
        WaitSecs(juiceTime);
        fnDAQNI('SetBit',port,0);
        manualJuiceStart = 0;
        disp('j')
    end
    
    % check for keyboard input
    [keyIsDown,secs,keyCode] = KbCheck;
    
    if keyIsDown && keyCode(82) %r for recenter
        recenter(); 
        keyIsDown = 0;
        disp(Vcent)
    end
    if keyIsDown && keyCode(74) %j to juice
        deliverJuice(); 
        keyIsDown = 0;
    end
    
	% escape
	if keyIsDown && keyCode(27)
		Quit = 1;
        fixationCheck(eyeRecord.x,eyeRecord.y,CX,CY)
    end
end


end

function posNew = convertPixelCoords(posOrig,screenSizeOrig,screenSizeNew,centerOrig,centerNew)
    posNew(1) = (posOrig(1) - centerOrig(1))*screenSizeNew(1)/screenSizeOrig(1) + centerNew(1);
    posNew(2) = (posOrig(2) - centerOrig(2))*screenSizeNew(2)/screenSizeOrig(2) + centerNew(2);
end

function eyePos = getEyePos(gain,Vcent,center)
    global channels
    Vraw = fnDAQNI('GetAnalog',channels);
    Xpos = (Vraw(1) - Vcent(1))*gain(1) + center(1);
    Ypos = (Vraw(2) - Vcent(2))*gain(2) + center(2);
    eyePos = [Xpos Ypos];
end

function gazeInBox = checkEyeInBox(eyePos,centerRect)
    if eyePos(1)>centerRect(1) && eyePos(1) < centerRect(3)...
            && eyePos(2)>centerRect(2) && eyePos(2)<centerRect(4)
       gazeInBox = 1;
    else
       gazeInBox = 0;
    end
end

function recenter()
    global Vcent channels
    Vcent = fnDAQNI('GetAnalog',channels);
end

function deliverJuice()
    global manualJuiceStart
    manualJuiceStart = 1;
end

function percentFixation = fixationCheck(x,y,CX,CY)
    s = 146.2603;
    count = 0;
    for i = 1:numel(x)
        if x(i) > CX-s && x(i) < CX+s && y(i) < CY+s && y(i) > CY-s
            count = count+1;
        end
    end

    percentFixation = count / numel(x);
end


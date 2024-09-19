function meridian_mapper_RLS(no_serial)

%SETUP: screen_width and screen_height don't need to be set manually if we
%want fixation in the center of the screen
%Get number of pixels on diameter of screen, then figure out if we want to
%fill that with the stim or fill a square circumscribed within that circle.
%Adjust lines 129,130 accordingly 

% this is the generic stimulus presentation program in Bremen, any special
% features nee
% ded for other tasks will be implemented here, if possible, so
% always use this as template...

% make sure the old psychtoolbox 2.56 is in the path
addpath(genpath('.\Psychtoolbox'), '-begin')

%fnDAQNI('Init',0); REMOVED by KARTHIK
% prepare a clean environment...
clear Screen
clear PsychSerial
clear iow
clear all

DAQ('Debug', false); % Set DAQ to not debug
DAQ('Init');
whichScreen = 1;
whichScreen2 = 2;    
xChannel = 3;
yChannel = 2;
curdir = pwd;
if ~isdir('EyeRecords');
    mkdir EyeRecords;
end
cd EyeRecords;
eyeRecordRun = length(dir('EyeRecord*')) + 1;
cd(curdir);


% ISCAN related parameter sm: set to one to use the serial port to control ISCAN serial trigger
% only useful with an ISCAN system...
use_serial = 0;
if use_serial == 1,
	serial_port = 'com1';
	portA = PsychSerial('Open', 'com1', 'com1', 9600);
	iscan_start_code = char(hex2dec('84'));
	iscan_stop_code = char(hex2dec('88'));
end

skip_dummies = 1;	% this has to be initialized somewhere...

% use digital IO?
use_iow = 0;	%this only works with code mercenaries IO-warrior40 with our additional circuits...
if use_iow == 1,
	% get the symbolic names for calling iow
	io = get_io_struct;
	% open the device
	io_id = iow(io.opendevice);
	% initialise all ports to enable read
	data = uint32(2^32 - 1);
	iow(io.write_io, io_id, data);
    sequence = 'joe';
    %sequence = 'undistort';
    if (strmatch('joe', sequence)),
        MRI_trig = 1;	% 32 bit position (1-based) of the MRI scanners acq trigger input on the iow
    else
        MRI_trig = 3;	% for user trigger of the scanner (not active for the dummy scans)
 	    skip_dummies = 1;
    end
% 	%	use Input 3 to connect the 200ms scanner trigger for the multiecho sequence
	act_state = 0;	% what level on MRI_TRIG tells us to start? The optocoupler inverts!
	% configuration for wave
	out_data = data;
	wave_trig = 17;
	wave_active = 0;	
	% joe's sequence uses a debug trigger of the scanner, that also fires during
	% shimming, if read_iow is set to 0, the iow input trigger can be enabled by
	% pressing 's' during the inter-stimulation periods
	read_iow = 0;
	joe_seq = 1;
end
% fixation cross, define length and widths of arms and the color
L = 20;  %orig: 12
W = 10;  %orig: 4
BarColor = [255 0 0];	% red, [255 255 255] is white;
% define truth values...
FALSE = 0;
TRUE = 1;
% percent of x and y position "uncertainty", relative to image size
rand_img_offset = 0; % 0 for face/body localizer, 20 for cartoon template

% the resolution in bremen's scanner, the boston chair pushed into the bore up
% to the fifth complete ring from the back (minus one finger); this results in a
% eye screen distance of 49cm, at the smalles zoom with the screen 3 cm in the
% small bore, 400 pixels@1280bx1024 result in a projection of 10.4cm
hb_deg_per_pixel = (atan(10.4 / 49.0) * 180 / pi)/ 400;
% should stimulation and iscan recording automatcally stop at the end of the
% last block or cycle around?
stop_at_runend = 1;


%%%%%%%%%%%May need to edit%%%%%%%%%%%%%%
experiment = 'meridian_mapper';%'abs_cartoon_tmpl_2';%'face_body_places_localizer';%'cartoonadapt';
exp_order = 'meridian_mapper';%'abs_cartoon_tmpl_2';%'face_localizer_monkey';%'body_localizer';%'face_localizer_monkey2'%'face_localizer_monkey';%'cartoonadapt';face_localizer_monkey
% list.dir = fullfile('C:', 'space', 'data', 'stimulation', 'stim_hb', 'morgue', 'stim_block_order_lists');
list.dir = pwd;
list.stim = ['stimlist_', experiment, '', '.txt'];%'stimlist_familiarity.txt';
list.block = ['blocklist_', experiment, '', '.txt'];%'blocklist_familiarity.txt';
list.order = ['orderlist_', exp_order, '', '.txt'];%'orderlist_familiarity.txt';
ImageDir = fullfile(pwd, 'images'); %directory where images are stored
default_fmt = 'tif';
[ImNumArray ImageArray] = textread(fullfile(list.dir, list.stim),'%s %s');
ImageOrderArray = load(fullfile(list.dir, list.order), '-ascii')
ImageNumArray = str2num(char(ImNumArray))
[blocklist] = loadblocklist(fullfile(list.dir, list.block))
tmp = save_lists(list.dir, list.stim, list.block, list.order);

%MRT related variables...
% the repetition time, needed as we express everything as multiple of the TR (decimal fractions are okay)
TR = 3; 
% if dummy scans are used (as should be) specify how many, this needed if the
% stimulation is started by hand at the moment the scanner makes its noises, or
% with one of our sequences, which puts out an acqisition trigger even for the
% dummy volumes...
dummy_acqs = 0;
if (skip_dummies == 1),
	dummy_acqs = 0;	% the scanner's user trigger is not active during the dummy scans
end
% the length of each block in TRs, this has to account for the dummy scans as
% well, even, if they are set to 0; the orderlist has to be of the same length
acqs_per_block = [dummy_acqs 12 12 12 12 12 12 12 12 12 12 12 12 12 12 12 12];
BlockLengths = acqs_per_block * TR;	% calculate the duration of each block
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% out put image size in voxel

%--------
%screen = 0;
%[windowPtr,rect] = Screen(screen,'OpenWindow');
%screen_width = 925; % orig: 1280;  changed to fit MGH projector
%screen_height = 925; %orig: 1024;  changed to fit MGH projector

%scale to boston size (183 pixels at 640bx480, where 100 pixels equal 7 degree)
boston_pixRect_deg = 183 * 7 / 100.0;
img_height_pix = round(boston_pixRect_deg / hb_deg_per_pixel);
img_width_pix = img_height_pix;

img_scale = 1;%changed from 1 to .7 to fit MGH projector 
img_height_pix = 1080 * img_scale; 
img_width_pix = 1920 * img_scale; 

x_offset_limit = (round(img_width_pix * (1 + rand_img_offset / 100)) - img_width_pix);
y_offset_limit = (round(img_height_pix * (1 + rand_img_offset / 100)) - img_height_pix);

ItemDur = 0.5;  %duration of each image in seconds

%-------------

NumImages = length(ImageArray);
[NumBlocks NumOrders] = size(ImageOrderArray);

warning off;

% screen_width = screenRect(3);
% screen_height = screenRect(4);


bcolor=[0 0 0]; % background color=black
fcolor=[255 255 255]; % forground color=white
gray = [128 128 128];
%gray = [0 0 0];
maskcolor = gray; %[0 0 0];
maskcolor = [0 0 0];

% this is going to be the desired rectangle --images will be scaled appropriately
pixRect = [0 0 img_width_pix img_height_pix];
wigglemaskRect = [0 0 round(img_width_pix * (1 + rand_img_offset / 100)) round(img_height_pix * (1 + rand_img_offset / 100))];
[window, screenRect] = Screen('OpenWindow', whichScreen, bcolor, [], 32);
[screen_width, screen_height] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(screenRect);

CX = xCenter;
CY = yCenter;

%define fixation area 
screen_width_cm = 27.5;
ppcm = screen_width / screen_width_cm;
fixation_deg = 1.5 * pi / 180;
monkey_distance_cm = 40;
x = tan(fixation_deg) * monkey_distance_cm * ppcm;
fixRectDim = [0 0 2*x 2*x];
fixRect = CenterRectOnPointd(fixRectDim,xCenter,yCenter);
disp(fixRectDim);
centerLoc = CenterRect(pixRect, screenRect);
PixLoc = centerLoc;
wigglemaskLoc = CenterRect(wigglemaskRect, screenRect);

%% create enough offscreen windows for each picture in the experiment
for i = 1:NumImages
	offScrPtr(i) = Screen(window, 'OpenOffscreenWindow', bcolor, pixRect);
end

%Initialize rand to a different state each time: 
rand('state', sum(100*clock));

mask = Screen(window, 'OpenOffscreenWindow', maskcolor, pixRect);
blank = Screen(window, 'OpenOffscreenWindow', gray, pixRect);
blankscreen = Screen(window, 'OpenOffscreenWindow', gray, screenRect);

for i = 1: NumImages
	% get the format from the image extension, or else
	[img_pathstr, img_name, img_ext] = fileparts(fullfile(ImageDir, ImageArray{i}));
	if (length(img_ext) > 2),
		fmt = img_ext(2:end);
	end
	if isempty(imformats(fmt)),
		fmt = default_fmt;
	end
	img = imread(fullfile(ImageDir, ImageArray{i}), fmt);
	img = double(img);
	img_dim = size(img);
	Screen(offScrPtr(i), 'PutImage', img, pixRect);
end


%%Load some functions to speed up beginning (??)
ItemDur;
%hidecursor;
Screen(window, 'WaitBlanking', 1);

% clear the io warrior read immediate buffer (max 8 reports)
if use_iow == 1,
	[in_data, change] = iow(io.readimmediate, io_id);
	while change ==1,
		[in_data, change] = iow(io.readimmediate, io_id);
	end
end

%% setup second screen for eye tracking
[window2, screenRect2] = Screen('OpenWindow', whichScreen2, [255 255 255], [], 32);
[screen_width2, screen_height2] = Screen('WindowSize', window2);
[CX2, CY2] = RectCenter(screenRect2);

screen_width2_cm = 31;
ppcm2 = screen_width2 / screen_width2_cm;
screen2Scale = screen_width2 / screen_width;

fixRectDim2 = fixRectDim*screen2Scale;
fixRect2 = CenterRectOnPointd(fixRectDim2,CX2,CY2);
disp(fixRectDim2);

%eye tracking and reward things
%fnDAQNI('Init',0) Removed by Karthik
global dotSize gain channels port Vcent manualJuiceStart
gain{1} =  -1205;
gain{2} = 520;

Vcent = [0 0];
channels = [3, 2];
port = 1;
manualJuiceStart = 0;
manualJuicing = 0;
juiceTime = 0.03;
dotSize = 4;
dotRect = [0 0 dotSize dotSize];
%% Cue word to remind task and check screen orientation
theorder = 1;
display_order(window, blankscreen, theorder, screenRect, fcolor);
fixbar = [CX - L/2, CY - L/2, CX + L/2, CY + L/2];
	Screen(window, 'FillRect', [0 0 0], fixbar);
	fixbar = [CX - L/4, CY - W/4, CX + L/4, CY + W/4];
	Screen(window, 'FillRect', BarColor, fixbar);
	fixbar = [CX - W/4, CY - L/4, CX + W/4, CY + L/4];
	Screen(window, 'FillRect', BarColor, fixbar);
    Screen('FrameRect',window,[255 0 0],fixRect);
	Screen('Flip', window); 
    manualJuiceTimer = GetSecs;
 baselineVoltage = DAQ('GetAnalog', 8);
while 1
    
	[keyIsDown, secs, keyCode] = KbCheck;

	%if keyCode(13) break; % start only when "return" key is pressed (keyCode for "return" is 13)
	if keyIsDown && keyCode(32)
		break; % start when space key is pressed
    end
    %if keyIsDown && keyCode(187)
    ttlVolt = DAQ('GetAnalog',8 );
    if abs(ttlVolt - baselineVoltage) > 0.4
        break; % trigger from MR scanner
    end
	if keyIsDown && keyCode(13)	% enter
		theorder = mod(theorder, NumOrders) + 1;
		display_order(window, blankscreen, theorder, screenRect, fcolor);
	end
	if keyIsDown && keyCode(27)	% escape
		Quit = 1;
		break;
    end
    %Don't know what this is for -Karthik
    %signal = fnDAQNI('GetAnalog',7);
    %signal2 = fnDAQNI('GetAnalog',7);
    %if signal2 > signal+0.1 || signal2 < signal-0.1 
     %   break;
    %end

end
% signal running trial to wave system...
if use_iow == 1,
	signal_wave = 1;
	iow(io.write_io, io_id, bitset(out_data, wave_trig, wave_active));
end
%
Priority(1);

experimentStart = GetSecs;
keyIsDown = FALSE;
Quit = FALSE;
%CX = screen_width / 2.0; %1024/2.;
%CY = screen_height / 2.0; %768/2.; 

% auto size to current screen...
% theorder = 1;  %we start with the first order column
blockindex = 1;
picindex = 1;
theblock = ImageOrderArray(blockindex,theorder); %we start with the first image specified in the first order column
thepic = blocklist{theblock}(picindex);
NumStimsInBlock = length(blocklist{theblock});
imcount = 1;
stop_run = 0;

Screen('CopyWindow', blankscreen, window);
Screen(window, 'FillRect', maskcolor, wigglemaskLoc);
Screen('Flip',window);

CycleStart = GetSecs;
BlockStart = GetSecs;
StimTarget = BlockStart + ItemDur * imcount;
BlockTarget = CycleStart + BlockLengths(1);
manualJuiceTimer = GetSecs;
eyeRecordInterval = 0.1;
eyeTime = GetSecs;
eyeRecord = [];
eyeRecord.x = [];
eyeRecord.y = [];
eyeRecord.time = [];
gazeTimer = 0;
gazeStart = GetSecs;
juicing = 0;
juiceInterval = 1.5;
blockLengths = [];
%start eye movement record
if use_serial == 1,
	PsychSerial('Write',  portA, iscan_start_code);
	iscan_active = 1;
end
curPixLoc = PixLoc;

while (~Quit)
    %display stimulus and fixation
	Screen('CopyWindow', offScrPtr(thepic), window, [], curPixLoc);
	fixbar = [CX - L/2, CY - L/2, CX + L/2, CY + L/2];
	Screen(window, 'FillRect', [0 0 0], fixbar);
	fixbar = [CX - L/4, CY - W/4, CX + L/4, CY + W/4];
	Screen(window, 'FillRect', BarColor, fixbar);
	fixbar = [CX - W/4, CY - L/4, CX + W/4, CY + L/4];
	Screen(window, 'FillRect', BarColor, fixbar);
	Screen('Flip', window); 
    
    %display fixation rect on second screen
    
    [Xpos,Ypos] = getEyePos([CX,CY]);
    if GetSecs - eyeTime >= eyeRecordInterval
        eyeRecord.time = [eyeRecord.time GetSecs];
        eyeRecord.x = [eyeRecord.x Xpos];
        eyeRecord.y = [eyeRecord.y Ypos];
        eyeTime = GetSecs;
    end
    [Xpos2,Ypos2] = convertEyePos(Xpos,Ypos,[CX,CY],[CX2,CY2],screen2Scale);
    eyePosRect = CenterRectOnPointd(dotRect,Xpos2,Ypos2);
    
    Screen('FrameRect',window2,[255 0 0],fixRect2);
    Screen('FillOval',window2,[255,0,0],eyePosRect);
    Screen('Flip', window2);
    
    if checkEyeInBox([Xpos,Ypos],fixRect)
       gazeTimer = GetSecs - gazeStart;
    else
       gazeStart = GetSecs;
       gazeTimer = 0;
    end

    %juice things
    
    if ~juicing && gazeTimer >= juiceInterval

       %fnDAQNI('SetBit',port,0);
       %fnDAQNI('SetBit',port,1); Karthik Changed
       DAQ('SetBit',[1 1 1 1]);
       pause(0.018);
       %fnDAQNI('SetBit',port,0);
       DAQ('SetBit',[0 0 0 0]);
       juiceStart = GetSecs;
       juicing = 1;
       gazeTimer = 0;
    end
    if juicing && (GetSecs - juiceStart >= juiceTime)
        %fnDAQNI('SetBit',port,0); Karthik
        DAQ('SetBit',[0 0 0 0]);
        juicing = 0;
        gazeStart = GetSecs; %this should either be here or in the if statement above
    end
    if manualJuiceStart
        %fnDAQNI('SetBit',port,0);
        %fnDAQNI('SetBit',port,1); Karthik
        DAQ('SetBit',[1 1 1 1]);
        pause(0.018);
        %fnDAQNI('SetBit',port,0);
        %DAQ('SetBit',[0 0 0 0]);
        manualJuiceTimer = GetSecs;
        manualJuicing = 1;
        manualJuiceStart = 0;
    end
    if manualJuicing && GetSecs - manualJuiceTimer > juiceTime
        %fnDAQNI('SetBit',port,0);
        DAQ('SetBit',[0 0 0 0]);
        Beeper(400);
        manualJuicing = 0;
    end
    
	if (GetSecs > BlockTarget)  %start a new block
		if stop_at_runend == 1,
			if mod(blockindex, NumBlocks) == 0,
				stop_run = 1;
			end
		end
		blockindex = mod(blockindex, NumBlocks) + 1;
		if (blockindex == 1)  %%starting over
			CycleStart = GetSecs;
		end
		theblock = ImageOrderArray(blockindex,theorder);
		theblock
		imcount = 1;
        blockTime = GetSecs - BlockStart;
        blockLengths = [blockLengths blockTime];
        disp(['block end: ' num2str(blockTime)]);
		BlockStart = GetSecs;
		BlockTarget = CycleStart + sum(BlockLengths(1:blockindex));
		StimTarget = BlockStart + ItemDur * imcount;
		NumStimsInBlock = length(blocklist{theblock});
		picindex = 1;
		thepic = blocklist{theblock}(picindex); %set appropriate pic for index
	end
	if (GetSecs > StimTarget)  %start a new picture
		imcount = imcount + 1;
		picindex = mod(picindex, NumStimsInBlock) + 1; % increment index
		thepic = blocklist{theblock}(picindex); %set appropriate pic for index
		StimTarget = BlockStart + ItemDur * imcount;
		% clear the area of the wiggeled image, if it was wiggeled
		if (rand_img_offset ~= 0),
			Screen('CopyWindow', mask, window, [], curPixLoc);
			curPixLoc = wiggle_pos(PixLoc, x_offset_limit, y_offset_limit);
		end
    end
	[keyIsDown,secs,keyCode] = KbCheck;
	% escape
	if keyIsDown && keyCode(27)
		Quit = TRUE;
		% return or end of one cycle of stimulation
	elseif ((keyIsDown && keyCode(13)) | stop_run == 1),
		Restart = TRUE;
		%stop eye movement record
		if use_serial == 1,
			PsychSerial('Write', portA, iscan_stop_code);
			iscan_active = 0;
		end
		
		% signal no running trial to wave system...
		if use_iow == 1,
			signal_wave = 0;
			iow(io.write_io, io_id, bitset(out_data, wave_trig, ~wave_active));
		end

		% clear the io warrior read immediate buffer (max 8 reports)
		if use_iow == 1,
			[in_data, change] = iow(io.readimmediate, io_id);
			while change ==1,
				[in_data, change] = iow(io.readimmediate, io_id);
			end
        end
       % fnDAQNI('SetBit',port,0); Removed Karthik
		Screen('FillRect',window,[255,0,0],screenRect);
        Screen('Flip',window);
		theorder = mod(theorder, NumOrders) + 1;
		blockindex = 1;
		picindex = 1;
		theblock = ImageOrderArray(blockindex,theorder); %we start with the first image specified in the first order column
		thepic = blocklist{theblock}(picindex);
		NumStimsInBlock = length(blocklist{theblock});
		imcount = 1;
		stop_run = 0;
		display_order(window, blankscreen, theorder, screenRect, fcolor);
		while 1
			[keyIsDown, secs, keyCode] = KbCheck;
			%if keyCode(13) break; % start only when "return" key is pressed (keyCode for "return" is 13)
			if keyIsDown && keyCode(32)
				break; % start when space key is pressed
            end
            if keyIsDown && keyCode(187)
				break; % start with trigger from scanner (=) or when (=) is pressed
			end
			if keyIsDown && keyCode(27)
				Quit = 1;
				break;
			end
			if keyIsDown && keyCode(13)
				theorder = mod(theorder, NumOrders) + 1;
				display_order(window, blankscreen, theorder, screenRect, fcolor);
			end
			% only read the iow MRI_trig after 's' has been pressed...
			if keyIsDown && keyCode(83)
				read_iow = 1;
			end
			% clear the io warrior read immediate buffer (max 8 reports)
			if (use_iow == 1) & (read_iow == 0),
				[in_data, change] = iow(io.readimmediate, io_id);
				while change == 1,
					[in_data, change] = iow(io.readimmediate, io_id);
				end
			end

			if (use_iow == 1) & (read_iow == 1),
				[in_data, change] = iow(io.readimmediate, io_id);
				if (change == 1),
					if (bitget(in_data, MRI_trig) == act_state),
						if joe_seq == 1,
							read_iow = ~read_iow;
						end
						break;
					end
				end
			end
		end
		% signal running trial to wave system...
		if use_iow == 1,
			signal_wave = 1;
			iow(io.write_io, io_id, bitset(out_data, wave_trig, wave_active));
		end

		Screen('CopyWindow', blankscreen, window);
		Screen(window, 'FillRect', maskcolor, wigglemaskLoc);
		CycleStart = GetSecs;
		BlockStart = GetSecs;
		StimTarget = BlockStart + ItemDur * imcount;
		BlockTarget = CycleStart + BlockLengths(1);
		if use_serial == 1 && Quit == 0,
			PsychSerial('Write', portA, iscan_start_code);
			iscan_active = 1;
		end
    end
    if keyIsDown && keyCode(82) %r for recenter
       recenter(); 
    end
    if keyIsDown && keyCode(74) %uice to juice
       deliverJuice(); 
    end
    if keyIsDown && keyCode(65) %a to grab attention
        grabAttention(window,screenRect,0.5);
    end
end
%
Priority(0);

experimentEnd = GetSecs;
experimentDuration = experimentEnd - experimentStart
%showcursor;

Screen('CloseAll');
if use_serial == 1,
	if iscan_active == 1,
		PsychSerial('Write', portA, iscan_stop_code);
    end
	PsychSerial('Close', 'com1'),
	clear PsychSerial;
end
if use_iow == 1,
	% make sure wave stops it's reward system
	if signal_wave == 1,
		iow(io.write_io, io_id, bitset(out_data, wave_trig, ~wave_active));
	end
	% close the device
	iow(io.closedevice, io_id);
	clear iow
end
warning on;
cd EyeRecords;
savefile = ['EyeRecord_' num2str(eyeRecordRun) '.mat']; 
save(savefile, 'eyeRecord');
cd(curdir);
%save('test.mat');
fixationCheck(eyeRecord.x,eyeRecord.y)
return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret_val = save_lists(list_dir, list_stim, list_block, list_order)
% create a YYYYMMDD sub directory and copy the used lists into this dir...
% copy the whole m-file into the save directory
warning off MATLAB:MKDIR:DirectoryExists;
date_v = datevec(now);
% create the current sub directory (yyyymmdd)
targ_dir_name = [num2str(date_v(1), '%04d'), num2str(date_v(2), '%02d'), num2str(date_v(3), '%02d'), '_stim'];
time_prefix = [num2str(date_v(4), '%02d'), num2str(date_v(5), '%02d'), num2str(date_v(6), '%02.0f')];
mkdir(list_dir, targ_dir_name);
% copy the three relevant lists into today's sub directory
copyfile(fullfile(list_dir, list_stim), fullfile(list_dir, targ_dir_name, list_stim));
copyfile(fullfile(list_dir, list_block), fullfile(list_dir, targ_dir_name, list_block));
copyfile(fullfile(list_dir, list_order), fullfile(list_dir, targ_dir_name, list_order));
% block_id.bat creates a list of the BlockNN labels of the block list.
%copyfile(fullfile(list_dir, 'block_id.bat'), fullfile(list_dir, targ_dir_name, 'block_id.bat'));
[m_pathstr, current_m_file, ext] = fileparts([mfilename('fullpath'), '.m']);

%copyfile(fullfile( m_pathstr, [current_m_file, '.m']), fullfile(list_dir, targ_dir_name, [current_m_file, '.m']));
copyfile(fullfile( m_pathstr, [current_m_file, '.m']), fullfile(list_dir, targ_dir_name, [time_prefix, '_', current_m_file, '.m']));
ret_val = 1;

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [blocklist] = loadblocklist(filename)

NumBlocks =  0;
fid = fopen(filename, 'r');
blocklist = cell(1);

while 1
	tline = fgetl(fid);
	if ~ischar(tline), break, end
	a = findstr(tline, 'Block');
	if (a>=1)
		NumBlocks = NumBlocks + 1;
		i = 0;
	else
		i = i+1;
		blocklist{NumBlocks}(i) = str2num(tline);
	end
end

line = fgetl(fid);
return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function display_order(window, blankscreen, theorder, screenRect, fcolor)

Screen('CopyWindow', blankscreen, window);
Screen(window, 'TextSize', 40);
buffer = sprintf('ready %d', theorder);
Screen(window, 'DrawText', buffer, (screenRect(3) / 2) - 100, screenRect(4) / 2, fcolor);
pause(0.5);

return

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [curPixLoc] = wiggle_pos(PixLoc, x_offset_limit, y_offset_limit)
% randomise the pixrect by =- offset_limit pixels
x = (rand - 0.5) * 2 * x_offset_limit / 2;
y = (rand - 0.5) * 2 * y_offset_limit / 2;
curPixLoc = PixLoc + [x y x y];

return

function [Xpos,Ypos] = getEyePos(center)
    global channels Vcent gain
    %Vraw = fnDAQNI('GetAnalog', channels); % Changed by Karthik
    Vraw = DAQ('GetAnalog', channels);
    Xpos = (Vraw(1) - Vcent(1))*gain{1} + center(1);
    Ypos = (Vraw(2) - Vcent(2))*gain{2} + center(2);    
 return
 
function [Xpos2,Ypos2] = convertEyePos(Xpos,Ypos,center,center2,scale)
    Xpos2 = (Xpos-center(1))*scale + center2(1);
    Ypos2 = (Ypos-center(2))*scale + center2(2);
return 

function recenter()
    global Vcent channels
    %Vraw = fnDAQNI('GetAnalog',channels);
    Vraw = DAQ('GetAnalog',channels);
    Vcent = Vraw;
return

function deliverJuice()
    global manualJuiceStart
    manualJuiceStart = 1;
return

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
return

function gazeInBox = checkEyeInBox(eyePos,centerRect)
    if eyePos(1)>centerRect(1) && eyePos(1) < centerRect(3)...
            && eyePos(2)>centerRect(2) && eyePos(2)<centerRect(4)
       gazeInBox = 1;
    else
       gazeInBox = 0;
    end

return
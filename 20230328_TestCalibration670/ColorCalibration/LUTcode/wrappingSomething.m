global fileroot bitDepth gray PRport values PR
dbstop if error

%% Init
prompt = 'Enter device name:';
deviceName = char(strrep(strrep(input(prompt, 's'), '%', '_'), ' ', '_'));
thisCalibName = [date,'_',deviceName];
thisCalibFolder = fullfile('..', 'measurements', thisCalibName);
mkdir(thisCalibFolder)

fileroot = fullfile(thisCalibFolder, filesep, thisCalibName);

PRport = 'COM4';%/dev/cu.usbmodem301';
PR = '655'; % Currently set up to handle 655 or 670. Could be easily modified in JoshCalibforBL to handle PR 650/705.

whichDevice = questdlg('Monitor or Tablet?', 'Device',...
    'Monitor', 'Tablet', 'None');
if strcmp(whichDevice, 'Tablet')
    bitDepth = 8;
else
    whichBitDepth = questdlg('8 (256 values) or 16 (65536 values) Bits?',...
        'Bit depth', '8', '16', 'None');
    bitDepth = str2num(whichBitDepth);  
end  
  
gray = round([0.5 0.5 0.5]*2^bitDepth-1); 

nbMeasures = 16; %with 16 all inputs are integers and decent spanning
values = (linspace(0,1,nbMeasures)) * (2^bitDepth-1);

%% Diplay dot to set up SR
global windowPTR whichScreen

switch whichDevice
    case 'Tablet'
        windowPTR = figure('units','normalized','outerposition',[0.4 0.4 0.2 0.2]);
        pause(1)
        CPforBLnoPTB([2^bitDepth-1,2^bitDepth-1,2^bitDepth-1])
    otherwise
        whichScreen = max(Screen('Screens')); %0
        Screen('Preference', 'SkipSyncTests', 1);
        [windowPTR,screenRect] = Screen('Openwindow',whichScreen,round(((2^bitDepth)-1)/2),[],32,2);
        %      [windowPTR,screenRect] = Screen('Openwindow',whichScreen,round(((2^bitDepth)-1)/2),[0 0 400 400],32,2);
        switch bitDepth
            case 8
                CPforBL255(2^bitDepth-1)
            case 16
                CPforBL(2^bitDepth-1)
        end
end

KbStrokeWait;
switch whichDevice
    case 'Tablet'
        close(windowPTR)
    otherwise
        Screen('CloseAll')
end
        
%% Take measurements
switch whichDevice
    case 'Tablet'
        BaseLum255noPTB()
    otherwise
        BaseLumMD()
end

%% Make LUT and save gamma fit, correction and LUT

makelutNEW(bitDepth, 0)

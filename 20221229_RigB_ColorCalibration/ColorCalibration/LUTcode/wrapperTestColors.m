global fileroot bitDepth gray PRport values
dbstop if error
%%%%%%%%
% Wrapper for collecting spectral information regarding colors you want to
% test. Modified from WrappingSomething by Stuart Duffield 10/14/2021. A
% previous version was also written by Stuart earlier, although this
% version is lost. The base of this script (almost all) was written by Marianne Duyck
% ~2018?
%%%%%%%%
%% Init
prompt = 'Enter device name: ';
deviceName = char(strrep(strrep(input(prompt, 's'), '%', '_'), ' ', '_'));
thisCalibName = [date,'_',deviceName];
thisCalibFolder = fullfile('..', 'measurements', thisCalibName);
mkdir(thisCalibFolder)

fileroot = fullfile(thisCalibFolder, filesep, thisCalibName);

PRport = '/dev/cu.usbmodem144401';
 
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

%valuesPath = '/Users/duffieldsj/Documents/GitHub/Personal-Scripts/jeevesRGB_new.csv'
%values = csvread(valuesPath)
%values = round(values)
values = [255 0 0;0 255 0;0 0 255]


%% Diplay dot to set up SR
global windowPTR whichScreen

switch whichDevice
    case 'Tablet'
        windowPTR = figure('units','normalized','outerposition',[0.4 0.4 0.2 0.2]);
        pause(1)
        CPforBLnoPTB([2^bitDepth-1,2^bitDepth-1,2^bitDepth-1])
    otherwise
        whichScreen = 0 %max(Screen('Screens')); %0
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
        BaseLumTestColorsMDSD()
end

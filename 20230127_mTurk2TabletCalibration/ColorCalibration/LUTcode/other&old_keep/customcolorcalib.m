load('13-Sep-LUV16_chroma41_to_check.mat')

% MD - to check some specific colors

% %% Automatic
% for icolor=1:size(rgb_monitor, 1)
%     measuredVals(icolor)=JoshCalib(rgb_monitor(icolor,:));
% end

%% Manual
global screenID
screenID = max(Screen('Screens'));
for icolor=1:size(rgb_vals, 1)
     CPforJC(rgb_vals(icolor,:))
     KbStrokeWait;
     Screen('CloseAll')
end
 
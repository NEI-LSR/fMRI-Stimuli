function [coordinates, volts] = GetAveragedFixationCoordinates(params)
    
    Datapixx('RegWrRd');                                                                                                         % Updating registers
    Datapixx('GetAdcStatus');                                                                                                    % Checking ADC status
    volts =NaN(16,params.run.fixation.numSamples);
    
    for idx = 1:params.run.fixation.numSamples
        Datapixx('RegWrRd');                                                                                                     % Updating registers
        volts(:,idx) = Datapixx('GetAdcVoltages');                                                                               % Reading ADC voltages for all channels
        Datapixx('RegWrRd');                                                                                                     % Updating registers
    end
    
    if strcmpi(params.run.fixation.eye2track, 'left')
        volts = mean(volts(params.datapixx.adcChannels(2:3),:),2)';                                                              % Selecting ADC voltages for channels 1 & 2 (left eye XY)
    elseif strcmpi(params.run.fixation.eye2track, 'right')
        volts = mean(volts(params.datapixx.adcChannels(5:6),:),2)';                                                              % Selecting ADC voltages for channels 4 & 5 (right eye XY)
    end
    
    degrees = (volts + params.datapixx.calibrationOffset) .* params.datapixx.calibrationGain .* params.datapixx.calibrationSign; % Converting voltages into degrees of visual angle (from center)
    pixels  = degrees .* params.display.pixPerDeg;                                                                               % Converting degrees into screen pixels
    coordinates = pixels + params.display.monkRectCenter;                                                                        % Centering pixels relative to screen center

end % Function end

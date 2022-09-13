function [coordinates, volts] = GetFixationCoordinates(params)
    
    Datapixx('RegWrRd');                                                                                                         % Updating registers
    Datapixx('GetAdcStatus');                                                                                                    % Checking ADC status
    Datapixx('RegWrRd');                                                                                                         % Updating registers
    volts = Datapixx('GetAdcVoltages');                                                                                          % Reading ADC voltages for all channels
    Datapixx('RegWrRd');                                                                                                         % Updating registers
    
    if strcmpi(params.run.fixation.eye2track, 'left')
        volts = volts(params.datapixx.adcChannels(2:3));                                                                         % Selecting ADC voltages for channels 1 & 2 (left eye XY)
    elseif strcmpi(params.run.fixation.eye2track, 'right')
        volts = volts(params.datapixx.adcChannels(5:6));                                                                         % Selecting ADC voltages for channels 4 & 5 (right eye XY)
    end
    
    degrees = (volts + params.datapixx.calibrationOffset) .* params.datapixx.calibrationGain .* params.datapixx.calibrationSign; % Converting voltages into degrees of visual angle (from center)
    pixels  = degrees .* params.display.pixPerDeg;                                                                               % Converting degrees into screen pixels
    coordinates = pixels + params.display.monkRectCenter;                                                                        % Centering pixels relative to screen center

end % Function end

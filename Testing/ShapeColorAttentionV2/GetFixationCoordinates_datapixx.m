function [coordinates,volts] = GetFixationCoordinates_datapixx(params)
    DataPixx('RegWrRd'); % Updating registers
    Datapixx('GetAdcStatus'); % Checking ADC status
    Datapixx('RegWrRd'); % Updating registers
    volts = Datapixx('ReadAdcBuffer',params.numVoltSamples,-1); % Reading ADC voltages for all channels
    Datapixx('RegWrRd'); % Updating registers

    if strcmpi(params.eye2track, 'left') % is it tracking the left eye?
        volts = mean(volts(params.datapixx.adcChannels(2:3),:),2)'; % Selecting ADC voltages for channels 1 & 2 (left eye XY)
    elseif strcmpi(params.eye2track, 'right'); % is it tracking the right eye?
        volts = mean(volts(params.datapixx.adcChannels(2:3),:),2)'; % Selecting ADC voltages for channels 1 & 2 (left eye XY)
    end

    offsets = [params.xOffset params.yOffset]; % Combine to form offsets
    gains = [params.xGain params.yGain]; % Combine to form gains
    pixels = volts .* gains; % Convert volts to pixels
    coordinates = pixels + offsets; % Offset the pixels

end % Function end



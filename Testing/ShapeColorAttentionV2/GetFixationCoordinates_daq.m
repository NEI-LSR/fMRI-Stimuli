function [coordinates,volts] = GetFixationCoordinates_daq(params)
    volts = DAQ('GetAnalog',params.daqChannels); % Get the voltages from the selected DAQ channels
    offsets = [params.xOffset params.yOffset]; % Combine offsets
    gains = [params.xGain params.yGain]; % Combine gains
    pixels = volts .* gains; % Convert volts to pixels
    coordinates = pixels + offsets; % Offset the pixels
end % Function end
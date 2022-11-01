function [] = Wait4ScannerTTL_daq(params)
        baselineVoltage = DAQ('GetAnalog',params.ttlChannel); % Get the baseline voltage
        while true
            [keyIsDown,secs,keyCode] = KbCheck; % Get keyboard inputs
            ttlVolt = DAQ('GetAnalog',params.daq.ttlChannel); % Get current voltage
            if keyCode(KbName('space')) % If space is pressed
                break; % Begin
            elseif abs(ttlVolt - baselineVoltage) > 0.4 % If TTL voltage has changed by more than said values
                break; % Begin
            end
        end
end % End function
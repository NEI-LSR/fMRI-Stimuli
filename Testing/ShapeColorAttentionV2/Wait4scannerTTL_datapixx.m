function [] = Wait4scannerTTL_datapixx(params)
    
    Datapixx('RegWrRd');
    volts = Datapixx('GetAdcVoltages');
    Datapixx('RegWrRd');
    initialVoltage = volts(params.datapixx.adcChannels(8));
    thresholdTTL = 2.5;
    
    fprintf('Waiting for scanner TTL... ');
    if initialVoltage < thresholdTTL
        while true
            Datapixx('RegWrRd');
            volts = Datapixx('GetAdcVoltages');
            Datapixx('RegWrRd');
            if volts(params.datapixx.adcChannels(8)) > thresholdTTL
                break;
            end
        end
    else
        while true
            Datapixx('RegWrRd');
            volts = Datapixx('GetAdcVoltages');
            Datapixx('RegWrRd');
            if volts(params.datapixx.adcChannels(8)) < thresholdTTL
                break;
            end
        end
    end
    fprintf('Done.\n');
    
end % Function end

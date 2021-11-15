function [] = Wait4scannerTTL(params)
    
    if params.run.isExperiment
        fprintf('Waiting for scanner TTL... ');
        thresholdTTL = 2.5;
        
        while true
            Datapixx('RegWrRd');
            volts = Datapixx('GetAdcVoltages');
            Datapixx('RegWrRd');
            if volts(params.datapixx.adcChannels(8)) > thresholdTTL
                break;
            end
        end
        
        fprintf('Done.\n');
    end
    
end % Function end

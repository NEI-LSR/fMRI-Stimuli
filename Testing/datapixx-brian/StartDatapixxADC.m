function [params] = StartDatapixxADC(params)
    
    % Error handling
    if ~exist('Datapixx.m', 'file')
        error('Matlab does not have access to DataPixx functions!');
    else
        try
            Datapixx('Open');
            fprintf('Initializing DataPixx... ');
        catch
            error('No DataPixx box detected! Check if it is powered on and connected.');
        end
    end
    
    % General DataPixx settings
    Datapixx('Open');
    Datapixx('StopAllSchedules');
    Datapixx('DisableDinDebounce');
    Datapixx('SetDinLog');
    Datapixx('StartDinLog');
    Datapixx('SetDoutValues',0);
    Datapixx('RegWrRd');
    Datapixx('DisableDacAdcLoopback');
    Datapixx('EnableAdcFreeRunning');
    Datapixx('RegWrRd');
    fprintf('\bDone.\n');
    
    % Starting ADC schedule for recording analog signals
    Datapixx('SetAdcSchedule', 0, params.datapixx.analogInRate, 0, params.datapixx.adcChannels, params.datapixx.adcBufferAddress, 2000); %300000);
    Datapixx('StartAdcSchedule');
    Datapixx('RegWrRd');
    
end % Function end

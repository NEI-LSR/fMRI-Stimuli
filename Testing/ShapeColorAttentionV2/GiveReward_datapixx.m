function [params] = GiveReward_datapixx(params, juiceTime, curTime)
% Gives juice reward via DataPixx

    if juiceTime > 0 % Do we give juice? If so, we need to calculate when to keep the juice on until
        if params.juiceEndTime > curTime % Is the current juice end time longer than the current time?
            params.juiceEndTime = params.juiceEndTime + juiceTime; % Extend the juice end time
        else
            params.juiceEndTime = curTime + juiceTime; % The juice end time is now the juice time plus the current time
        end
    end

    if params.juiceOn == true % Is the juice currently on?
        if params.juiceEndTime <= curTime % If the current time has exceeded or equals the end juiceTime
            params.juiceOn = false;
        else
            params.juiceOn = true;
        end
    elseif params.juiceOn == false % is the juice actually off?
        if params.juiceEndTime > curTime % Is the juice end time in the future?
            Datapixx('SetDacVoltages',[params.datapixx.dacChannels(1) 0]); % Make sure the datapixx dac output is 0?
            Datapixx('RegWrRd');
        
            dacVoltages = [zeros(1,5), 5*one(1,int16(params.datapixx.analogOutRate * juiceTime)),zeros(1,5)]; % TTL waveform
            Datapixx('WriteDacBuffer',dacVoltages, params.datapixx.dacBufferAddress, params.datapixx.dacChannels(1)); % Write out the juicing time to the datapixx buffer
            Datapixx('RegWrRd');
        
            Datapixx('SetDacSchedule', 0, params.datapixx.analogOutRate,length(dacVotlages),params.datapixx.dacChannels(1), params.datapixx.dacBufferAddress, length(dacVoltages));
            Datapixx('StartDacSchedule');
            Datapixx('RegWrRd');              
            params.juiceOn = true;
        else
            params.juiceOn = false;
        end
    end






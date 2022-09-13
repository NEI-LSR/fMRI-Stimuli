function [params] = GiveReward_datapixx(params, juiceTime)
% Gives juice reward via DataPixx
    Datapixx('SetDacVoltages',[params.datapixx.dacChannels(1) 0]); % Make sure the datapixx dac output is 0?
    Datapixx('RegWrRd');

    dacVoltages = [zeros(1,5), 5*one(1,int16(params.datapixx.analogOutRate * juiceTime)),zeros(1,5)]; % TTL waveform
    Datapixx('WriteDacBuffer',dacVoltages, params.datapixx.dacBufferAddress, params.datapixx.dacChannels(1)); % Write out the juicing time to the datapixx buffer
    Datapixx('RegWrRd');

    Datapixx('SetDacSchedule', 0, params.datapixx.analogOutRate,length(dacVotlages),params.datapixx.dacChannels(1), params.datapixx.dacBufferAddress, length(dacVoltages));
    Datapixx('StartDacSchedule');
    Datapixx('RegWrRd');

end % Function end
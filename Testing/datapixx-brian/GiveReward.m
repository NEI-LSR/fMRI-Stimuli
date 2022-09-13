function [] = GiveReward(params)
    
    Datapixx('SetDacVoltages', [params.datapixx.dacChannels(1) 0]);
    Datapixx('RegWrRd');
    
    dacVoltages = [zeros(1,5), 5*ones(1,int16(params.datapixx.analogOutRate * params.run.reward.TTL)), zeros(1,5)]; % TTL waveform
    Datapixx('WriteDacBuffer', dacVoltages, params.datapixx.dacBufferAddress, params.datapixx.dacChannels(1));
    Datapixx('RegWrRd');
    
    Datapixx('SetDacSchedule', 0, params.datapixx.analogOutRate, length(dacVoltages), params.datapixx.dacChannels(1), params.datapixx.dacBufferAddress, length(dacVoltages));
    Datapixx('StartDacSchedule');
    Datapixx('RegWrRd');
    
end % Function end

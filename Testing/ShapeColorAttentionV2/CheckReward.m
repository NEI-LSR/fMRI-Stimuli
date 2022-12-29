function [params] = CheckReward(params)
% Should we give juice?
    if params.timeSinceLastJuice > params.rewardWaitActual % Has the time that has elapsed since the last juice exceeded the wait time?
        startIdx = round(params.frameIdx-((params.FPS*params.rewardWait)+1)); % Where are we going to start calculating reward from?
        if startIdx < 1
            startIdx = 1; % Start index is always at least 1
        elseif startIdx >= params.frameIdx % If the start index is somehow ahead of the frame index
            startIdx = params.frameIdx - 1; % Start index becomes 1 less than frame index
        end

        if sum(params.fixation(startIdx:params.frameIdx),"all","omitnan") > params.rewardPerf*params.FPS*params.rewardWaitActual
            params = interface("GiveReward",params,params.rewardDur,toc);
            params.timeSinceLastJuice = 0; % Set time since last juice to 0
            params.timeAtLastJuice = toc; % Set time at last juice to the current time
            params.rewardWaitActual = params.rewardWait(2*rand-1)*params.rewardWaitJitter; % Jitter the response if desired
        else
            params.timeSinceLastJuice = toc - params.timeAtLastJuice; % How long has it been since the last juice?
        end
    else
        params.timeSinceLastJuice = toc - params.timeAtLastJuice; % How long has it been since the last juice?
    end
    % Check if we need to end juice
    params = interface("StopReward",params,toc); 
end

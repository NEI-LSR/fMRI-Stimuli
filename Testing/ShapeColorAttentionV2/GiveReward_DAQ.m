function [params] = GiveReward_DAQ(params,juiceTime,curTime)
% Function for delivering juice/reward with a NIDAQ card
% Since the NIDAQ card doesn't have a buffer, we need to get creative about
% how we interface with the card.

    if juiceTime > 0 % Do we give juice? If so, we need to calculate when to keep the juice on until
        if params.juiceEndTime > curTime % Is the current juice end time longer than the current time?
            params.juiceEndTime = params.juiceEndTime + juiceTime; % Extend the juice end time
        else
            params.juiceEndTime = curTime + juiceTime; % The juice end time is now the juice time plus the current time
        end
    end

    if params.juiceOn == true % Is the juice currently on?
        if params.juiceEndTime <= curTime % If the current time has exceeded or equals the end juiceTime
            DAQ('SetBit',[0 0 0 0]); % Turn off the juice
            params.juiceOn = false;
        else
            params.juiceOn = true;
        end
    elseif params.juiceOn == false % is the juice actually off?
        if params.juiceEndTime > curTime % Is the juice end time in the future?
            DAQ('SetBit',[1 1 1 1]); % Turn on juice
            params.juiceOn = true;
        else
            params.juiceOn = false;
        end
    end
end





        
function [params] = CheckReward(params)
    
    if params.run.fixation.isDotOn && params.run.fixation.log(end) > params.run.reward.interval
        GiveReward(params);
        params.run.reward.count = params.run.reward.count + 1;
        
        if params.run.reward.frequency == params.run.reward.startFrequency
            params.run.reward.frequency = params.run.reward.minFrequency;
        else
            params.run.reward.frequency = min(params.run.reward.frequency+params.run.reward.frequencyIncrement, params.run.reward.maxFrequency);
        end
        
        params.run.reward.interval  = params.run.reward.interval + (1/params.run.reward.frequency);
    end
    
end % Function end

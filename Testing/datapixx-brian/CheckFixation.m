function [params] = CheckFixation(params)
    
    %[params.run.fixation.coordinates(end+1,1), params.run.fixation.coordinates(end+1,2)] = GetMouse(window);
    params.run.fixation.coordinates(end+1,:) = GetFixationCoordinates(params);
    params.run.fixation.isInWindow = IsInCircle(params.run.fixation.coordinates(end,1), params.run.fixation.coordinates(end,2), params.run.fixation.windowRect);
    
    if params.run.fixation.isBroken && params.run.fixation.isInWindow
        params.run.fixation.isBroken = 0;
    elseif ~params.run.fixation.isBroken && ~params.run.fixation.isInWindow
        params.run.fixation.isBroken      = 1;
        params.run.fixation.breakStartIdx = params.run.frameIdx;
    end
    
    if params.run.fixation.isBroken
        if params.run.fixation.log(end) > 0 && params.run.frameIdx-params.run.fixation.breakStartIdx > params.run.fixation.breakTolerance*params.display.fps
            params.run.fixation.log(end+1,:) = 0;
            params.run.reward.frequency    = params.run.reward.startFrequency;
            params.run.reward.interval     = 1 / params.run.reward.frequency;
        end
    else
        params.run.fixation.log(end) = params.run.fixation.log(end) + params.display.ifi;
    end
    
end % Function end

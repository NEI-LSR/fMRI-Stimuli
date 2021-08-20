function [fixLog, fixBreakStartIdx, isFixBroken] = CalculateFixationDurationsOffline(params)
    
    fixLog           = 0;
    isFixBroken      = 1;
    fixBreakStartIdx = 1;
    if params.run.fixation.breakTolerance > 0.7
        fixBreakTolerance = 0.7;
    else
        fixBreakTolerance = params.run.fixation.breakTolerance;
    end
    
    for frameIdx = 1:length(params.run.log)
        if isFixBroken && params.run.log(frameIdx,end)==1
            isFixBroken = 0;
        elseif ~isFixBroken && params.run.log(frameIdx,end)==0
            isFixBroken = 1;
            fixBreakStartIdx = frameIdx;
        end
        
        if isFixBroken
            if fixLog(end)>0 && frameIdx-fixBreakStartIdx>fixBreakTolerance*params.display.fps
                fixLog(end+1) = 0;
            end
        else
            fixLog(end) = fixLog(end) + params.display.ifi;
        end
    end
    if fixLog(end) == 0
        fixLog(end) = [];
    end
    fixLog = fixLog';
    
end % Function end

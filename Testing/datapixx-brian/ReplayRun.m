function [] = ReplayRun(params, window, fixGridTex, movieTex)
    
    fixationBreakStartIdx = 1;
    fixationIsBroken      = 1;
    fixationLog           = 0;
    Priority(9);
    startTime = tic;
    [~, time2flip] = Screen('Flip', window);
    
    fprintf('\nReplaying... ');
    for frameIdx = 1:params.run.frameIdx
        time2flip = time2flip + params.display.ifi*0.99;
        Screen('FillRect', window, params.display.grayBackground, params.display.expWindowRect);
        
        % Drawing fixation grid on framebuffer
        Screen('DrawTexture', window, fixGridTex, [], params.display.expRect+[params.run.fixation.dotOffset,params.run.fixation.dotOffset]);
        
        % Drawing stimulus on framebuffer
        if ~isnan(movieTex(frameIdx))
            Screen('DrawTexture', window, movieTex(frameIdx), [], params.display.expRect, [], [], params.run.stimContrast);
        end
        
        % Drawing fixation dot on framebuffer
        if params.run.fixation.isDotOn
            Screen('DrawDots', window, [0 0], params.run.fixation.dotSize, params.run.fixation.dotColor, params.display.expRectCenter+params.run.fixation.dotOffset, 1);
        end
        
        % Checking fixation
        if fixationIsBroken && params.run.log(frameIdx,end)
            fixationIsBroken = 0;
        elseif ~fixationIsBroken && ~params.run.log(frameIdx,end)
            fixationIsBroken      = 1;
            fixationBreakStartIdx = frameIdx;
        end
        if fixationIsBroken
            if fixationLog(end) > 0 && frameIdx-fixationBreakStartIdx > params.run.log(frameIdx,5)*params.display.fps
                fixationLog(end+1) = 0;
            end
        else
            fixationLog(end) = fixationLog(end) + params.display.ifi*0.99;
        end
        
        % Drawing experimenter overlay on framebuffer (run statistics)
        if isnan(movieTex(frameIdx))
            [text2draw, margin, textSize] = FormatText2draw;
            DrawFormattedText(window, text2draw, margin, params.display.expWindowRect(4)-textSize-margin, 1, [], [], [], [], [], params.display.expWindowRect);
        end
        
        % Drawing experimenter overlay on framebuffer (fixation window circle)
        Screen('FrameOval', window, params.run.fixation.windowColor(params.run.log(frameIdx,end)+1,:), OffsetRect(params.run.fixation.windowRect,-params.display.expWindowRect(3),0), 3);
        
        % Drawing experimenter overlay on framebuffer (monkey's gaze position)
        if IsInRect(params.run.fixation.coordinates(frameIdx,1), params.run.fixation.coordinates(frameIdx,2), params.display.monkWindowRect)
            gazeRect = round([params.run.fixation.coordinates(frameIdx,1) params.run.fixation.coordinates(frameIdx,2) params.run.fixation.coordinates(frameIdx,1) params.run.fixation.coordinates(frameIdx,2)]) + [-5 -5 5 5];
            Screen('FillOval', window, params.run.fixation.windowColor(params.run.log(frameIdx,end)+1,:), OffsetRect(gazeRect,-params.display.expWindowRect(3),0));
        end
        
        Screen('Flip', window, time2flip);
        
        if KbCheck
            break;
        end
    end
    
    Screen('FillRect', window, params.display.blackBackground, params.display.expWindowRect);
    Screen('Flip', window);
    Priority(0);
    fprintf('End.\n\n');
    
    
    %% Formating run parameters to be drawn on experimenter's screen
    function [text2draw, margin, textSize] = FormatText2draw
        
        textFormat  = ['Elapsed time         = %02d:%02.0f s\n', ...
                       'Reward TTL           = %.3f s\n', ...
                       'Reward frequency     = %.1f Hz\n', ...
                       'Reward count         = %d\n', ...
                       'Performance          = %.1f %%\n\n', ...
                       'Fix. duration        = %.1f s\n', ...
                       'Fix. window size     = %.1f deg\n', ...
                       'Fix. break tolerance = %.1f s \n\n', ...
                       'X-axis offset        = %.2f V\n', ...
                       'Y-axis offset        = %.2f V\n', ...
                       'X-axis gain          = %d deg/V\n', ...
                       'Y-axis gain          = %d deg/V\n'];
               
        textContent = [floor(toc(startTime)/60), rem(toc(startTime),60), ...
                       params.run.reward.TTL, ...
                       params.run.log(frameIdx,3), ...
                       params.run.log(frameIdx,2), ...
                       (sum(fixationLog)/toc(startTime)) * 100, ...
                       fixationLog(end), ...
                       params.run.log(frameIdx,4), ...
                       params.run.log(frameIdx,5), ...
                       params.datapixx.calibrationOffset(1), ...
                       params.datapixx.calibrationOffset(2), ...
                       params.datapixx.calibrationGain(1), ...
                       params.datapixx.calibrationGain(2)];
               
        text2draw   = sprintf(textFormat, textContent);
        margin      = 20 * params.display.scaleHD;
        textSize    = (length(textContent)*12) * params.display.scaleHD;
    
    end % Function end
    
end % Function end

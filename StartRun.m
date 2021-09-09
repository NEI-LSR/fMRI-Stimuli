function [params] = StartRun(params, window, fixGridTex, movieTex)
    
    figureHandle = figure('Visible', 'off');
    imshow([params.directory.stimuli '/keyboard_shortcuts.png'], 'Parent', gca, 'Border', 'tight');
    set(figureHandle, 'Position', [100 100 1132 310], 'Name', 'Keyboard shortcuts', 'NumberTitle', 'off', 'Menu', 'none', 'Toolbar', 'none', 'Visible', 'on');
    drawnow;
    
    params.directory.session          = [params.directory.subject '/' datestr(clock,'yyyymmdd')];
    params.run.fixation.coordinates   = [];
    params.run.fixation.log           = 0;
    params.run.fixation.isBroken      = 1;
    params.run.fixation.breakStartIdx = 1;
    params.run.reward.count           = 0;
    params.run.reward.interval        = 1 / params.run.reward.startFrequency;
    params.run.isAborted              = 0;
    
    Priority(9);
    %Wait4scannerTTL(params);
    params.run.startTime = clock;
    startTime = tic;
    Screen('FillRect', window, params.display.grayBackground);
    [~, time2flip] = Screen('Flip', window);
    
    % Beginning run
    for frameIdx = 1:params.run.exactDuration * params.display.fps
        params.run.frameIdx = frameIdx;
        time2flip = time2flip + params.display.ifi*0.99;
        
        % Drawing fixation grid on framebuffer
        Screen('DrawTexture', window, fixGridTex, [], params.display.expRect+[params.run.fixation.dotOffset,params.run.fixation.dotOffset]);
        if params.run.fixation.isGridOn
            Screen('DrawTexture', window, fixGridTex, [], params.display.monkRect+[params.run.fixation.dotOffset,params.run.fixation.dotOffset]);
        end
        
        % Drawing stimulus on framebuffer
        if ~isnan(movieTex(frameIdx))
            if params.display.jitter == true && rem((frameIdx-1),params.display.fps*params.run.stimlength) == 0
                jitterV = (rand()*2-1);
                jitterH = (rand()*2-1);
                lBorderExp = (jitterH*params.display.jitterPix(1)+params.display.expRectStimBase(1));
                tBorderExp = (jitterV*params.display.jitterPix(2)+params.display.expRectStimBase(2));
                rBorderExp = (jitterH*params.display.jitterPix(1)+params.display.expRectStimBase(3));
                bBorderExp = (jitterV*params.display.jitterPix(2)+params.display.expRectStimBase(4));
                params.display.expRectStim = [lBorderExp tBorderExp rBorderExp bBorderExp];
                lBorderMonk = (jitterH*params.display.jitterPix(1)+params.display.monkRectStimBase(1));
                tBorderMonk = (jitterV*params.display.jitterPix(2)+params.display.monkRectStimBase(2));
                rBorderMonk = (jitterH*params.display.jitterPix(1)+params.display.monkRectStimBase(3));
                bBorderMonk = (jitterV*params.display.jitterPix(2)+params.display.monkRectStimBase(4));
                params.display.monkRectStim = [lBorderMonk tBorderMonk rBorderMonk bBorderMonk];
            end
            Screen('DrawTexture', window, movieTex(frameIdx), [], params.display.expRectStim, [], [], params.run.stimContrast);
            Screen('DrawTexture', window, movieTex(frameIdx), [], params.display.monkRectStim, [], [], params.run.stimContrast);
        end
        
        % Drawing fixation dot on framebuffer
        if params.run.fixation.isDotOn
            Screen('DrawDots', window, [0 0], params.run.fixation.dotSize, params.run.fixation.dotColor, params.display.expRectCenter+params.run.fixation.dotOffset, 1);
            Screen('DrawDots', window, [0 0], params.run.fixation.dotSize, params.run.fixation.dotColor, params.display.monkRectCenter+params.run.fixation.dotOffset, 1);
        end
        
        params = CheckFixation(params);
        
        % Drawing experimenter overlay on framebuffer (statistics)
        if ~isnan(movieTex(frameIdx))
            [text2draw, margin, textSize] = FormatText2draw;
            DrawFormattedText(window, text2draw, margin, params.display.expWindowRect(4)-textSize-margin, 1, [], [], [], [], [], params.display.expWindowRect);
        end
        
        % Drawing experimenter overlay on framebuffer (fixation window circle)
        Screen('FrameOval', window, params.run.fixation.windowColor(params.run.fixation.isInWindow+1,:), OffsetRect(params.run.fixation.windowRect,-params.display.expWindowRect(3),0), 3);
        
        % Drawing experimenter overlay on framebuffer (monkey's gaze position)
        if IsInRect(params.run.fixation.coordinates(end,1), params.run.fixation.coordinates(end,2), params.display.monkWindowRect)
            gazeRect = round([params.run.fixation.coordinates(end,1) params.run.fixation.coordinates(end,2) params.run.fixation.coordinates(end,1) params.run.fixation.coordinates(end,2)]) + [-5 -5 5 5];
            Screen('FillOval', window, params.run.fixation.windowColor(params.run.fixation.isInWindow+1,:), OffsetRect(gazeRect,-params.display.expWindowRect(3),0));
        end
        
        [~, params.run.log(frameIdx, 1)] = Screen('Flip', window, time2flip);
        
        params = CheckReward(params);
        
        % Logging data
        params.run.log(frameIdx,2:end) = [params.run.reward.count params.run.reward.frequency params.run.fixation.windowSize params.run.fixation.breakTolerance params.run.fixation.isGridOn params.run.fixation.isDotOn params.run.fixation.isInWindow];
        
        CheckKeyboard;
        if params.run.isAborted
            text2draw = FormatText2draw;
            break;
        end
    end
    
    % Ending run
    params.run.duration = toc(startTime);
    params.run.endTime  = clock;
    Screen('FillRect', window, params.display.blackBackground);
    Screen('Flip', window);
    Priority(0);
    
    fprintf('Ending run.\n');
    disp(text2draw);
    close(figureHandle);
    SaveRun(params);
    
    
    %% Formating run parameters to be drawn on experimenter's screen
    function [text2draw, margin, textSize] = FormatText2draw
        
        textFormat  = ['Elapsed time         = %02d:%02.0f s\n', ...
                       'Reward TTL           = %.3f s\n', ...
                       'Reward frequency     = %.2f Hz\n', ...
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
                       params.run.reward.frequency, ...
                       params.run.reward.count, ...
                       (sum(params.run.fixation.log)/toc(startTime)) * 100, ...
                       params.run.fixation.log(end), ...
                       params.run.fixation.windowSize, ...
                       params.run.fixation.breakTolerance, ...
                       params.datapixx.calibrationOffset(1), ...
                       params.datapixx.calibrationOffset(2), ...
                       params.datapixx.calibrationGain(1), ...
                       params.datapixx.calibrationGain(2)];
               
        text2draw   = sprintf(textFormat, textContent);
        margin      = 20 * params.display.scaleHD;
        textSize    = (length(textContent)*12) * params.display.scaleHD;
    
    end % Function end
    
    
    %% Checking key presses
    function CheckKeyboard
        
        [keyIsDown, secs, keyCode] = KbCheck([], params.key.list);
        
        if keyIsDown && secs > params.key.lastPress + params.key.minPressDuration
            params.key.lastPress = secs;
            
            if keyCode(params.key.abortRun)
                params.run.isAborted = 1;
                
            elseif keyCode(params.key.increaseFixWindowSize)
                if params.run.fixation.windowSize < 50
                    params.run.fixation.windowSize = params.run.fixation.windowSize + 1;
                    params.run.fixation.windowRect = CenterRect([0, 0, params.run.fixation.windowSize.*params.display.pixPerDeg], params.display.monkWindowRect+[params.run.fixation.dotOffset params.run.fixation.dotOffset]);
                end
                
            elseif keyCode(params.key.decreaseFixWindowSize)
                if params.run.fixation.windowSize > 1
                    params.run.fixation.windowSize = params.run.fixation.windowSize - 1;
                    params.run.fixation.windowRect = CenterRect([0, 0, params.run.fixation.windowSize.*params.display.pixPerDeg], params.display.monkWindowRect+[params.run.fixation.dotOffset params.run.fixation.dotOffset]);
                end
                
            elseif keyCode(params.key.toggleFixDot)
                params.run.fixation.isDotOn = ~params.run.fixation.isDotOn;
                
            elseif keyCode(params.key.centerFix)
                [~, volts] = GetAveragedFixationCoordinates(params);
                params.datapixx.calibrationOffset = -volts;
                
            elseif keyCode(params.key.manualReward)
                GiveReward(params);
                params.run.reward.count = params.run.reward.count + 1;
            
            elseif keyCode(params.key.toggleFixGrid)
                params.run.fixation.isGridOn = ~params.run.fixation.isGridOn;
                
            elseif keyCode(params.key.increaseXgain)
                params.datapixx.calibrationGain(1) = params.datapixx.calibrationGain(1) + 1;
                
            elseif keyCode(params.key.decreaseXgain)
                if params.datapixx.calibrationGain(1) > 1
                    params.datapixx.calibrationGain(1) = params.datapixx.calibrationGain(1) - 1;
                end
                
            elseif keyCode(params.key.increaseYgain)
                params.datapixx.calibrationGain(2) = params.datapixx.calibrationGain(2) + 1;
                
            elseif keyCode(params.key.decreaseYgain)
                if params.datapixx.calibrationGain(2) > 1
                    params.datapixx.calibrationGain(2) = params.datapixx.calibrationGain(2) - 1;
                end
            
            elseif keyCode(params.key.dot2right)
                if params.run.fixation.dotOffset(1) == -params.display.resolution(2)/4
                    params.run.fixation.dotOffset = [0 0];
                elseif params.run.fixation.dotOffset(1) == 0
                    params.run.fixation.dotOffset = [params.display.resolution(2)/4 0];
                end
                params.run.fixation.windowRect = CenterRect([0, 0, params.run.fixation.windowSize.*params.display.pixPerDeg], params.display.monkWindowRect+[params.run.fixation.dotOffset params.run.fixation.dotOffset]);
                
            elseif keyCode(params.key.dot2left)
                if params.run.fixation.dotOffset(1) == params.display.resolution(2)/4
                    params.run.fixation.dotOffset = [0 0];
                elseif params.run.fixation.dotOffset(1) == 0
                    params.run.fixation.dotOffset = [-params.display.resolution(2)/4 0];
                end
                params.run.fixation.windowRect = CenterRect([0, 0, params.run.fixation.windowSize.*params.display.pixPerDeg], params.display.monkWindowRect+[params.run.fixation.dotOffset params.run.fixation.dotOffset]);
                
            elseif keyCode(params.key.dot2up)
                if params.run.fixation.dotOffset(2) == params.display.resolution(2)/4
                    params.run.fixation.dotOffset = [0 0];
                elseif params.run.fixation.dotOffset(2) == 0
                    params.run.fixation.dotOffset = [0 -params.display.resolution(2)/4];
                end
                params.run.fixation.windowRect = CenterRect([0, 0, params.run.fixation.windowSize.*params.display.pixPerDeg], params.display.monkWindowRect+[params.run.fixation.dotOffset params.run.fixation.dotOffset]);
                
            elseif keyCode(params.key.dot2down)
                if params.run.fixation.dotOffset(2) == -params.display.resolution(2)/4
                    params.run.fixation.dotOffset = [0 0];
                elseif params.run.fixation.dotOffset(2) == 0
                    params.run.fixation.dotOffset = [0 params.display.resolution(2)/4];
                end
                params.run.fixation.windowRect = CenterRect([0, 0, params.run.fixation.windowSize.*params.display.pixPerDeg], params.display.monkWindowRect+[params.run.fixation.dotOffset params.run.fixation.dotOffset]);
            end
        end
        
    end % function end
    
end % function end

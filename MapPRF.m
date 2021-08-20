function [params] = MapPRF()
    
    params   = LoadParameters;
    edit LoadParameters.m
    
    params   = InitializeKeyboard(params);
    
    params   = StartDatapixxADC(params);
    
    [window] = OpenPTBwindow(params);
    
    [fixGridTex, retinoTex, motionTex] = MakePTBtextures(params, window);

    while true
        selection = ShowDialogBox('list');
        
        if isempty(selection)
            break;
            
        elseif selection == 1
            GiveReward(params);
            
        elseif selection == 2
            ShowDialogBox('question');
            params.run.type = 'retino';
            fprintf('\nRunning retinotopy pRF mapping...\n');
            params = StartRun(params, window, fixGridTex, retinoTex);
            
        elseif selection == 3
            ShowDialogBox('question');
            params.run.type = 'motion';
            fprintf('\nRunning motion pRF mapping...\n');
            params = StartRun(params, window, fixGridTex, motionTex);
            
        elseif selection == 4
            params.run.isExperiment = 0;
            params.run.type = 'fixation';
            fprintf('\nRunning fixation training...\n');
            params = StartRun(params, window, fixGridTex, NaN(length(retinoTex),1));
            
        elseif selection == 5
            runFilename  = ShowDialogBox('file');
            if ~isempty(runFilename)
                paramsReplay = load(runFilename, 'params');
                paramsReplay = paramsReplay.params;
                switch paramsReplay.run.type
                    case 'retino'
                        ReplayRun(paramsReplay, window, fixGridTex, retinoTex);
                    case 'motion'
                        ReplayRun(paramsReplay, window, fixGridTex, motionTex);
                    case 'fixation'
                        ReplayRun(paramsReplay, window, fixGridTex, NaN(length(retinoTex),1));
                end
            end
            
        elseif selection == 6
            [~, subjectID] = fileparts(params.directory.subject);
            [~, sessionDate] = ShowDialogBox('file');
            if ~isempty(sessionDate)
                PlotPerformance(subjectID, sessionDate);
            end
            
        elseif selection == 7
            ShowDialogBox('input');
        end
    end
    
    Datapixx('Close');
    fprintf('\n');
    sca;
    
    %% Creating various dialog boxes
    function [answer, answer2] = ShowDialogBox(type)
        
        answer  = [];
        answer2 = [];
        if ~ispc && ~ismac
            set(0, 'DefaultUICOntrolFontSize', 24)
        end
        switch type
            case 'list'
                answer = listdlg('ListSize', [200 150], 'SelectionMode', 'single', 'OkString', 'Select', 'CancelString', 'Quit', ...
                                 'Name', 'Main menu', ...
                                 'ListString', {'Deliver manual reward', ...
                                                'Run retinotopy pRF mapping', ...
                                                'Run motion pRF mapping', ...
                                                'Run fixation training', ...
                                                'Replay a previous run', ...
                                                'Plot performance', ...
                                                'Modify run parameters'});
            
            case 'question'
                answer = questdlg('Is this a training or an experiment (i.e. collecting MRI data)?', '', 'Experiment', 'Training', 'Experiment');
                if strcmp(answer, 'Experiment')
                    params.run.isExperiment = 1;
                else
                    params.run.isExperiment = 0;
                end
            
            case 'file'
                [filename, pathname] = uigetfile('*.mat', 'Select a run file');
                if ~isequal(filename,0) && ~isequal(pathname,0)
                    answer  = fullfile(pathname, filename);
                    answer2 = split(fileparts(pathname), '/');
                    answer2 = answer2{end};
                end
            
            case 'input'
                [~, subjectID] = fileparts(params.directory.subject);
                inputs = inputdlg({'Subject ID', ...
                                   'Viewing distance (cm)', ...
                                   'Stimulus contrast (0 to 1)', ...
                                   'Eye to track (left OR right)', ...
                                   'Fixation break tolerance (s)', ...
                                   'Reward TTL (s)', ...
                                   'Start reward frequency (Hz)', ...
                                   'Min reward frequency (Hz)', ...
                                   'Max reward frequency (Hz)', ...
                                   'Reward frequency increment (Hz)'}, 'Parameters', 1, ...
                                  {subjectID, ...
                                   num2str(params.display.viewingDistance), ...
                                   num2str(params.run.stimContrast), ...
                                   params.run.fixation.eye2track, ...
                                   num2str(params.run.fixation.breakTolerance), ...
                                   num2str(params.run.reward.TTL), ...
                                   num2str(params.run.reward.startFrequency), ...
                                   num2str(params.run.reward.minFrequency), ...
                                   num2str(params.run.reward.maxFrequency), ...
                                   num2str(params.run.reward.frequencyIncrement)});
                if ~isempty(inputs)
                    params.directory.subject             = [params.directory.save '/' inputs{1}];
                    params.display.viewingDistance       = str2double(inputs{2});
                    params.display.pixPerDeg             = 2 * (params.display.pixPerCm * params.display.viewingDistance * tand(0.5));
                    params.run.stimContrast              = str2double(inputs{3});
                    params.run.fixation.eye2track        = inputs{4};
                    params.run.fixation.breakTolerance   = str2double(inputs{5});
                    params.run.reward.TTL                = str2double(inputs{6});
                    params.run.reward.startFrequency     = str2double(inputs{7});
                    params.run.reward.minFrequency       = str2double(inputs{8});
                    params.run.reward.maxFrequency       = str2double(inputs{9});
                    params.run.reward.frequencyIncrement = str2double(inputs{10});
                end
        end
        
    end % Function end

end % Function end

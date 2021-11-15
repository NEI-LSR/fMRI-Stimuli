function [params] = MeridianMapper()

    
    params   = LoadParameters_MM;
    edit LoadParameters_MM.m
    
    params   = InitializeKeyboard(params);
    
    if params.system.debug == false % If debugging, don't initialize Datapixx
        params   = StartDatapixxADC(params);
    end
    
    try
        if params.system.screens == 1
            [window] = OpenPTBwindow(params);
        elseif params.system.screens == 2
            [window,window2] = OpenPTBwindow(params);
        end
    catch problems
        disp(problems)
    end
    
    [fixGridTex, retinoTex] = MakePTBtextures_meridian_mapper(params, window);
    
    
    if params.system.screens == 2
        Screen('FillRect', window, [1,0,0]);
        Screen('Flip', window);
        Screen('FillRect', window2, [1,0,0]);
        Screen('Flip', window2);
    end
    
    while true
        
        if params.system.debug == false
            selection = ShowDialogBox('list');


            if isempty(selection)
                break;

            elseif selection == 1
                if params.system.debug == false
                    GiveReward(params);
                elseif params.system.debug == true
                    disp('Cannot give reward in debug mode')
                end
            elseif selection == 2
                
                ShowDialogBox('question');
                params.run.type = 'Meridian Mapper';
                fprintf('\nRunning Meridian Mapper...\n');
                if params.system.screens == 1
                    params = StartRun(params, window, fixGridTex, retinoTex);
                elseif params.system.screens == 2
                    params = StartRun(params, window, fixGridTex, retinoTex, window2);
                end
                
            elseif selection == 3
                params.run.isExperiment = 0;
                params.run.type = 'fixation';
                fprintf('\nRunning fixation training...\n');
                if params.system.screens == 1
                    params = StartRun(params, window, fixGridTex, NaN(length(retinoTex),1));
                elseif params.system.screens == 2
                    params = StartRun(params, window, fixGridTex, NaN(length(retinoTex),1), window2);
                end
            

            elseif selection == 4 % Need to code this to be functional
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

            elseif selection == 5
                [~, subjectID] = fileparts(params.directory.subject);
                [~, sessionDate] = ShowDialogBox('file');
                if ~isempty(sessionDate)
                    PlotPerformance(subjectID, sessionDate);
                end

            elseif selection == 6
                ShowDialogBox('input');
            end
            
        elseif params.system.debug == true
            params.run.isExperiment = 0;
            while true
                [~,~,keys] = KbCheck([]);
                if keys(19) | keys(40)
                    params.run.type = 'Meridian Mapper';
                    fprintf('\nRunning Meridian Mapper...\n');
                    if params.system.screens == 1
                        params = StartRun(params, window, fixGridTex, retinoTex);
                    elseif params.system.screens == 2
                        params = StartRun(params, window, fixGridTex, retinoTex, window2);
                    end
                elseif keys(9)
                    params.run.isExperiment = 0;
                    params.run.type = 'fixation';
                    fprintf('\nRunning fixation training...\n');
                    if params.system.screens == 1
                        params = StartRun(params, window, fixGridTex, NaN(length(retinoTex),1));
                    elseif params.system.screens == 2
                        params = StartRun(params, window, fixGridTex, NaN(length(retinoTex),1), window2);
                end
                elseif keys(20)
                    sca;
                end
            end
        end
             
            
    end
    
    if params.system.debug == false
        Datapixx('Close');
    end
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
                                                'Run Meridian Mapper', ...
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

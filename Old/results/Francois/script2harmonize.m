allSessions = dir([pwd '/' '20*']);

for idx = 1:length(allSessions)
    runs = dir([allSessions(idx).folder '/' allSessions(idx).name '/' 'run*.mat']);
    for idx2 = 1:length(runs)
        filename = [runs(idx2).folder '/' 'run' num2str(idx2) '_' 'calibration' '.mat'];
        if ~exist(filename, 'file')
            filename = [runs(idx2).folder '/' 'run' num2str(idx2) '_' 'experiment' '.mat'];
        end
        load(filename, 'params');
        
        if isfield(params,'saveDir') 
            if strcmp(params.saveDir,'/projects/ocakb/matlab/pRF_mapping_v6/results/')
                run('script2harmonize_v6.m')
                fprintf('%s, v6\n', filename);
            elseif strcmp(params.saveDir,'/projects/ocakb/matlab/pRF_mapping_v7/results/')
                run('script2harmonize_v8.m')
                fprintf('%s, v8\n', filename);
            elseif strcmp(params.saveDir,'/projects/ocakb/matlab/pRF_mapping_v8/results/')
                if isfield(params.calibration,'endTime')
                    dateString = split(filename, filesep);
                    dateString = dateString{end-1};
                    run('script2harmonize_v8_9.m')
                    fprintf('%s, v8_9\n', filename);
                else
                    run('script2harmonize_v8.m')
                    fprintf('%s, v8\n', filename);
                end
            elseif strcmp(params.saveDir,'/projects/ocakb/matlab/pRF_mapping_v10/results/')
                if params.calibration.log(1,4) > 1
                    run('script2harmonize_v10_11.m')
                    fprintf('%s, v10_11\n', filename);
                else
                    run('script2harmonize_v10.m')
                    fprintf('%s, v10\n', filename);
                end
            elseif strcmp(params.saveDir,'/projects/ocakb/matlab/pRF_mapping_v11/results/')
                run('script2harmonize_v10_11.m')
                fprintf('%s, v10_11\n', filename);
            end
        else
            run('script2harmonize_v12_13.m')
            fprintf('%s, v12_13\n', filename);
        end
        save(filename, 'params');
    end
end

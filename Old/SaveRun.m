function [] = SaveRun(params)
    
    if params.run.duration < 60
        return;
    else
        if ~exist(params.directory.subject, 'dir')
            mkdir(params.directory.subject);
        end
        
        if params.run.isExperiment
            runType = [params.run.type 'Experiment'];
        else
            runType = [params.run.type 'Training'];
        end
        
        dateString = datestr(params.run.startTime, 'yyyymmdd');
        if ~exist([params.directory.subject '/' dateString], 'dir')
            mkdir([params.directory.subject '/' dateString]);
        end
        
        params        = rmfield(params, 'key');
        existingFiles = dir([params.directory.subject '/' dateString '/' 'run*.mat']);
        filename      = [params.directory.subject '/' dateString '/' 'run' num2str(length(existingFiles)+1) '_' runType '.mat'];
        save(filename, 'params');
    end
    
end % function end

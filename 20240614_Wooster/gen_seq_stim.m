function [params] = gen_db_sequences(params,numstim,totalstim,numorder,numsplits,numoverlap, used_indexes)
%% Generate New Debruijn sequences and stimuli order

    a = debruijn_generator(numstim*2,numorder);
    b = reshape(a,[],numsplits)';
    % c = b(:,1:numoverlap);
    %c1 = [c(2:end); c(1)];
    d = b(:,end+1-numoverlap:end);
    d1 = [d(end); d(1:end-1)];
    %e = [d1 b c1]; % Reordering, gives final debruijn sequencing
    e = [d1 b]; % Final debruijn orders with level of overlap
    
    s = randsample(totalstim,numstim); % Sample stimuli
    s = used_indexes(s);
    
    dt = strrep(strrep(datestr(datetime),' ','_'),':','_');

    csvwrite(fullfile(params.dataDir,[dt,'_stimindices.csv']),s); % Write out stim indices
    csvwrite(fullfile(params.dataDir,[dt,'_stimorders.csv']),e); % Write out stim orders
   
    params.stimIndex = s;
    params.stimOrders = e;

   

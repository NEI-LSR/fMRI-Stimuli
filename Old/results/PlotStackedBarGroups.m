function [figureHandle, barHandle] = PlotStackedBarGroups(stackData, groupLabels)
    
    % stackData(i,j,k) => 3d matrix (stackData(group, stack, stackElement)) 
    % groupLabels      => cell array
    
    numGroups         = size(stackData, 1);
    numStacksPerGroup = size(stackData, 2);
    groupBins         = 1:numGroups;
    maxGroupWidth     = 0.65;                                                   % 1 = all bars in groups touching
    stackWidth        = maxGroupWidth / numStacksPerGroup;
    figureHandle      = figure;
    hold on;
    
    for idx = 1:numStacksPerGroup
        YData                 = squeeze(stackData(:,idx,:));
        relativeStackPosition = idx - ((numStacksPerGroup+1)/2);                % Centering the bars
        groupPosition         = relativeStackPosition * stackWidth + groupBins; % Offsetting the group positions
        barHandle(idx,:)      = bar(YData, 'stacked');
        set(barHandle(idx,:), 'BarWidth', stackWidth);
        set(barHandle(idx,:), 'XData', groupPosition);
    end
    
    hold off;
    set(gca,'XTickMode', 'manual');
    set(gca,'XTick', groupBins);
    set(gca,'XTickLabelMode', 'manual');
    set(gca,'XTickLabel', groupLabels);
    
end % Function end

function [DM] = ProduceSCDM(mainpath, varargin)
    % Stuart Duffield 06/06/2022
    % Produces the design matrices for the shape color attention
    % experiments
    % Inputs: the path to the data of a shape color session, a list of runs
    % that you want to analyze, and a list of IMA numbers for those runs
    
    % Some good hygeine checking
    if length(varargin) >= 2
        goodRuns = varargin{1};
        if ~ismatrix(goodRuns)
            error("The second argument must be a list of good runs!")
        else
            if size(goodRuns,1) > 1
                error("The second argument must be a list of size 1xN of the good runs")
            end
        end
        IMAs = varargin{2};

        if length(IMAs) ~= length(goodRuns)
            error('IMA list length must match length of runs you want to analyze')
        end

    end
    
    if ispc
        dataPaths_init = dir([mainpath '\\*.mat']); % Get the initial data file paths. These may be changed depending on if the run was completed
    else
        dataPaths_init = dir([mainpath '//*.mat']); % Get the initial data file paths. These may be changed depending on if the run was completed
    end
    dataPaths = {};
    LumSettings = [];
    for i=1:length(dataPaths_init)
        if ispc
            path = [dataPaths_init(i).folder '\' dataPaths_init(i).name];
        else
            path = [dataPaths_init(i).folder '/' dataPaths_init(i).name];
        end
        load(path,'frameIdx','exactDur','fps','LumSetting','TR');
        [~,pathfile,~] = fileparts(path);
        parts = split(pathfile,'_');
        runnum = parts{2};

        if ismember(str2num(runnum),goodRuns)
            if frameIdx >= exactDur*fps % did it finish?
                dataPaths_index = length(dataPaths)+1;
                dataPaths{dataPaths_index} = path; % Add it if it successfully finished
                LumSettings = [LumSettings LumSetting];
            end
        end

     end

    

    colors = ["LightRed","DarkRed","LightYellow","DarkYellow","LightGreen","DarkGreen","LightTurquiose","DarkTurquiose","LightBlue","DarkBlue","LightPurple","DarkPurple","LightGray","DarkGray"];
    chrom = ["Hourglass","UpArrow","Diamond","Spike","Lock","Bar","Spade","Dodecagon","Sawblade","Nail","Rabbit","Puzzle","Venn","Hat"];
    achrom =["Chevron","Tie","Acorn","House","Pacman","Stickyhand","Bell","LeftArrow","Heart","Ditto","Crowbar","Gem","Jellyfish","Star"];

    colors_high = colors(1:2:end);
    chrom_high = chrom(1:2:end);
    achrom_high = achrom(1:2:end);

    colors_low = colors(2:2:end);
    chrom_low = chrom(2:2:end);
    achrom_low = achrom(2:2:end);
    
    
    DM_temp3 = strings(exactDur/TR,length(goodRuns));
    for i = 1:length(dataPaths)
        load(dataPaths{i},"exactDur","blocklength","TR","blockorder","LumSetting","colorCase","circleOrder","achromCase","achromOrder","bwCase","bwOrder","grayCase","stimDur","grayDur","choiceSectionDur");
        blocknames = strings(1,length(blockorder)); % This just initializes everything as a string vector
        endGrayDur = (exactDur/TR)-(blocklength*length(blockorder)); % This is because I actually mess up the calculations elsewhere
        if LumSetting == 1 % high luminance colors
            blocknames(blockorder == colorCase) = colors_high(circleOrder);
            blocknames(blockorder == achromCase) = achrom_high(achromOrder);
            blocknames(blockorder == bwCase) = chrom_high(bwOrder);
            blocknames(blockorder == grayCase) = "Background"; 
        elseif LumSetting == 2
            blocknames(blockorder == colorCase) = colors_low(circleOrder);
            blocknames(blockorder == achromCase) = achrom_low(achromOrder);
            blocknames(blockorder == bwCase) = chrom_low(bwOrder);
            blocknames(blockorder == grayCase) = "Background"; 
        elseif LumSetting == 3
            blocknames(blockorder == colorCase) = colors(circleOrder);
            blocknames(blockorder == achromCase) = achrom(achromOrder);
            blocknames(blockorder == bwCase) = chrom(bwOrder);
            blocknames(blockorder == grayCase) = "Background"; 
        end
        DM_temp1 = [repelem(blocknames,1,blocklength) repmat(["Background"],1,endGrayDur)];
        DM_temp2 = DM_temp1;
        for j = 1:length(blockorder)
            blockjump = (j-1)*blocklength;
            if grayDur > 0
                DM_temp2((blockjump+stimDur+1):(blockjump+stimDur+grayDur)) = "Background";
            end
            if blocknames(j) ~= "Background"
                DM_temp2((blockjump+stimDur+grayDur+1):(blockjump+stimDur+grayDur+choiceSectionDur)) = DM_temp2(blockjump+1) + "_Choice";
            end
        end
        DM_temp3(:,i) = DM_temp2;
    end

    DM = array2table(DM_temp3);
    DM.Properties.VariableNames = split(num2str(IMAs),'  ')
    if ispc
        writetable(DM,[mainpath '\\DMs.txt'],"Delimiter","\t")
    else
        writetable(DM,[mainpath '//DMs.txt'],"Delimiter","\t")
    end


            
    



    
end
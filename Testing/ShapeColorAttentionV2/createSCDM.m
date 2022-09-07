function [params] = createSCDM(params)
% Stuart J Duffield
DM_array = strings(params.runDur/params.TR,1);
TRind = 1;
for i = 1:length(params.orderNames)
    for j = 1:params.stimDur
        DM_array(TRind) = params.orderNames(i);
        TRind = TRind + 1;
    end
    for f = 1:params.grayDur
        DM_array(TRind) = "Background";
        TRind = TRind + 1;
    end
    for p = 1:params.choiceSectionDur
        if params.probeArray(i) == 1
            DM_array(TRind) = strcat(params.orderNames(i),"_Choice");
            TRind = TRind+1;
        else
            DM_array(TRind) = "Background";
            TRind = TRind + 1;
        end
    end
end
for i = 1:params.endGrayDur/params.TR
    DM_array(TRind) = "Background";
    TRind = TRind + 1;
end

DM = array2table(DM_array);
DM.Properties.VariableNames = params.IMA;
writetable(DM,params.DMSaveFile,"Delimiter","\t");


for traces = [2 3 4 5 6 7 8 19 20 21 22 25]
eyeFile = (['C:\Documents and Settings\Administrator\Desktop\Scanning STIMS and EYES\100221Pollux\21\cycle' num2str(traces) '\cycle' num2str(traces) 'EyeData']);
[eyeTime eyeX eyeY] = textread(eyeFile,'%f %f %f','headerlines',15);  
E = [eyeTime eyeX eyeY];


X = []; Y=[];
for i = 1:length(E)
    if E(i,2) > 0 && E(i,3) > 0
        X = [X E(i,2)];
        Y = [Y E(i,3)];
    end
end

% figure (traces) 
% scatter(X,Y)
% title(['100221Pollux eye trace ' num2str(traces)])

E(:,1) = E(:,1)-E(1,1);


%%PLOT BLOCK BY BLOCK
figure(traces)
k = 10:32:522;
    
for r = 1:16;
    X = []; Y=[];Xblink=[];Yblink=[];
    for i = 1:length(E)
        if E(i,1) >=k(r)+1 && E(i,1) <=k(r)+32 %&& E(i,2) > 0 && E(i,3) > 0
            X = [X E(i,2)];
            Y = [Y E(i,3)];
        end
    end
    subplot(4,4,r)
    scatter(X,Y,'b')
    xlim([0 1000])
    ylim([0 1000])
    title(['Block ' num2str(r)])
end

end



    





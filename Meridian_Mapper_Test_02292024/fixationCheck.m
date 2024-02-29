function percentFixation = fixationCheck(x,y)

CX = 960;
CY = 540;
s = 146.2603;
count = 0;
for i = 1:numel(x)
    if x(i) > CX-s && x(i) < CX+s && y(i) < CY+s && y(i) > CY-s
        count = count+1;
    end
end

percentFixation = count / numel(x);

end
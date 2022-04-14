function vector = trapezoid(length1,length2,color1,color2,offset,size,varargin)
        % Do we have a LUT?
        LUTcheck = false;
        if length(varargin) == 1
            LUT = varargin{1};
            LUTcheck = true;
        elsif len(varargin{:}) > 1
            disp('Too many argument inputs, interpreting first argument as the LUT')
            LUT = varargin{1};
            LUTcheck = true;
        end
        % If we have a LUT, we can precalculate where each color falls.
        % Will help with calculations later
        if LUTcheck
            color1inv = NaN(1,3);
            color2inv = NaN(1,3);
            for i = 1:length(color1)
                d = 0;
                while isnan(color1inv(i))
                    color1inv(i)= find(color1(i)+d==LUT(:,i))
                    d = d + 1; % Walk it up if it returns NaN
                end
            end
            for i = 1:length(color2)
                d = 0;
                while isnan(color2inv(i))
                    color2inv(i)= find(color2(i)+d==LUT(:,i))
                    d = d + 1; % Walk it up if it returns NaN
                end
            end
        end

        vector = NaN(1,size,3);
        cycleLen = 2*length1+2*length2;
        for i = offset+1:offset+size;
            % First, we need to calculate the cycle number and the position
            % within the cycle
            if i > cycleLen
                p = rem(i,cycleLen);
                if p == 0
                    p = cycleLen;
                end
            elseif i<0
                p = cycleLen-rem(abs(i),cycleLen);
            else
                p = i;
                if p == 0
                    p = cycleLen;
                end
            end
            % Now, we need to determine the color multipliers at any given
            % time
            if p >= 1 && p <= length1
                color1mult = 1;
                color2mult = 0;
                slope = false; 
            elseif p > length1 && p <= length1+length2
                color1mult = 1-((p-length1)/(length2+1));
                color2mult = (p-length1)/(length2+1);
                slope = true;
            elseif p > length1 + length2 && p <= 2*length1 + length2
                color1mult=0;
                color2mult=1;
                slope = false;
            else
                color1mult = 1-(((length2+1) - (p - (2*length1+length2)))/(length2+1));
                color2mult = ((length2+1) - (p - (2*length1+length2)))/(length2+1);
                slope=true;
            end
            % Now, we need to calculate the colors
            if LUTcheck && slope
                vector(1,i-offset,:) = LUT(color1inv*color1mult+color2inv*color2mult);
            else
                vector(1,i-offset,:) = color1*color1mult+color2*color2mult;
            end

        end

end





































% function vector = trapezoid(length1,length2,,color1,color2,offset,size)
%         vector = NaN(1,size);
%         cycleLen = 2*length1+2*length2;
%         for i = offset+1:offset+size;
%             if i > cycleLen
%                 p = rem(i,cycleLen);
%                 if p == 0
%                     p = cycleLen;
%                 end
%             elseif i<0
%                 p = cycleLen-rem(abs(i),cycleLen);
%             else
%                 p = i;
%                 if p == 0
%                     p = cycleLen;
%                 end
%             end
%             if p >= 1 && p <= length1
%                 vector(i-offset) = 0;
%             elseif p > length1 && p <= length1+length2
%                 vector(i-offset) = (p-length1)/(length2+1);
%             elseif p > length1 + length2 && p <= 2*length1 + length2
%                 vector(i-offset) = 1;
%             else
%                 vector(i-offset) = ((length2+1) - (p - (2*length1+length2)))/(length2+1);
%             end
%         end
% 
% end

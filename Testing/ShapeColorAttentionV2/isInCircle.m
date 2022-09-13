function [inCircle] = isInCircle(coordinates,circle)
% Calculates whether a coordinate is in a psychtoolbox rectangle
% Takes screen coordinates (in pixels) and returns whether or not that is
% in the circle. The circle is defined by a psychtoolbox rectangle
        radius = (circle(3) - circle(1)) / 2; % Get the radius of the circle
        [xCircleCenter, yCircleCenter] = RectCenter(circle); % Get the center of the circle
        xDiff = coordinates(1)-xCircleCenter; % Get the x portion of the vector difference
        yDiff = coordinates(2)-yCircleCenter; % Get the y portiont of the vector difference
        dist = hypot(xDiff,yDiff); % Get the total vector difference
        inCircle = radius>dist; % Is it in the circle?
end % Function end
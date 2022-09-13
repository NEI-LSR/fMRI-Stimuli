function isInside = IsInCircle(x, y, circle) % circle defined as a Rect [x1 y1 x2 y2]
    
    circleRadius = (circle(3)-circle(1)) / 2;
    [xCircleCenter, yCircleCenter] = RectCenter(circle);
    
    distanceFromCircleCenter = norm([x y] - [xCircleCenter yCircleCenter]);
    
    if distanceFromCircleCenter < circleRadius
        isInside = 1;
    else
        isInside = 0;
    end
    
end % Function End

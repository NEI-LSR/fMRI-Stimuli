function [xc y1c y2c] = commondomain(x1, y1, x2, y2)

% interpolate y1 and y2 at 1nm interval
if max(diff(x1)) > 1
  x1i = x1(1):x1(end);
  y1 = interp1(x1, y1, x1i, 'spline');
  x1 = x1i;
end
if max(diff(x2)) > 1
  x2i = x2(1):x2(end);
  y2 = interp1(x2, y2, x2i, 'spline');
  x2 = x2i;
end

% common range and domain
xc = [max([x1(1) x2(1)]):min([x1(end) x2(end)])];
y1c = y1(ismember(x1, xc), :);
y2c = y2(ismember(x2, xc), :);






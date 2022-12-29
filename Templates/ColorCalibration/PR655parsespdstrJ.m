function spd = PR655parsespdstrJ(readStr, S)
% spd = PR655parsespdstr(readStr,S)
%
% Parse the spectral power distribution string
% returned by the PR655.
% 
% 01/16/09    tbc   Adapted from PR650Toolbox for use with PR655
%
%disp(readStr)
if nargin < 2 || isempty(S)
	S = [380 5 81];
end

start = findstr(readStr,'380,');
for k= 1:101
%disp(k)
%disp(strcat('currVal = ',str2num(readStr(start+4+16*(k-1):start+4+9+16*(k-1)))))
    %fprintf('k: %d, bi: %d, ed: %d\n', k, start+6+17*(k-1), start+6+9+17*(k-1));
    spd(k,1) = (380+(k*4))-4;
	spd(k,2) = str2num(readStr(start+4+16*(k-1):start+4+9+16*(k-1)));
end

% Convert to our units standard.
%spd = 4 * spd';

% Spline to desired wavelength sampling.
%spd(:,2) = SplineSpd([380 4 101], spd, S);

return

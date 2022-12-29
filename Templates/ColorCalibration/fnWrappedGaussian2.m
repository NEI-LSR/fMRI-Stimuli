function [wG] = fnWrappedGaussian2(params, theta, opt)

%vectorial version

% WRAPPED GAUSSIAN FUNCTION (ie gaussian to fit circular data)
% default function behavior is in degrees, add opt arg is want to use
% radians
% theta is the angle
% params is a 1 by 4 vector containing the parameters of the model
% params = [max_height, spread, center, min_height]

validateattributes(params, {'double'}, {'numel', 4,  'ncols', 4})

if ~exist('opt','var') || isempty(opt)
    scale=360;
else
    scale=2*pi;
end

temp = zeros(length(theta), 4);
N = 4;
nVals = linspace(-N, N, 2*N+1);

for t = 1:numel(theta) 
    for i = 1:numel(nVals)
        temp(t, i) = exp(-(1/2)*((theta(t) - params(3)+scale*nVals(i))/params(2))^2);
    end
end

wG = (params(1)-params(4)) * sum(temp, 2) + params(4);
wG = wG';

end


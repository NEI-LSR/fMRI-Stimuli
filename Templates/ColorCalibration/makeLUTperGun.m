function [xlut, gammaTable, gammaTableCorrected] = makeLUTperGun(xdata, ydata, col, varargin)
global fileroot
%MAKELUT - Create lookup table for gamma correction.
%also generates plot of fits and inverse fit for visual inspection
  
if nargin == 4
    bitdepth = varargin{1};
else
    bitdepth = log(max(xdata)+1)/log(2); 
end

if bitdepth == 8
	fprintf('Working on 8 bit \n');
elseif bitdepth == 16
	fprintf('Working on 16 bit \n');
else
	error('Check bit depth value: should be 8 or 16...')
end 

nbLUTvalues = 2^bitdepth;
nbGammaTableValues = 1001;

% 1 - normalize range x and y data to 0-1
ydataold = ydata;
xdataold = xdata;
%ydata = (ydata-min(ydata))/(max(ydata)-min(ydata)); % in the inital script
%is it better? Check one day MD 
ydata = ydataold./max(ydataold);
xdata = xdataold./max(xdataold); 

% 2 - define start params and fit
p0 = [min(ydata) 1 2.2]; % starting values for [a/p(1), b/p(2), gamma/p(3)]
fun = @(p, x) p(1)+p(2)*x.^p(3); % better evaluation of gamma than just x.^gamma
if license('test','optimization_toolbox')
    pfit = lsqcurvefit(fun, p0, xdata, ydata);
else %when you have no toolboxes
    fun2 = @(p) sum((ydata - (p(1)+p(2)*xdata.^p(3))).^2); 
    opts = optimset('MaxFunEvals',50000, 'MaxIter',10000);
    pfit = fminsearch(fun2, p0, opts);
end
yfit = feval(fun, pfit, xdata);
residuals = yfit - ydata;
RMS = sqrt(mean(residuals.^2)); %evaluate fit
gammaTable = feval(fun, pfit, 0:1/nbGammaTableValues:1);

% 3 - compute inverse function and makelut
inv_fun = @(g, x) real(x.^(1/g)); %can't use the exact inverse of the fitted function
% because not bounded and artefacts when offset > x
ylut = linspace(0, 1, nbLUTvalues);
xlut = inv_fun(pfit(3), ylut);
xlut = round(xlut*(nbLUTvalues-1));
gammaTableCorrected = inv_fun(pfit(3), 0:1/nbGammaTableValues:1);
% 4 - plot
fig = figure;
plot(xdata, ydata, '.', 'color', col, 'MarkerSize', 15)
hold on
plot(xdata, feval(fun, pfit, xdata), col)
title(sprintf('%s gun - Max Lum = %3.1f - Gamma = %3.2f',col, ...
    max(ydataold),pfit(3)))
xlabel('input proportion of gun value')
ylabel('output proportion of Luminance max')
legend off
plot(0:0.01:1, inv_fun(pfit(3),0:0.01:1), col)
xlim([-0.05, 1.05])
ylim([-0.05, 1.05])
axis square
%saveas(fig, sprintf('%s_%sGunFit.eps',fileroot, col),'epsc')
saveas(fig, sprintf('%s_%sGunFit.png',fileroot, col),'png')

end 
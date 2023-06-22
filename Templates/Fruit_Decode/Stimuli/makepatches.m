fruits = ['Banana','Orange','Grape'];
for i = 1:length(fruits)
    fruit = fruits(i);
    a = dir([fruit '*.png']);
    for y = 1:length(a)
        disp(a(y).name)
        producetexture(a(y).name,40,4000);
    end
end

function producetexture(imgname,respatch,sizepatch)
magnification = sizepatch/respatch;
[img, map, alpha] = imread(imgname);
a_flat = reshape(img,size(img,1)*size(img,2),3);
mask_flat = logical(round(reshape(alpha,size(alpha,1)*size(alpha,2),1)/255));
colors = a_flat(mask_flat,:);
colorsample = randsample(size(colors,1),respatch^2,true);
colorresampled = colors(colorsample,:);
patch=reshape(colorresampled,respatch,respatch,3);
gauss= gauss2d(respatch,respatch,[respatch/2,respatch/2]);
patch=repelem(patch,magnification,magnification,1);
gauss=repelem(gauss,magnification,magnification);
h = imshow(patch);
set(h,'AlphaData',gauss);
saveas(h,['patch_' imgname]);
end
function mat = gauss2d(gsize, sigma, center)
[R,C] = ndgrid(1:gsize, 1:gsize);
mat = gaussC(R,C, sigma, center);
end
function val = gaussC(x, y, sigma, center)
xc = center(1);
yc = center(2);
exponent = ((x-xc).^2 + (y-yc).^2)./(2*sigma);
val       = (exp(-exponent));
end
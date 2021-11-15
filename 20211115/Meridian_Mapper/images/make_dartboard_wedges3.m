% TODO: vectorize me... anti-aliasing?
clear all
tic
img_width = 1280;
img_height = 1024;
img_path = fullfile('c:', 'space', 'data', 'stimulation', 'stim_hb', 'morgue', 'images', 'retinotopy');
img_path = pwd;
img_base_name = 'dartboard';
n_imgs = 2;
% parameters for parent dartboard image
x_center = img_width / 2;
y_center = img_height / 2;
NumRings = 15;  %formula for radius given by 240 = exp^(6*a) -1 => a = 0.9141
NumWedges = 36;
theta_offset = 0;	% phase angle of the sectors...
bg_grey = 0.5;	% background grey level of the wedges
color_type = 'bw-alt';%'bw-alt';	% bw-alt, rand_col, uniform
uni_color = [0.5 0.5 0.5];
%uni_color = [1 1 1];
checker_type = 'checker50';	% checker100 (use calculated color for every sector) or checker50 (only color every other sector)

% parameters for mask
mask_type = 'wedge';	% wedge or ring or none, wegdes are mirror symmetric orthogonal to axis
mask_color = bg_grey; % 0.0
mask_wedge = 60;
mask_axis = 90;	% 0 is vertical
% levy, hasson, avidan, hendler, malach 2001: eccentricities
%	center: circle radius 0.9deg
%	mid: 1.25 deg inner radius, 2.5 deg outer radius
%	periphery: 5 deg inner radius, 10 deg outer radius
mask_inner_radius_deg = 1.25;
mask_outer_radius_deg = 2.5;
hb_deg_per_pixel = (atan(10.4 / 49.0) * 180 / pi)/ 400;
mask_inner_radius = mask_inner_radius_deg / hb_deg_per_pixel;
mask_outer_radius = mask_outer_radius_deg / hb_deg_per_pixel;

%init parameters
alpha = log((img_height / 2) - 1) / NumRings;
radii = [exp(alpha * (1:NumRings)) - 1];

% vector style mode of calculation of the images...
[x_ind, y_ind] = meshgrid([1:img_width], [1:img_height]);
x_vec = x_ind - 0.5 - x_center;	% pixel considered to be one pixel wide, -0.5 takes the pixel center...
y_vec = y_ind - 0.5 - y_center;
% calculate the polar angle theta for each pixel relative to the center
%theta_map = (atan(y_vec ./ x_vec) * 180 / pi + 180)';
theta_map = (atan2(y_vec, x_vec) * 180 / pi + 180)';
% clean up the division by zero NaNs...
x_zero_idx = find(x_vec(1, :) == 0);
y_zero_idx = find(y_vec(:, 1) == 0);
theta_map(x_zero_idx, 1:y_zero_idx -1) = 90;
theta_map(x_zero_idx, y_zero_idx :end) = 270;
% create theta_map with phase shift of theta-offset degs
if (theta_offset ~= 0),
	color_theta_map = mod(theta_map + theta_offset, 360);
	theta_map = color_theta_map;
end
% calculate for each pixel to which wqedge it belongs.
wedge_id = ceil(theta_map * NumWedges / 360);

% calculate the distance/radius for each pixel to the center in pixel
radius_map = round(sqrt(x_vec.^2 + y_vec.^2))';
ring_id = radius_map;

% calculate for each pixel to which ring it belongs
for i_ring = 1:length(radii)
	tmp_idx = find(radius_map > radii(i_ring));
	ring_id(tmp_idx) = i_ring;
end
% the center pixel (if any), will be placed in ring 1 as well.
ring_zero = find(ring_id == 0);
ring_id(ring_zero) = 1;


for im =  1:n_imgs
	
	image = zeros(img_width, img_height, 3) + bg_grey';

	% assign the color information
	odd_im = mod(im, 2);
	for i_ring = 1:NumRings
		odd_ring = mod(i_ring, 2);
		ring_idx = find(ring_id == i_ring);
		%ring_idx = find(ring_id < 100);
		for j_wedge = 1:NumWedges
			odd_wedge = mod(j_wedge, 2);
			wedge_idx = find(wedge_id == j_wedge);
			%wedge_idx = find(wedge_id < 100);
			img_idx = intersect(ring_idx, wedge_idx);
			if ~isempty(img_idx),
				switch color_type
					case 'uniform'
						sector_col = uni_color;
					case 'rand_col'
						sector_col = rand(1,3);
					case 'bw-alt'
						if odd_ring == 0,
							sector_col = zeros(1, 3) + (odd_wedge);
						else
							sector_col = zeros(1, 3) + (~odd_wedge);
						end
						if odd_im == 0,
							sector_col = ~sector_col;
						end
				end
				image(img_idx) = sector_col(1);
				image(img_idx + img_width * img_height) = sector_col(2);
				image(img_idx + 2 * img_width * img_height) = sector_col(3);
			end
		end

	end
	
	% create mask
	mask = ones(img_width, img_height);
	mask_half_wedge = mask_wedge / 2;
	switch mask_type
		case 'wedge'
			% avoid wegdes spanning over the 0/360 line...
			if (((mask_axis - mask_half_wedge) < 0) | ((mask_axis + mask_half_wedge) > 360)),
				mask_theta_map = mod(theta_map + 180, 360);
				mask_ax = mod(mask_axis + 180, 360);
			else
				mask_theta_map = theta_map;
				mask_ax = mask_axis;
			end
% 			masked_pixel1_idx = find(mask_theta_map <= mask_ax - mask_half_wedge);
% 			masked_pixel2_idx = find(mask_theta_map >= mask_ax + mask_half_wedge);
% 			masked_pixel_1_idx = union(masked_pixel1_idx, masked_pixel2_idx);
			masked_pixel_1_idx = find((mask_theta_map <= mask_ax - mask_half_wedge) | (mask_theta_map >= mask_ax + mask_half_wedge));

			% avoid wegdes spanning over the 0/360 line...
			if (((mask_axis + 180 - mask_half_wedge) < 0) | ((mask_axis + 180 + mask_half_wedge) > 360)),
				mask_theta_map = mod(theta_map + 180, 360);
				mask_ax = mod(mask_axis + 180, 360);				
			else
				mask_theta_map = theta_map;
				mask_ax = mask_axis;				
			end
% 			masked_pixel3_idx = find(mask_theta_map <= mask_ax + 180 - mask_half_wedge);
% 			masked_pixel4_idx = find(mask_theta_map >= mask_ax + 180 + mask_half_wedge);
% 			masked_pixel_2_idx = union(masked_pixel3_idx, masked_pixel4_idx);
			masked_pixel_2_idx = find((mask_theta_map <= mask_ax + 180 - mask_half_wedge) | (mask_theta_map >= mask_ax + 180 + mask_half_wedge));
			
			masked_pixel_idx = intersect(masked_pixel_1_idx, masked_pixel_2_idx);
			mask(masked_pixel_idx) = 0; % apply the mask
%			figure
%			imagesc(mask);
		case 'ring'
			masked_pixel_idx = find((radius_map <= mask_inner_radius) | (radius_map > mask_outer_radius));
			mask(masked_pixel_idx) = 0; % apply the mask
% 			imagesc(mask);
			% fill me in
		case 'none'
				mask = ones(img_width, img_height);
	end

	% apply the mask, if any
	mask_idx = find(~mask);
	if ~isempty(mask_idx)
		image(mask_idx) = mask_color;
		image(mask_idx + img_width * img_height) = mask_color;
		image(mask_idx + 2 * img_width * img_height) = mask_color;
	end

	% preview the image
	image = permute(image, [2 1 3]);
	figure
	imagesc(image);
	axis equal

	switch mask_type
		case 'wedge'
			filename = sprintf('%s\\%s_%s_%s_w%d_a%d_%d.tif', img_path, img_base_name, color_type, checker_type, mask_wedge, mask_axis, im);
		case 'none'
			filename = sprintf('%s\\%s_%s_%s_%d.tif', img_path, img_base_name, color_type, checker_type, im);
		case 'ring'
			filename = sprintf('%s\\%s_%s_%s_ir%04.2f_or%04.2f_%d.tif', img_path, img_base_name, color_type, checker_type, mask_inner_radius_deg, mask_outer_radius_deg, im);
	end
 	imwrite(image, filename, 'tif');
end
toc
disp('done...');
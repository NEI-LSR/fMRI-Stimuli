function drawGamutLimits()
	
	
	filename = 'gamutLimit.txt';
	
	fid = fopen(filename, 'r');
	
	formatSpec = '******* C:%f G:%f broke';
	
	D = textscan(fid, formatSpec);
	
	chroma = D{1};
	grey = D{2};
	
	figure();
	
	plot(chroma, grey, 'ko');
	xlim([0, 1]);
	ylim([0, 1]);
	axis square;
	xlabel('chroma');
	ylabel('grey');
	set(gca, 'XTick', [0:.1:1], 'YTick', [0:.1:1], 'XGrid', 'on', 'YGrid', 'on');
	
	errorok;
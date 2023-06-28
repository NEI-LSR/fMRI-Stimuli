function findLUVColors(filename,calibrationfolder)
    % Takes target LUV values and finds appropriate XYZ and RGB values
    % given a Cx3 size spreadsheet of target LUV values and the name of the
    % calibrated monitor as listed in the 'measurements' folder

    curdir = pwd;
    targvaldir = fullfile(curdir,'targetvalues');
    measurementsdir = fullfile(curdir,'measurements');
    calibrationdir = fullfile(measurementsdir,calibrationfolder);
    load(fullfile(calibrationdir,[calibrationfolder '.mat']));
    load(fullfile(calibrationdir,[calibrationfolder '_LUT.mat']));

    LUV = csvread(fullfile(targvaldir,filename));

    redpoint = LumValues.red(end).xyYJudd;
    greenpoint = LumValues.green(end).xyYJudd;
    bluepoint = LumValues.blue(end).xyYJudd;
    whitepoint = LumValues.white(end).xyYJudd;
    XYZ2RGBM = XYZToRGBMatrix(redpoint(1),redpoint(2),greenpoint(1),greenpoint(2),bluepoint(1),bluepoint(2),whitepoint(1),whitepoint(2));

    for i = 1:size(LumValues.white,1)
        disp(['Testing white gunvals of ' num2str(LumValues.white(i).gunValue)])
        test_whitepoint = LumValues.white(i).xyYJudd;
        twXYZ = xyYToXYZ(test_whitepoint');
        xyzvals = LuvToXYZ(LUV',twXYZ);
        estRGB = round((XYZ2RGBM * xyzvals));
        disp(['Maximum gunval:' num2str(max(estRGB,[],'all'))])
        disp(['Minimum gunval:' num2str(min(estRGB,[],'all'))])
        estRGB(estRGB>256) = 256;
        estRGB(estRGB<1) = 1;
        estRGB_lookup = LUT(estRGB');


        outrgb = fullfile(targvaldir,['targRGB_whitepoint_'  num2str(LumValues.white(i).gunValue) '.csv']);
        outxyz = fullfile(targvaldir,['targXYZ_whitepoint_'  num2str(LumValues.white(i).gunValue) '.csv']);

        csvwrite(outrgb,estRGB_lookup);
        csvwrite(outxyz,xyzvals');
    end


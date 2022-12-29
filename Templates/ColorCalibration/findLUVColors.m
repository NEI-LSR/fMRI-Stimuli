function findLUVColors(filename,calibrationfolder)
    % Takes target LUV values and finds appropriate XYZ and RGB values
    % given a Cx3 size spreadsheet of target LUV values and the name of the
    % calibrated monitor as listed in the 'measurements' folder

    curdir = pwd;
    targvaldir = fullfile(curdir,'targetvalues');
    measurementsdir = fullfile(curdir,'measurements');
    calibrationdir = fullfile(curdir,calibrationfolder);
    LumValues = load(fullfile(calibrationdir,[calibrationfolder '.mat']));
    LUT = load(fullfile(calibrationdir,[calibrationfolder '_LUT.mat']));

    LUV = csvread(fullfile(targvaldir,filename));

    redpoint = LumValues.red(end).xyYJudd;
    greenpoint = LumValues.green(end).xyYJudd;
    bluepoint = LumValues.blue(end).xyYJudd;
    whitepoint = LumValues.white(end).xyYJudd;
    XYZ2RGBM = XYZToRGBMatrix(redpoint(1),redpoint(2),greenpoint(1),greenpoint(2),bluepoint(1),bluepoint(2),whitepoint(1),whitepoint(2));

    for i = size(LumValues.white,1):1
        disp(['Testing white gunvals of ' LumValues.white(i).gunValue])
        test_whitepoint = LumValues.white(i).xyYJudd;
        twXYZ = xyYToXYZ(test_whitepoint');
        xyzvals = LuvToXYZ(LUV',twXYZ);
        estRGB = XYZ2RGBM * xyzvals;
        estRGB_lookup = LUT(estRGB');
        disp(['Maximum gunval:' max(estRGB_lookup)])
        disp(['Minimum gunval:' min(estRGB_lookup)])
        outrgb = fullfile(targvaldir,['targRGB_whitepoint_'  LumValues.white(i).gunValue]);
        outxyz = fullfile(targvaldir,['targXYZ_whitepoint_'  LumValues.white(i).gunValue]);

        writecsv(estRGB_lookup,outrgb);
        writecsv(estRGB_lookup,outxyz);
    end


function findLUVColors2(filename,calibrationfolder,varargin)
    % Takes target LUV values and finds appropriate XYZ and RGB values
    % given a Cx3 size spreadsheet of target LUV values and the name of the
    % calibrated monitor as listed in the 'measurements' folder
    % Updated so that it actually samples a number of whitepoints
    
    if length(varargin) > 0
        sampledist = varargin{1};
    else 
        sampledist = 5;
    end

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
    allpoints = [redpoint; greenpoint; bluepoint; redpoint]; % This is for plotting later
    whitepoint = LumValues.white(end).xyYJudd;

    bluepointXYZ = xyYToXYZ(bluepoint');
    greenpointXYZ = xyYToXYZ(greenpoint');
    redpointXYZ = xyYToXYZ(redpoint');


    Zsamples = round(floor(bluepointXYZ(3)/4):sampledist:floor(bluepointXYZ(3)));
    Ysamples = round(floor(greenpointXYZ(2)-60):sampledist:floor(greenpointXYZ(2)));
    Xsamples = round(floor(redpointXYZ(1)-60):sampledist:floor(redpointXYZ(1)));

    XYZ2RGBM = XYZToRGBMatrix(redpoint(1),redpoint(2),greenpoint(1),greenpoint(2),bluepoint(1),bluepoint(2),whitepoint(1),whitepoint(2));
    
    for i = 1:length(Xsamples)
        for y = 1:length(Ysamples)
            for j = 1:length(Zsamples)
                test_whitepoint = [Xsamples(i) Ysamples(y) Zsamples(j)];
                xyzstring = strrep(num2str(test_whitepoint),' ','_');
                disp(['Testing XYZ values of ' xyzstring])
                whitepointRGB = round(XYZ2RGBM * test_whitepoint');
                rgbstring = strrep(num2str(whitepointRGB'),' ','_');
                disp(['RGB ' rgbstring])

                xyzvals = LuvToXYZ(LUV',test_whitepoint');
                estRGB = round((XYZ2RGBM * xyzvals));
                if max(estRGB) <=256 & min(estRGB) >= 1
                    disp('good')
                    eval = 'good';
                    evalbool = true;
                else
                    disp('bad')
                    eval = 'bad';
                    evalbool = false;
                end
                estRGB(estRGB>256) = 256;
                estRGB(estRGB<1) = 1;
                estRGB_lookup = LUT(estRGB');

                whitepointinfo = [test_whitepoint; whitepointRGB'];

                if evalbool
                    outrgb = fullfile(targvaldir,['targRGB_whitepoint_'  xyzstring '.csv']);
                    outxyz = fullfile(targvaldir,['targXYZ_whitepoint_'  xyzstring '.csv']);
                    outinfo = fullfile(targvaldir,['info_whitepoint_' xyzstring '.csv']);
                    outplot = fullfile(targvaldir,['chromaticityplot_' xyzstring '.png']);

                    csvwrite(outrgb,estRGB_lookup);
                    csvwrite(outxyz,xyzvals');   
                    csvwrite(outinfo,whitepointinfo); 
                end

                
                xyYvals = XYZToxyY(xyzvals);
                if evalbool
                    figure('visible','off');
                    hold on
                    DrawChromaticity
                    plot(allpoints(:,1),allpoints(:,2));
                    scatter(xyYvals(1,:),xyYvals(2,:),'x');
                    saveas(gcf,outplot);
                    title(['Whitepoint' xyzstring]);
                    close;
                end
            end
        end
    end


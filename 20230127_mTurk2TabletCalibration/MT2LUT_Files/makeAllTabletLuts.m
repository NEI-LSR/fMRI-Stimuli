function makeAllTabletLuts()


clear VARIABLES
clear GLOBAL
clear FUNCTIONS

nColors = 36;

fnm1 = '30-Jan-2023_discovery';
fnm2 = '30-Jan-2023_apollo';
fnm3 = '30-Jan-2023_sputnik';
fnm4 = '30-Jan-2023_voyager';
fnm5 = '30-Jan-2023_curiosity';

% fnm1 = '26-Mar-2021_R52KC0W2M5J';
% fnm2 = '25-Mar-2021_ R52KC0W1T9B';
% fnm3 = '24-Mar-2021_R52KC0W29CH';
% fnm4 = '22-Mar-2021_R52KC0W29HR'; 
fnms = {fnm1, fnm2, fnm3, fnm4, fnm5};

dmp = true; % Do you want to dump out files

% chroma
cstart = 0.3;
cstep = 0.3;
cstop = 0.3;

%grey
gmid = 0.425;
gdiff = 0.2;

gstart = gmid-gdiff;
gstep = gdiff/10;
gstop = gmid+gdiff;

nc = length(cstart:cstep:cstop);
ng = length(gstart:gstep:gstop);

niter = nc*ng;

for n = 1:length(fnms)

    fnm = fnms{n};

    iter = 0;

    wb = waitbar(iter, 'Calculating');

    nogood = [];
    good = [];

    allRGB = [];
    allluv = [];
    nlum = length(gstart:gstep:gstop);

    for chroma = cstart:cstep:cstop
        for greyVal = gstart:gstep:gstop
            iter = iter + 1;

            waitbar(iter/niter, wb);

            try

                
                [rgb, luv, gry] = LUV_to_RGB_James_byJames(nColors, chroma, greyVal, fnm, dmp);

                good = [good; chroma, greyVal];

            catch
                % 				disp(['******* C:',num2str(chroma), ' G:',num2str(greyVal),' broke']);
                nogood = [nogood; chroma, greyVal];
            end;

            allRGB = [allRGB; rgb];
        end;
    end;
    

    delete(wb);

    title(fnm);
    % 		errorok

    disp(fnm);
    disp('max');
    disp(255.*max(allRGB));

    disp('min');
    disp(255.*min(allRGB));


    if ~isempty(nogood)
        disp(['Err at ']);
        disp(num2str(nogood));
        disp(' ');
    end;
    
    % uncomment to rewrite luts
    if dmp
        dumpLuts(nlum, allRGB, gry, fnm);
    end

end;


%***********************************************************%
%***********************************************************%
%***********************************************************%


%***********************************************************%
%***********************************************************%
%***********************************************************%
function dumpLuts(nlum, rgb, gry, fnm)

allrgb = cell(nlum,1);
nrgb = size(rgb,1)/nlum;
idx = 1:nrgb;

for m = 1:nlum
    allrgb{m} = round(255.*rgb(idx,:));

    idx = idx + nrgb;
end;  % nlum



spotfilename = [fnm,'_RGB.txt'];

ubidx = find(fnm=='_', 1, 'First');

spotfilename = spotfilename((ubidx+1):end);

disp(['Writing ', spotfilename]);

fid = fopen(spotfilename, 'w');

ccmp = {'red', 'green', 'blue'};

gry = round(gry);

fprintf(fid, '"calibname":"%s",\r\n', spotfilename);
fprintf(fid, '"grey":[%d, %d, %d];\r\n', gry(1), gry(2), gry(3));




for cc = 1:length(ccmp)
    fprintf(fid, '"%s":[\r\n', ccmp{cc});

    for lum = 1:length(allrgb)
        fprintf(fid, '[');

        rgb = allrgb{lum};
        nc = size(rgb,1);

        for c = 1:(nc-1)

            val = rgb(c, cc);
            val = round(val);
            fprintf(fid, '%d, ', val);

        end;
        val = rgb(nc, cc);
        val = round(val);
        fprintf(fid, '%d', val);


        fprintf(fid, '],\r\n');


    end;  % lum
    fprintf(fid, '];\r\n');

end;  % cc
fclose(fid);

%% From RGB2XYZ for any Screen
% use rgb2xyzC
% Compare it with  the one that is right now in the script
% If it fits, then you can load other spectral distributions and you  are
% good to go
% Btw, this script is directly inspired from http://www.brucelindbloom.com/

%% Initialize few color properties
    
% load spectral distribution of the white point         
%GunSpectra  = xlsread('./CALIB/SpectralDataVPIXX20170921.xls');
%GunSpectra  = csvread('./CALIB/SpectralDataVPIXX20171030.csv');
%GunSpectra  = xlsread('./spectra.xls');

[file,path,indx] = uigetfile; 
NAME  = who('-file', [path, file]); 
DAT   = load([path, file]); 
GunSpectra(:,1)   = DAT.(NAME{1}).red(end).Spectrum(:,1); 
GunSpectra(:,2)   = DAT.(NAME{1}).red(end).Spectrum(:,2); 
GunSpectra(:,3)   = DAT.(NAME{1}).green(end).Spectrum(:,2); 
GunSpectra(:,4)   = DAT.(NAME{1}).blue(end).Spectrum(:,2); 

xyz         = csvread('./ciexyz31_1.txt');
xyzI        = interp1(xyz(:,1), xyz(:,2:4),GunSpectra(:,1),'spline');
Vlambda     = xyzI(:,2);

spectra_Rmax= [GunSpectra(:,1) GunSpectra(:,2)];
RmaxXYZ     = GunSpectra(:,2)'*xyzI;
Rmaxxyz     = RmaxXYZ/sum(RmaxXYZ);

spectra_Gmax= [GunSpectra(:,1) GunSpectra(:,3)];
GmaxXYZ     = GunSpectra(:,3)'*xyzI;
Gmaxxyz     = GmaxXYZ/sum(GmaxXYZ);

spectra_Bmax= [GunSpectra(:,1) GunSpectra(:,4)];
BmaxXYZ     = GunSpectra(:,4)'*xyzI;
Bmaxxyz     = BmaxXYZ/sum(BmaxXYZ);
%We enter x,y relative values of R, G and B guns (from measurements)

K = 683;
lambda     =spectra_Rmax(:,1); %get wavelengths used for monitor spectra
LambdaStep = diff(lambda);

% White value

white(1)   = LambdaStep(1)*sum(K*(Vlambda.*spectra_Rmax(:,2))); %1\2 * Rmax 
white(2)   = LambdaStep(1)*sum(K*(Vlambda.*spectra_Gmax(:,2))); %1\2 * Gmax 
white(3)   = LambdaStep(1)*sum(K*(Vlambda.*spectra_Bmax(:,2))); %1\2 * Bmax 

LumWhite = sum(white);

rx   = Rmaxxyz(1);
ry   = Rmaxxyz(2);
rz   = 1-(rx+ry);
gx   = Gmaxxyz(1);
gy   = Gmaxxyz(2);
gz   = 1-(gx+gy);
bx   = Bmaxxyz(1);
by   = Bmaxxyz(2);
bz   = 1-(bx+by);

% I compute everything as if I do not have access to the absolute energy
% which is not true. But the resulting matrix is the same anyway
% Raw rgb2xyz matrix for any screen. do not relate on the white point at
% first
rgb2xyz  = [rx    gx    bx; %x
            ry    gy    by; %y
            rz    gz    bz];%z

% from the relative matrix I want to specify the white point 
% Normalize the matrix with the y value of each gun so that y is equal to one for each of them  

rgb2xyzNorm = [rx/ry    gx/gy    bx/by; %x
                   1        1      1  ; %y
               rz/ry    gz/gy    bz/by];%z

% xyz white value of the screen
Whitexyz     = (RmaxXYZ' + GmaxXYZ' + BmaxXYZ')/sum((RmaxXYZ' + GmaxXYZ' + BmaxXYZ'));
% Normalize the vector with the y value so that y is equal to one  
WhitexyzNorm = Whitexyz/Whitexyz(2);

% Normalization factor for the considered white (AX = b, X = A-1*b)
% ie compute the X = Lw vector allow me to define truly the white point with my
% rgb2xyz matrix?
Lw       = rgb2xyzNorm\WhitexyzNorm;

rgb2xyzC = [rgb2xyzNorm(:,1)*Lw(1), rgb2xyzNorm(:,2)*Lw(2), rgb2xyzNorm(:,3)*Lw(3)];

% To check that everything is ok:
% Compute the white point with R = G = B
whitexyzNormTest =   rgb2xyzC*[1;1;1];
isequal(whitexyzNormTest,WhitexyzNorm)

whiteXYZ =   LumWhite * whitexyzNormTest;


saveFlag = questdlg('Save RGB2XYZ Transformation Matrix?', 'save', 'yes', 'no', 'yes');
if saveFlag == 'yes'
	[~, fname, ext] = fileparts(file);
	save([path, fname, '_RGB2XYZtransformMat', ext], 'rgb2xyzC'); 
end 


       
function [bsuccess] = CPforBLnoPTB(mx)

pos = get(gcf, 'Position'); %// gives x left, y bottom, width, height
screenWidth = pos(3);
screenHeight = pos(4);
size = min([screenWidth screenHeight]);

squaresize = size / 6;
xpos = screenWidth/2; 
ypos = screenHeight/2;

set(gca,'Color',mx/255)
disp(['Reading #' num2str(1) ': ' num2str(mx(1,:))]);

bsuccess = 1;


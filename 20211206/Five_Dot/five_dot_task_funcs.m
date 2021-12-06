function Vraw = drawEyePos(Vcent,gain,center,baseRect,channels)
    Vraw = fnDAQNI('GetAnalog',channels);
    Xpos = (Vraw(1) - Vcent(1))*gain(1) + center(1);
    Ypos = (Vraw(2) - Vcent(2))*gain(2) + center(2);
    eyePosRect = CenterRectOnPointd(baseRect,Xpos,Ypos);
end

function x = random(y)
    x = y
end
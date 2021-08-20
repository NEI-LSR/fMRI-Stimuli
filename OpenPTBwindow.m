function [window] = OpenPTBwindow(params)
    
    PsychDefaultSetup(2);
    InitializeMatlabOpenGL;
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    Screen('Preference', 'DefaultFontSize', round(12*params.display.scaleHD));
    Screen('Preference', 'DefaultFontName', 'Courier');
    PsychImaging('PrepareConfiguration');
    
    window = PsychImaging('OpenWindow', params.display.num, params.display.blackBackground, params.display.windowRect, [], [], [], 16);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    
end % Function end

function [varargout] = OpenPTBwindow(params)
    
    PsychDefaultSetup(2);
    InitializeMatlabOpenGL;
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'Verbosity', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    Screen('Preference', 'DefaultFontSize', round(12*params.display.scaleHD));
    Screen('Preference', 'DefaultFontName', 'Courier');
    %PsychImaging('AddTask', 'General', 'UseRetinaResolution');
    PsychImaging('PrepareConfiguration');
    
    if params.system.screens == 1
        window = PsychImaging('OpenWindow', params.display.num, params.display.blackBackground, params.display.windowRect, [], [], [], 16);
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        
        varargout{1} = window
        
    elseif params.system.screens == 2
        window = PsychImaging('OpenWindow', params.display.num1, params.display.blackBackground, params.display.monkWindowRect, [], [], [], 16);
        Screen('BlendFunction', window, 'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');
        
        window2 = PsychImaging('OpenWindow', params.display.num2, params.display.blackBackground, params.display.expWindowRect, [], [], [], 16);
        Screen('BlendFunction', window2, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        
        varargout{1} = window
        varargout{2} = window2
    end
end % Function end

% SAFEEXIT runs all commands allowing for a safe exit.
function [] = safeExit()

global EYE_TRACKER padhandle

try
    if EYE_TRACKER
        endEyeTracker();
    end
    % Close the audio device
    PsychPortAudio('Close', padhandle);
    
    % Closing everything
    Priority(0);
    sca;
    ShowCursor;
    ListenChar(0);
    saveCode;
    
catch
    if EYE_TRACKER
        endEyeTracker();
    end
    % Close the audio device
    PsychPortAudio('Close', padhandle);
    
    % Closing everything
    Priority(0);
    sca;
    ShowCursor;
    ListenChar(0);
    saveCode;
end
end
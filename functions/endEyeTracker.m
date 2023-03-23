%% EYE_TRACKER TRIGGER FUCNTIONS

%ENDTRIG
% The function sends end of experiment signals to the eyetracker and
% saves it in the data folder.
function [] = endEyeTracker()
%Stopping the eyetracker recording
Eyelink('StopRecording')
% Restoring the Eyetracker to the state we found it in:
Eyelink('Command','include "PHYSICAL.INI"')
Eyelink('Command','include "FINAL.INI"')
Eyelink('Command','include "PARSER.INI"')
% Shutting down the Eyelink
Eyelink('Shutdown')
end
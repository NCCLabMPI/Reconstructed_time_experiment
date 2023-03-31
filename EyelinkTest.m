% PTB Eyelink test:
WINDOW_RESOLUTION = [10 10 1200 800];
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
% Get the different screens:
screens = Screen('Screens');
% Use the last screen preferentially:
screenNumber = max(screens);
[w, wRect] = Screen('OpenWindow',screenNumber, [125, 125, 125]); 

% Open Eyelink and run the calibration:
% Initializing eyelink
Eyelink('Initialize');

% Initializes Eyelink and Ethernet system. Opens tracker connection, reports any problems.
%window (above) is the window you set with the function Screen(\91OpenWindow\92)
el = EyelinkInitDefaults(w);

Eyelink('Openfile', 'test.edf');
% Setting the eyetracker to binocular
Eyelink('command','binocular_enabled = NO')

% Setting calibration to 13 dots
Eyelink('command','calibration_type = HV13')
EyelinkDoTrackerSetup(el);

% Starting the recording
Eyelink('StartRecording');
% Wait for the recording to have started:
WaitSecs(1);
% Stop the recording:
Eyelink('StopRecording');
%Closing the edf file
Eyelink('CloseFile')
status=Eyelink('ReceiveFile','test.edf', 'test.edf');
% Shutting down the Eyelink
Eyelink('Shutdown')


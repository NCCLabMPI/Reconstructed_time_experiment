% INITEYETRACKER
% This function initialize the eyetracker
function [] = initEyetracker(blk)
global el edfFile w subjectNum SCREEN_SIZE_CM viewDistanceBottomTop  DISTANCE_SCREEN_TRACKER

% Initializing eyelink
Eyelink('Initialize');

% Initializes Eyelink and Ethernet system. Opens tracker connection, reports any problems.
%window (above) is the window you set with the function Screen(\91OpenWindow\92)
el = EyelinkInitDefaults(w);

el.backgroundcolour = [125 125 125];
EyelinkUpdateDefaults(el);

% name and open file to record data to
%VERY IMPORTANT: THE NAME OF THE FILE SHOULD BE SHORT (5-6 CHARACTERS), OTHERWISE IT WILL GIVE AN ERROR AND IT WON\92T SAVE THE FILE!!!
edfFile = sprintf('%d_%d.edf',subjectNum,blk);
Eyelink('Openfile', edfFile);

s = Eyelink('command','camera_lens_focal_length = 16');

% Setting the eyetracker to binocular
Eyelink('command','binocular_enabled = NO')

% Setting calibration to 13 dots
Eyelink('command','calibration_type = HV13')

% Setting calibration to manual
Eyelink('command', 'enable_automatic_calibration = NO')
% Setting the thresholds for saccade and other events
% (see: http://download.sr-support.com/dispdoc/cmds9.html)
Eyelink('command','select_parser_configuration = 0') % 0 for standard, 1 for psychophysics!
% Below are the default values of the standard eyetracker configuiration.
% You can change single values if you need:
% Eyelink('command', 'saccade_velocity_threshold = 22');
% Eyelink('command', 'saccade_acceleration_threshold = 3800');
% Eyelink('command', 'saccade_motion_threshold=0.0');
% Eyelink('command', 'saccade_pursuit_fixup=60');
% Eyelink('command', 'fixation_update_interval=0');
% Eyelink('command', 'fixation_update_accumulate=0');


% We have to retrieve a few information concerning the tracker. It is
% likely that some labs will be using old version of the tracker. And in
% some versions the parameters are a bit different, and some parameters
% cannot be set from the experiment PC.
% Retrieving the tracker version and the tracker software version
[~,vs] = Eyelink('GetTrackerVersion');
fprintf('Running the experiment on a ''%s'' tracker.\n',vs)

% Setting file event filter:
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
% Settibg sample data types
Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,RAW,AREA,HTARGET,GAZERES,BUTTON,STATUS,INPUT');

% Adding link events and samples: in case we later decide to do online
% stuffs. These commands make it possible to call the different events and
% data through the link, to call them during the experiment and use them as
% we are running:
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,HTARGET,STATUS,INPUT');

% Set the sampling rate to 1000Hz:
Eyelink('command', 'sample_rate = 1000');

% Set the use of ellipse filter to no:
Eyelink('command', 'use_ellipse_fitter = no');

% Set the illuminator to 75%:
Eyelink('command', 'elcl_tt_power = 2');

% Pass the screen physical coordinates in mm. Required for online parsers:
% [<left>, <top>, <right>, <bottom>]: 
SCREENPHYSICALCOORDINATES = [-SCREEN_SIZE_CM(1,1)/2, SCREEN_SIZE_CM(1,2)/2,...
    SCREEN_SIZE_CM(1,1)/2, -SCREEN_SIZE_CM(1,2)/2]*10; % NEEDS TO BE IN MM
Eyelink('command',' screen_phys_coords=%s',num2str(SCREENPHYSICALCOORDINATES))% : to set the screen size in mm

% Set the distance between screen and participant, also necessary for online parsers:
Eyelink('command',' screen_distance=%s',num2str(viewDistanceBottomTop*10))

%% Sending physical parameters to the edfs:
Eyelink('Message', sprintf('Screen_size_mm: %s', num2str(SCREENPHYSICALCOORDINATES)))
Eyelink('Message', sprintf('Screen_distance_mm: %s', num2str(viewDistanceBottomTop*10)))
Eyelink('Message', sprintf('Camera_position_mm: %s', num2str(DISTANCE_SCREEN_TRACKER*10)))

end

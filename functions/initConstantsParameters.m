
% INITCONSTANTSPARAMETERS this function defines all the constants and parameters of
% the program. Please note was can be changed, and what cannot, without
% breaking the program.
% The codes used to designate stimuli:
% stimuli are coded as a 4 digit number.
% 1st digit = stimulus type (1 = face; 2 = object; 3 = letter; 4 = false font)
% 2nd digit = stimulus orientation (1 = center; 2 = left; 3 = right)
% 3rd & 4th digits = stimulus id (1...20; for faces 1...10 is male, 11...20 is female)
% e.g., "1219" = 1 is face, 2 is left orientation and 19 is a female stimulus #19
% Duration is encoded by the first decimal so that 1219.1 has duration 0.5,
% 1219.2 has duration 1 s and 1219.3 has duration 1.5 s
function initConstantsParameters()
    
    disp('')
    disp('WELCOME TO initConstantsParameters')
    disp('')   
    %% Header
    % GOBAL CONSTANTS
    % -----------------------------------------------------
    % Text and messages
    global INSTRUCTIONS1 INSTRUCTIONS2 INSTRUCTIONS3 INSTRUCTIONS4 INSTRUCTIONS5 INSTRUCTIONS6 INSTRUCTIONS7 TRUE FALSE SAVING_MESSAGE TRIGGER_DURATION_EXCEEDED_WARNING
    global LOADING_MESSAGE  CLEAN_EXIT_MESSAGE  END_OF_EXPERIMENT_MESSAGE MINIBLOCK_TEXT END_OF_BLOCK_MESSAGE MEG_BREAK_MESSAGE
    global PRACTICE_START_MESSAGE EXPERIMET_START_MESSAGE NUM_OF_TRIALS_CALIBRATION DIAL_SENSITIVITY_FACTOR
    global FEEDBACK_MESSAGES FEEDBACK_MESSAGES_PRACTICE AUD_FEEDBACK_MESSAGE EYETRACKER_CALIBRATION_MESSAGE EYETRACKER_CALIBRATION_MESSAGE_BETWEENBLOCKS PRESS_SPACE PRESS_ANY_BUTTON fontType fontSize fontColor 
    global GENERAL_BREAK_MESSAGE CALIBRATION_START_MESSAGE END_OF_MINIBLOCK_MESSAGE RESTART_MESSAGE RESTARTBLOCK_OR_MINIBLOCK_MESSAGE RESTART_PRACTICE_MESSAGE PROGRESS_MESSAGE PROGRESS_MESSAGE_MEG RESP_ORDER_WARNING_MESSAGE INTROSPEC_QN_VIS INTROSPEC_QN_AUD
    % -----------------------------------------------------
    % Matrices info
    global EXPERIMENT_NAME
    global BEHAV_FILE_NAMING BEHAV_FILE_NAMING_WHOLE BEHAV_FILE_SUMMARY_NAMING EYETRACKER_FILE_NAMING TOBII_VALIDATION_LOG_FILE_NAMING TRIG_LOG_FILE_NAMING LPTTRIG_LOG_FILE_NAMING
    % -----------------------------------------------------
    % Timing parameters
    global JITTER_RANGE_MEAN JITTER_RANGE_MIN JITTER_RANGE_MAX END_WAIT STIM_DURATION TRIAL_DURATION
    % -----------------------------------------------------
    % Keys parameters
    global VIS_RESPONSE_KEY ValidationKey VIS_TARGET_KEY WRONG_KEY NO_KEY RESTART_KEY ABORT_KEY abortKey upKey downKey RightKey LeftKey MEGbreakKey PauseKey RestartKey YesKey 
    global oneKey twoKey threeKey fourKey spaceBar MINIBLOCK_RESTART_KEY BLOCK_RESTART_KEY
    global CALIBRATION_PITCH_FREQ HIGH_PITCH_FREQ LOW_PITCH_FREQ PITCH_DURATION HIGH_PITCH_KEY LOW_PITCH_KEY AUD_RESPONSE_KEY_HIGH AUD_RESPONSE_KEY_LOW
    % -----------------------------------------------------
    % Trials parameters
    global DEBUG FIXATION
    % -----------------------------------------------------
    % Screen parameters 
    global FRAME_WIDTH MAX_VISUAL_ANGEL VIEWING_DISTANCE FRAME_COLOR  viewDistance FIXATION_COLOR FIXATION_FONT_SIZE  DIAMOUT_FIXATION DIAMIN_FIXATION
    % -----------------------------------------------------
    % Annex folders and files
    global CODE_FOLDER FUNCTIONS_FOLDER TEMPORARY_FOLDER SECRET_FOLDER STIM_FOLDER DATA_FOLDER OBJECTS_R_FOL FALSES_R_FOL CHARS_R_FOL FACES_R_FOL
    global OBJECTS_FOLDER FALSES_FOLDER CHARS_FOLDER FACES_FOLDER OBJECTS_C_FOL OBJECTS_L_FOL FALSES_C_FOL FALSES_L_FOL CHARS_C_FOL CHARS_L_FOL ANIMAL_REWARD_FOL
    global FACES_C_FOL FACES_L_FOL FEMALE_FOLDER MALE_FOLDER FILE_POSTFIX PRACTICE_L_FOL PRACTICE_R_FOL PRACTICE_C_FOL FIXATION_FILE INSTRUCTIONS_FOLDER EXP_DATE
    % -----------------------------------------------------
    % Dummy variables
    global debugFactor
    % -----------------------------------------------------
    % Saving parameters
    global excelFormat excelFormatSummary

    % Practice
    global MinPracticeHits MaxPracticeHits MaxPracticeFalseAlarms MaxPracticeFalseAlarms_Irrelevant Practice_aud_accuracy_cutoff
    % Diverse
    global NO_TRIAL PRACTICE   
    
    
    %%  PARAMETERS THAT MAY BE ALTERED
    EXPERIMENT_NAME = 'ReconTime';
    BEHAV_FILE_NAMING = '_Beh_V1_RawDurR';
    BEHAV_FILE_NAMING_WHOLE = '_Beh_V1_RawDurWHOLE';
    BEHAV_FILE_SUMMARY_NAMING = '_Beh_V1_SumDur';
    LPTTRIG_LOG_FILE_NAMING = '_LPTTrigLog_V1_DurR';
    TRIG_LOG_FILE_NAMING = '_Beh_V1_TrigDurR';
    EYETRACKER_FILE_NAMING = '_ET_V1_DurR';
    TOBII_VALIDATION_LOG_FILE_NAMING = '_ET_V1_Valid_sum_DurR';
    FILE_POSTFIX = '*.png';
    %add date as a separate column 5 years rewind
    t=datenum(date);
    EXP_DATE=datestr(t);
    
    % Add a frame for the bebug mode to not mix things up:
    FRAME_WIDTH = 0; % 0 for delete
    if DEBUG FRAME_WIDTH = 1; end
    FRAME_COLOR = [39,241,44];

    % TIMING
    JITTER_RANGE_MEAN = 0.600;
    JITTER_RANGE_MIN = 0.400;
    JITTER_RANGE_MAX = 2.000;
    STIM_DURATION = [0.500 1.000 1.500]; % Planned duration in seconds. However, since every lab amy have a different refresh rate, we need to go as close as possible to it. So it will be actualized once we get the refresh rate:
    TRIAL_DURATION = 2.000; % Total trial duration in seconds, without jitter
    END_WAIT = 2.000; % time of "end of experiment" message (in s)

    % Define pitches in Hz and duration in sec
    HIGH_PITCH_FREQ = 1100;
    LOW_PITCH_FREQ = 1000;
    PITCH_DURATION = 0.084;

    % calibration parameters
    NUM_OF_TRIALS_CALIBRATION = 100;
    CALIBRATION_PITCH_FREQ = 800;
    DIAL_SENSITIVITY_FACTOR = 2;

    if DEBUG == 2 %fast debug
        STIM_DURATION = [6 12 18] * (1/60); % 1/60 to allow at least one frame to appear on screen
        TRIAL_DURATION = 24 * (1/60); % leaves 3 frames for fixation
        JITTER_RANGE_MIN = 8 * (1/60);
        JITTER_RANGE_MAX = 24 * (1/60);
        JITTER_RANGE_MEAN = ((JITTER_RANGE_MIN+JITTER_RANGE_MAX)/2) * (1/60);
        debugFactor = 20; % by how much to quicken the run
    end

    % TEXT
    fontType = 'David';
    fontSize = 50; % general text size, not target
    FIXATION_COLOR = [205 33 42];
    FIXATION_FONT_SIZE = 20;
    fontColor = 0; % black;

    % messages
    END_OF_EXPERIMENT_MESSAGE = 'The End. Thank You!';
    FIXATION = 'o';
    LOADING_MESSAGE = 'Loading...';
    SAVING_MESSAGE = 'Saving...';
    CLEAN_EXIT_MESSAGE = 'Program aborted by user!';
    MINIBLOCK_TEXT = 'Press When These Appear:';
    END_OF_MINIBLOCK_MESSAGE = 'End of miniblock %d out of %d.\n\n Press SPACE to continue...';
    END_OF_BLOCK_MESSAGE = 'End of block %d out of %d.\n\n Press SPACE to continue...';
    MEG_BREAK_MESSAGE = 'We are saving the data, the experiment will proceed \n\n as soon as we are ready. \n\n Please wait';
    EXPERIMET_START_MESSAGE = 'The experiment starts now.\n\n Press SPACE to continue...';
    CALIBRATION_START_MESSAGE = 'The calibration task starts now.\n\n Press SPACE to continue...';
    EYETRACKER_CALIBRATION_MESSAGE = 'Before we proceed, we need to calibrate the eyetracker.\n\n\n\n You will see a dot that will move to different locations on screen.\n\n Your task is to keep looking at the dot at all times.\n\n Try to avoid blinking as much as possible.\n\n\n Press SPACE to proceed to calibration...';
    EYETRACKER_CALIBRATION_MESSAGE_BETWEENBLOCKS = 'Before we proceed, we need to calibrate the eyetracker.\n\n\n Press SPACE to proceed to calibration...';
    GENERAL_BREAK_MESSAGE = 'Feel free to take a break now.\n\n Press SPACE to continue...';
    FEEDBACK_MESSAGES = {'Nice job! Keep it up!','Warning: You are missing targets.','Warning: You are selecting incorrect targets.'};
    FEEDBACK_MESSAGES_PRACTICE = {'Nice job! Keep it up!','Warning: You missed x targets.','Warning: You selected x incorrect targets.'};
    AUD_FEEDBACK_MESSAGE = '\n\n\n\n Your score on the auditory task was: %s';
    RESP_ORDER_WARNING_MESSAGE = 'Please remember to \n\n respond to the visual first \n\n and to the auditory task second';

    INTROSPEC_QN_VIS = 'Visual task duration?';
    INTROSPEC_QN_AUD = 'Auditory task duration?';

    PRESS_SPACE ='\nPress SPACE to continue...\n';
    PRESS_ANY_BUTTON ='\nPress any button to continue...\n';

    TRIGGER_DURATION_EXCEEDED_WARNING = 'The duration of the processes before flipping the photodiode back to black was too long. \n The photodiode square will be on for longer!!!';
    RESTART_MESSAGE='Are you sure you want to restart?';
    RESTARTBLOCK_OR_MINIBLOCK_MESSAGE = 'Do you want to restart the block or the miniblock?\n Press M to restart the miniBlock \Press B to restart the block';
    RESTART_PRACTICE_MESSAGE='\n\n It is recommended to repeat the practice.\n\n\n Experimenter: Press R to repeat or Y to proceed.';
    PROGRESS_MESSAGE = 'Congratulations! You completed a miniblock. Well Done! \n\n Press SPACE to continue...'; 
    
    PROGRESS_MESSAGE_MEG = 'You completed a miniblock.';
    VIEWING_DISTANCE = viewDistance; % in centimeters
    MAX_VISUAL_ANGEL = [6,6]; % in degrees | "on a rectangular aperture at an average visual angle of 6? by 4?"

    % Size of the fixation in DVA:
    DIAMOUT_FIXATION = 0.6; % diameter of outer circle (degrees)
    DIAMIN_FIXATION = 0.1; % diameter of inner circle (degrees)
    
    % Format of saved data:
    excelFormat = '.csv';
    excelFormatSummary = '.xls';
    
    % Response params
    KbName('UnifyKeyNames');
    upKey         =  KbName('UpArrow');
    downKey       =  KbName('DownArrow');
    RightKey      =  KbName('RightArrow');
    LeftKey       =  KbName('LeftArrow');
    PauseKey      =  KbName('Q');   
    RestartKey    =  KbName('R'); 
    abortKey      =  KbName('ESCAPE'); % ESC aborts experiment
    MEGbreakKey   =  KbName('F5');
    YesKey        =  KbName('Y');
    spaceBar      =  KbName('SPACE');
    oneKey        =  KbName('1!');
    twoKey        =  KbName('2@');
    threeKey      =  KbName('3#');
    fourKey       =  KbName('4$');
    MINIBLOCK_RESTART_KEY = KbName('M');
    BLOCK_RESTART_KEY = KbName('B');
    VIS_RESPONSE_KEY = spaceBar;
    AUD_RESPONSE_KEY_HIGH = twoKey;
    AUD_RESPONSE_KEY_LOW = oneKey;

    ValidationKey = KbName('V');

    
    %%  PARAMETERS THAT SHOULD NOT BE ALTERED, BUT SHOULD BE USED AS REFERENCE
    
    % Folders
    DATA_FOLDER = 'data';
    CODE_FOLDER = 'code';
    FUNCTIONS_FOLDER = 'functions';
    TEMPORARY_FOLDER = 'temporary';
    SECRET_FOLDER = 'DONT OPEN! DEAD INSIDE!';
    
    % program codes
    ABORT_KEY = 4;
    RESTART_KEY = 3;
    WRONG_KEY = 2;
    VIS_TARGET_KEY = 1; % to mark if up was pressed
    NO_KEY = 0;
    HIGH_PITCH_KEY = HIGH_PITCH_FREQ;
    LOW_PITCH_KEY = LOW_PITCH_FREQ;

    TRUE = 1;
    FALSE = 0;

    NO_TRIAL = nan;
    % instruction slides addresses
    INSTRUCTIONS1 = 'instructions1.png';
    INSTRUCTIONS2 = 'instructions2.png';
    INSTRUCTIONS3 = 'instructions3.png';
    INSTRUCTIONS4 = 'instructions4.png';
    INSTRUCTIONS5 = 'instructions5.png';
    INSTRUCTIONS6 = 'instructions6.png';
    INSTRUCTIONS7 = 'instructions7.png';

    % stimuli folders addresses
    STIM_FOLDER = 'stimuli';
    FACES_FOLDER = 'faces';
    CHARS_FOLDER = 'chars';
    FALSES_FOLDER = 'falses';
    OBJECTS_FOLDER = 'objects';
    MALE_FOLDER = 'male';
    FEMALE_FOLDER = 'female';
    FIXATION_FILE = 'fixation.png';
    INSTRUCTIONS_FOLDER = 'instructions';

    % stimuli folders for each type of stimuli by left, right and center
    FACES_L_FOL = fullfile(pwd,STIM_FOLDER,FACES_FOLDER,'left');
    FACES_C_FOL = fullfile(pwd,STIM_FOLDER,FACES_FOLDER,'center');
    FACES_R_FOL = fullfile(pwd,STIM_FOLDER,FACES_FOLDER,'right');
    CHARS_L_FOL = fullfile(pwd,STIM_FOLDER,CHARS_FOLDER,'left');
    CHARS_C_FOL = fullfile(pwd,STIM_FOLDER,CHARS_FOLDER,'center');
    CHARS_R_FOL = fullfile(pwd,STIM_FOLDER,CHARS_FOLDER,'right');
    FALSES_L_FOL = fullfile(pwd,STIM_FOLDER,FALSES_FOLDER,'left');
    FALSES_C_FOL = fullfile(pwd,STIM_FOLDER,FALSES_FOLDER,'center');
    FALSES_R_FOL = fullfile(pwd,STIM_FOLDER,FALSES_FOLDER,'right');
    OBJECTS_L_FOL = fullfile(pwd,STIM_FOLDER,OBJECTS_FOLDER,'left');
    OBJECTS_C_FOL = fullfile(pwd,STIM_FOLDER,OBJECTS_FOLDER,'center');
    OBJECTS_R_FOL = fullfile(pwd,STIM_FOLDER,OBJECTS_FOLDER,'right');
    
    ANIMAL_REWARD_FOL = fullfile(pwd,'Pictures_between_miniblocks_exp1');

    %% Practice parameters :
    PRACTICE_START_MESSAGE = 'The practice starts now.\n\n Press SPACE to continue...';

    PRACTICE = 8000;
    PRACTICE_L_FOL = fullfile(pwd,STIM_FOLDER,'practice','left');
    PRACTICE_R_FOL = fullfile(pwd,STIM_FOLDER,'practice','right');
    PRACTICE_C_FOL = fullfile(pwd,STIM_FOLDER,'practice','center');
    
    MinPracticeHits=4;
    MaxPracticeHits=6;
    MaxPracticeFalseAlarms=2;
    MaxPracticeFalseAlarms_Irrelevant=0;
    Practice_aud_accuracy_cutoff=0.9;        
end % end of initConstantParameters function

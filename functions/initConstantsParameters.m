
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
    global INSTRUCTIONS1 INSTRUCTIONS2 INSTRUCTIONS3 INSTRUCTIONS4 INSTRUCTIONS5 INSTRUCTIONS6 INSTRUCTIONS7 TRUE FALSE SAVING_MESSAGE
    global LOADING_MESSAGE  CLEAN_EXIT_MESSAGE  END_OF_EXPERIMENT_MESSAGE MINIBLOCK_TEXT END_OF_BLOCK_MESSAGE MEG_BREAK_MESSAGE
    global EXPERIMET_START_MESSAGE NUM_OF_TRIALS_CALIBRATION DIAL_SENSITIVITY_FACTOR RESPONSE_BOX
    global AUD_FEEDBACK_MESSAGE EYETRACKER_CALIBRATION_MESSAGE EYETRACKER_CALIBRATION_MESSAGE_BETWEENBLOCKS PRESS_SPACE fontType fontSize fontColor 
    global GENERAL_BREAK_MESSAGE CALIBRATION_START_MESSAGE END_OF_MINIBLOCK_MESSAGE RESTART_MESSAGE RESP_ORDER_WARNING_MESSAGE INTROSPEC_QN_VIS INTROSPEC_QN_AUD
    % -----------------------------------------------------
    % Matrices info
    global EXPERIMENT_NAME
    % -----------------------------------------------------
    % Timing parameters
    global JITTER_RANGE_MEAN JITTER_RANGE_MIN JITTER_RANGE_MAX END_WAIT STIM_DURATION TRIAL_DURATION FRAME_ANTICIPATION
    % -----------------------------------------------------
    % Keys parameters
    global VIS_RESPONSE_KEY CalibrationKey ValidationKey VIS_TARGET_KEY WRONG_KEY NO_KEY RESTART_KEY ABORT_KEY abortKey upKey downKey RightKey LeftKey MEGbreakKey PauseKey RestartKey YesKey 
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
    global CODE_FOLDER FUNCTIONS_FOLDER DATA_FOLDER FILE_POSTFIX INSTRUCTIONS_FOLDER EXP_DATE
    % -----------------------------------------------------
    % Dummy variables
    global debugFactor
    % -----------------------------------------------------
    % Saving parameters
    global excelFormat excelFormatSummary
    % Diverse
    global NO_TRIAL
    
    
    %%  PARAMETERS THAT MAY BE ALTERED
    EXPERIMENT_NAME = 'ReconTime';
    FILE_POSTFIX = '*.png';
    %add date as a separate column 5 years rewind
    t=datenum(date);
    EXP_DATE=datestr(t);
    
    % Add a frame for the bebug mode to not mix things up:
    FRAME_WIDTH = 0; % 0 for delete
    if DEBUG FRAME_WIDTH = 1; end
    FRAME_COLOR = [39,241,44];

    % TIMING
    TRIAL_DURATION = 2.000; % Total trial duration in seconds, without jitter
    END_WAIT = 2.000; % time of "end of experiment" message (in s)
    FRAME_ANTICIPATION = 0.5; % used for excat timing in PTB

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
    EYETRACKER_CALIBRATION_MESSAGE = 'Press SPACE to proceed to perform the calibration \n\n Press C to skip the calibration';
    EYETRACKER_CALIBRATION_MESSAGE_BETWEENBLOCKS = 'Before we proceed, we need to calibrate the eyetracker.\n\n\n Press SPACE to proceed to calibration...';
    GENERAL_BREAK_MESSAGE = 'Feel free to take a break now.\n\n Press SPACE to continue...';
    AUD_FEEDBACK_MESSAGE = '\n\n\n\n Your score on the auditory task was: %s';
    RESP_ORDER_WARNING_MESSAGE = 'Please remember to \n\n respond to the visual first \n\n and to the auditory task second';

    INTROSPEC_QN_VIS = 'Visual task duration?';
    INTROSPEC_QN_AUD = 'Auditory task duration?';

    PRESS_SPACE ='\nPress SPACE to continue...\n';
    RESTART_MESSAGE='Are you sure you want to restart?';

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
    CalibrationKey = KbName('C');
    upKey         =  KbName('UpArrow');
    downKey       =  KbName('DownArrow');
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

    if RESPONSE_BOX
        RightKey =  KbName('H');
        LeftKey  =  KbName('G');
        VIS_RESPONSE_KEY = KbName('B');
        AUD_RESPONSE_KEY_HIGH = KbName('A');
        AUD_RESPONSE_KEY_LOW = KbName('C');
        ValidationKey = KbName('H');
        spaceBar =  KbName('D');

    else
        RightKey =  KbName('RightArrow');
        LeftKey  =  KbName('LeftArrow');
        VIS_RESPONSE_KEY = spaceBar;
        AUD_RESPONSE_KEY_HIGH = twoKey;
        AUD_RESPONSE_KEY_LOW = oneKey;
        ValidationKey = KbName('V');
    end

    
    %%  PARAMETERS THAT SHOULD NOT BE ALTERED, BUT SHOULD BE USED AS REFERENCE
    
    % Folders
    DATA_FOLDER = 'data';
    CODE_FOLDER = 'code';
    FUNCTIONS_FOLDER = 'functions';
    
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
    INSTRUCTIONS_FOLDER = 'instructions';
    INSTRUCTIONS1 = 'instructions1.png';
    INSTRUCTIONS2 = 'instructions2.png';
    INSTRUCTIONS3 = 'instructions3.png';
    INSTRUCTIONS4 = 'instructions4.png';
    INSTRUCTIONS5 = 'instructions5.png';
    INSTRUCTIONS6 = 'instructions6.png';
    INSTRUCTIONS7 = 'instructions7.png';

end % end of initConstantParameters function

function [] = initPsychtooblox()
    global DEBUG ScreenHeight stimSizeHeight ScreenWidth refRate screenScaler fontType fontSize fontColor text gray w REF_RATE_OPTIMAL center
    global WINDOW_RESOLUTION debugFactor NO_FULLSCREEN  VIEWING_DISTANCE MAX_VISUAL_ANGEL STIM_DURATION TRIAL_DURATION ppd
    global padhandle
    disp('WELCOME to initPsychtooblox')
    
    %% Set preferences and open graphic window:
    % Set psychtoolbox default to 2
    PsychDefaultSetup(2);
    % Set teh screen preferences:
    try
        if DEBUG 
            % In debug mode, skip the sync test, as it crashes on low perf
            % laptopts
            Screen('Preference', 'SkipSyncTests', 1); 

        else
            % For the real experiment, do not skip the sync test
            Screen('Preference', 'SkipSyncTests', 1); 
        end
    catch
        % Trying a second time just in case something went wrong the first
        % try
        if DEBUG 
            Screen('Preference', 'SkipSyncTests', 1); 
        else
            Screen('Preference', 'SkipSyncTests', 1); 
        end
    end
    Screen('Preference', 'TextRenderer', 1);
    Screen('Preference', 'VisualDebugLevel', 4);
    % Get the different screens:
    screens = Screen('Screens');
    % Use the last screen preferentially:
    screenNumber = max(screens);
    % Set the gray:
    gray = [125,125,125];

    % Open a graphic window:
    try
        if NO_FULLSCREEN 
            % For debugging purposes, we can run the experiment with not
            % full screen
            [w, wRect] = Screen('OpenWindow',screenNumber, gray, WINDOW_RESOLUTION); 
        else
            % But here again, for  the real experiment go for full screen
            [w, wRect]  =  Screen('OpenWindow',screenNumber, gray); 
        end
    catch
        % Try again in case something went wrong
        if NO_FULLSCREEN 
            [w, wRect] = Screen('OpenWindow',screenNumber, gray, WINDOW_RESOLUTION); 
        else
            [w, wRect]  =  Screen('OpenWindow',screenNumber, gray); 
        end
    end
    
    % Hide the cursor:
    if ~NO_FULLSCREEN
        HideCursor;
    end
        % this enables us to use the alpha transparency
    Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA', [gray 128]);

    % Setting priority to max, such that the experiment has full priority
    % on the CPU:
    priorityLevel=MaxPriority(w);
    Priority(priorityLevel);
    
    %% Initialize sound parameters
    InitializePsychSound(1);
    device = [];
    mode = 1;
    reqlatencyclass = 1;
    freq = [];
    channels = 2;
    padhandle = PsychPortAudio('Open', device, mode, reqlatencyclass, freq, channels);
    PsychPortAudio('Volume', padhandle, 0.2);

    %% Derive relevant parameters from setup information:
    % Extract screen parameters in pixels:
    ScreenWidth     =  wRect(3);
    ScreenHeight    =  wRect(4);
    center          =  [ScreenWidth/2; ScreenHeight/2];
    % Get hte refresh rate:
    hz = Screen('NominalFrameRate', w);
    disp(hz)
    refRate = hz.^(-1);
    if DEBUG == 2 
        refRate = refRate / debugFactor ;
    end
    % If we are not in debug mode and that the screen refresh rate does not
    % match the expected one, abort:
    if ~DEBUG && round(hz) ~= REF_RATE_OPTIMAL
        sca;
        error("Error. \nThe refresh rate is %d and not equal to %d hz. Make sure you set your screen refresh rate to match the latter!", round(hz), REF_RATE_OPTIMAL)
    end
    
    % We can now actualize the stimuli duration:
    % It needs to be a multiple of the frame rate:
    DurationCoefficients = round((STIM_DURATION )/refRate);
    STIM_DURATION = DurationCoefficients*refRate;
    
    % We can now actualize the trial duration:
    % It needs to be a multiple of the frame rate:
    DurationCoefficients_trial = round((TRIAL_DURATION )/refRate);
    TRIAL_DURATION = DurationCoefficients_trial*refRate;
    
    screenScaler = ScreenWidth/1920; % allows scaling so that with smaller screens, objects will be of smaller sizes (1 = Full HD)

    % Stimuli size by visual angle, based on viewing distance and physical
    % size of screen (MAKE SURE YOU INPUT THESE IN)
    stimSizeHeight = getVisualAngel(VIEWING_DISTANCE,MAX_VISUAL_ANGEL(1)); % in px

    % Compute the pixel per degree of visual angle:
    ppd = getVisualAngel(VIEWING_DISTANCE,1); % pixel per degree

    %% Set text params

    Screen('TextFont',w, fontType);
    Screen('TextStyle', w, 0);
    Screen('TextSize', w, round(fontSize*screenScaler));
    text.Color = fontColor; %black
    
    %% PRELIMINTY PREPATATION
    % check for Opengl compatibility, abort otherwise
    AssertOpenGL;

    rng('default');
    % Reseed the random-number generator for each expt.
    rng('Shuffle');

    % Do dummy calls to GetSecs, WaitSecs, KbCheck
    KbCheck;
    WaitSecs(0.1);
    GetSecs;
    
    % Listening for keyboard inputs:
    if ~NO_FULLSCREEN
        ListenChar(2);
    end

end

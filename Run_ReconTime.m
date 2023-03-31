%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear all;

% Hardware parameters:
global subjectNum TRUE FALSE refRate viewDistance compKbDevice
global el EYE_TRACKER CalibrationKey spaceBar EYETRACKER_CALIBRATION_MESSAGE NO_PRACTICE session LAB_ID subID task_type
global TRIAL_DURATION DATA_FOLDER NUM_OF_TRIALS_CALIBRATION FRAME_ANTICIPATION PHOTODIODE DIOD_DURATION SHOW_INSTRUCTIONS
global LOADING_MESSAGE CLEAN_EXIT_MESSAGE CALIBRATION_START_MESSAGE SAVING_MESSAGE END_OF_EXPERIMENT_MESSAGE
global END_OF_MINIBLOCK_MESSAGE END_OF_BLOCK_MESSAGE EXPERIMET_START_MESSAGE
global ABORTED RESTART_KEY NO_KEY ABORT_KEY VIS_TARGET_KEY LOW_PITCH_KEY HIGH_PITCH_KEY
global HIGH_PITCH_FREQ LOW_PITCH_FREQ PITCH_DURATION RESP_ORDER_WARNING_MESSAGE padhandle

% prompt user for information
subjectNum = input('Subject number [101-199, default 101]: '); if isempty(subjectNum); subjectNum = 101; end
session = input('Session number [1-6, default 1]: '); if isempty(session); session = 1; end
viewDistance = input('View Distance in cm [default 69.5]: '); if isempty(viewDistance); viewDistance = 69.5; end
introspection = input('Introspective task [0: PRP only, 1: introspection, default 0]: '); if isempty(introspection); introspection = 0; end
if introspection
    task_type = 'introspection';
else
    task_type = 'prp';
end

% Add functions folder to path (when we separate all functions)
function_folder = [pwd,filesep,'functions\'];
addpath(function_folder)

% initializing experimental parameters 
initRuntimeParameters
initConstantsParameters(); % defines all constants and initilizes parameters of the program

% Logging everything that is printed into the command window! If the
% log file already exist, delete it, otherwise the logs will be
% appended and it won't be specific to that participant. Moreover, the
% logs are always saved
dfile ='log_recon_time.txt';
if exist(dfile, 'file') ; delete(dfile); end
Str = CmdWinTool('getText');
dlmwrite(dfile,Str,'delimiter','');
% To get different seeds for matlab randomization functions.
rng('shuffle');

%% check if participant and session exists already

% Create the subject ID by combining the lab ID with the subject name:
subID = sprintf('%s%d', LAB_ID, subjectNum);

SubSesFolder = fullfile(pwd,DATA_FOLDER,['sub-',subID],['ses-',num2str(session)]);
ExistFlag = exist(SubSesFolder,'dir');
if ExistFlag
    warning ('This participant number and session was already attributed!')
    proceedInput = questdlg({'This participant number and session was already attributed!', 'Are you sure you want to proceed?'},'RestartPrompt','yes','no','no');
    if strcmp(proceedInput,'no')
        error('Program aborted by user')
    end
end

% Initializing PTB:
initPsychtooblox(); % initializes psychtoolbox window at correct resolution and refresh rate

%% Setup the trial matrix and log:
% open trial matrix (form Experiment 1) and add auditory conditions
MatFolderName = [pwd,filesep,'TrialMatrices\'];
TableName = ['sub-',subID,'_task-', task_type,'_trials.csv'];
trial_mat = readtable(fullfile(MatFolderName, TableName));

%% Load and prepare the visual and audio stimuli:
showMessage(LOADING_MESSAGE);
loadStimuli() % visual
[high_pitch_buff, low_pitch_buff] = init_audio_pitches(PITCH_DURATION, HIGH_PITCH_FREQ,  LOW_PITCH_FREQ); % auditory

%% Instructions and practice:
% displays instructions
if SHOW_INSTRUCTIONS
    Instructions(task_type);
end
% calibration task
if strcmp(task_type, 'introspection')
    showMessage(CALIBRATION_START_MESSAGE);
    KbWait(compKbDevice,3);
    handle = PsychPowerMate('Open'); % open dial
    cali_log = calibration(NUM_OF_TRIALS_CALIBRATION);
    saveTable(cali_log,'calibration', 1)
end

%% Main experimental loop:
try
    
    ABORTED = 0;
    
    %% save everything from command window
    Str = CmdWinTool('getText');
    dlmwrite(dfile,Str,'delimiter','');
    
    
    %%  Experiment
    % Experiment Prep
    previous_miniblock = 0;
    warning_response_order = 0;
    start_message_flag = FALSE;
    showFixation('PhotodiodeOff');
    
    %% Block loop:
    blks = unique(trial_mat.block);
    if NO_PRACTICE
        blk = 1;
    else
        blk = trial_mat.block(1);
    end
    
    while blk <= blks(end)      
        % in the very first trial of the actual experiment show start message
        if blk == 1
            showMessage(EXPERIMET_START_MESSAGE);
            KbWait(compKbDevice,3);
            start_message_flag = TRUE;
        end

        % Initialize the eyetracker with the block number and run the
        % calibration:
        if EYE_TRACKER
            % Initialize the eyetracker:
            initEyetracker(subID, blk);
            % Show the calibration message to give the option to perform 
            % the eyetracker calibration if needed:
            showMessage(EYETRACKER_CALIBRATION_MESSAGE);
            CorrectKey = 0; % Setting the CorrectKey to 0 to initiate the loop
            while ~CorrectKey % As long as a non-accepted key is pressed, keep on asking
                [~, CalibrationResp, ~] =KbWait(compKbDevice,3);
                if CalibrationResp(CalibrationKey)
                    % Run the calibration:
                    EyelinkDoTrackerSetup(el);
                    CorrectKey = 1;
                elseif CalibrationResp(spaceBar)
                    CorrectKey = 1;
                end
            end
            % Starting the recording
            Eyelink('StartRecording');
            % Wait for the recording to have started:
            WaitSecs(0.1);
        end
        
        % Extract the trial and log of this block only:
        blk_mat = trial_mat(trial_mat.block == blk, :);
        % Extract the task from this block:
        task = char(blk_mat.task(1));
        
        % Add the columns for logging:
        blk_mat = prepare_log(blk_mat);
        log_hasInputs_vis = nan(1,length(trial_mat.trial));

        % Check whether this block is a practice or not:
        is_practice = blk_mat.is_practice(1);
        if is_practice
            % Extract from table the practice type:
            practice_type = blk_mat.task(1);
            practice_start_msg = get_practice_instructions(practice_type);
            showMessage(practice_start_msg);
            KbWait(compKbDevice,3);

        else
            % Otherwise, show the target screen:
            practice_type = 'not_practice';
        end
       
        % Show the target screen at the beginning of each block (expect during auditory practice):
        if ~strcmp(practice_type, 'auditory')
            blk_mat.TargetScreenOnset(1) = showMiniBlockBeginScreen(blk_mat, 1);
            KbWait(compKbDevice,3,WaitSecs(0)+5);
        end

        % Wait a random amount of time and show fixation:
        fixOnset = showFixation('PhotodiodeOff'); % 1
        WaitSecs(rand*2);
        
        %% Trials loop:
        for tr = 1:length(blk_mat.trial)
            % flags needs to be initialized
            fixShown = FALSE;
            pitchPlayed = FALSE;
            jitterLogged = FALSE;
            hasInput_vis = FALSE;
            hasInput_aud = FALSE;
            
            % other variables that need to be reset for every trial
            hasInputs = 0; % input flag, marks if participant already replied
            PauseTime = 0; % If the experiment is paused, the duration of the pause is stored to account for it.
            
            % get texture pointer
            vis_stim_id = blk_mat.identity{tr};
            orientation = blk_mat.orientation{tr};
            texture_ptr = getPointer(vis_stim_id, orientation);
            blk_mat.texture(tr) = texture_ptr;
            
            % show stimulus
            if strcmp(practice_type, 'auditory')
                blk_mat.vis_stim_time(tr) = showFixation('PhotodiodeOn'); % Do not show the
                DiodFrame = 0;
            else
                blk_mat.vis_stim_time(tr) = showStimuli(texture_ptr);
                DiodFrame = 0;
            end

            % Sending response trigger for the eyetracker
            if EYE_TRACKER
                trigger_str = get_et_trigger('vis_onset', blk_mat.task_relevance{tr}, ...
                    blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                    blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                Eyelink('Message',trigger_str);
            end
            
            % I then set a frame counter. The flip of the stimulus
            % presentation is frame 0. It is already the previous frame because it already occured:
            PreviousFrame = 0;
            % I then set a frame index. It is the same as the previous
            % frame for now
            FrameIndex = PreviousFrame;
            
            %--------------------------------------------------------
            
            %% TIME LOOP
            elapsedTime = 0;
            
            % for introspective trial the jitter is moved out of the time loop
            % and comes after the questions
            if strcmp(task, 'introspection')
                total_trial_duration = TRIAL_DURATION - (refRate*FRAME_ANTICIPATION);
            else
                total_trial_duration = TRIAL_DURATION - (refRate*FRAME_ANTICIPATION) + blk_mat.stim_jit(tr);
            end
            
            while elapsedTime < total_trial_duration
                
                %% Play audio stimulus
                if elapsedTime >= (blk_mat.onset_SOA(tr) - refRate*FRAME_ANTICIPATION) && ...
                        pitchPlayed == FALSE && ~strcmp(practice_type, 'visual')
                    % Select the right buffer
                    if blk_mat.pitch(tr) == 1000
                        pitch_buff = low_pitch_buff;
                    elseif blk_mat.pitch(tr) == 1100
                        pitch_buff = high_pitch_buff;
                    end
                    % Load the buffer
                    PsychPortAudio('FillBuffer', padhandle, pitch_buff);
                    % Play the buffer
                    audio_start = PsychPortAudio('Start',padhandle, 1, 0);
                    % Get the buffer time stamp:
                    audio_start = GetSecs();
                    % Sending response trigger for the eyetracker
                    if EYE_TRACKER
                        trigger_str = get_et_trigger('audio_onset', blk_mat.task_relevance{tr}, ...
                            blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                            blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                        Eyelink('Message',trigger_str);
                    end
                    blk_mat.aud_stim_time(tr) = audio_start;
                    blk_mat.aud_stim_buff(tr) = pitch_buff;
                    pitchPlayed = TRUE;
                end
                
                %% Get response:
                if hasInputs < 2
                    % Ge the response:
                    [key,Resp_Time] = getInput();
                    
                    % Handling the response:
                    % If the participant pressed a key that is different 
                    % to the one of the previous iteration:
                    if key ~= NO_KEY && key ~= blk_mat.trial_first_button_press(tr) 
                        
                        % Sending response trigger for the eyetracker
                        if EYE_TRACKER
                            trigger_str = get_et_trigger('response', blk_mat.task_relevance{tr}, ...
                                blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                                blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                            Eyelink('Message',trigger_str);
                        end

                        if key == ABORT_KEY % If the experiment was aborted:
                            ABORTED = 1;
                            error(CLEAN_EXIT_MESSAGE);
                        end

                        % logging reaction
                        hasInputs = hasInputs + 1;
                        log_hasInputs_vis(tr) = hasInputs;
                        
                        % Log the response received:
                        if  hasInputs == 1
                            blk_mat.trial_first_button_press(tr) = key;
                        else
                            blk_mat.trial_second_button_press(tr) = key;
                        end
                        
                        % store RT for visual task
                        if key == VIS_TARGET_KEY && hasInput_vis == FALSE % taget key was pressed
                            blk_mat.time_of_resp_vis(tr) =  Resp_Time;
                            blk_mat.has_repsonse_vis(tr) = 1;
                            hasInput_vis = TRUE;
                            % store RT for auditory task
                        elseif (key == LOW_PITCH_KEY || key == HIGH_PITCH_KEY) && hasInput_aud == FALSE % auditory key was pressed
                            blk_mat.time_of_resp_aud(tr) =  Resp_Time;
                            hasInput_aud = TRUE;
                        elseif  ~ismember(key,[VIS_TARGET_KEY, LOW_PITCH_KEY, HIGH_PITCH_KEY])
                            blk_mat.wrong_key(tr) =  key;
                            blk_mat.wrong_key_timestemp(tr) =  Resp_Time;
                        end
                    end
                end
                                
                %% Inter stimulus interval
                % Present fixation
                if elapsedTime >= ((blk_mat.duration(tr)) - refRate*FRAME_ANTICIPATION) && fixShown == FALSE
                    fix_time = showFixation('PhotodiodeOn');
                    DiodFrame = CurrentFrame;
                    % Sending response trigger for the eyetracker
                    if EYE_TRACKER
                        trigger_str = get_et_trigger('fixation_onset', blk_mat.task_relevance{tr}, ...
                                blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                                blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                        Eyelink('Message',trigger_str);
                    end
                    % log fixation in journal
                    blk_mat.fix_time(tr) = fix_time;
                    fixShown = TRUE;
                end
                
                % Present jitter
                if elapsedTime > TRIAL_DURATION  - refRate*FRAME_ANTICIPATION && jitterLogged == FALSE
                    JitOnset = showFixation('PhotodiodeOn');
                    DiodFrame = CurrentFrame;
                    % Sending response trigger for the eyetracker
                    if EYE_TRACKER
                        trigger_str = get_et_trigger('jitter_onset', blk_mat.task_relevance{tr}, ...
                                blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                                blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                        Eyelink('Message',trigger_str);
                    end
                    
                    % log jitter started
                    blk_mat.JitOnset(tr) = JitOnset;
                    jitterLogged = TRUE;
                end
                
                % Updating clock:
                elapsedTime = GetSecs - blk_mat.vis_stim_time(tr);
                
                % Updating the frame counter:
                CurrentFrame = floor(elapsedTime/refRate);

                % Check if a new frame started:
                if CurrentFrame > PreviousFrame
                    FrameIndex = FrameIndex +1;

                    % turn photodiode off again after diod duration
                    if PHOTODIODE && (CurrentFrame - DiodFrame == DIOD_DURATION - 1)
                        turnPhotoTrigger('off');
                    end
                    PreviousFrame = CurrentFrame;
                end
            end
            blk_mat.trial_end(tr) = GetSecs;
            
            %% End of trial
            
            % check order of responses
            if blk_mat.trial_first_button_press(tr) >= 1000 && blk_mat.trial_second_button_press(tr) == 1
                warning_response_order = 1;
            end
            
            if strcmp(task, 'introspection')
                WaitSecs(0.2);
                
                % introspective question 1 (RT visual task)
                introspec_question = 'vis';
                blk_mat.iRT_vis(tr) = run_dial(introspec_question);
                
                showFixation('PhotodiodeOn');
                WaitSecs(0.1);
                
                % introspective question 2 (RT auditory task)
                introspec_question = 'aud';
                blk_mat.iRT_aud(tr) = run_dial(introspec_question);
                
                showFixation('PhotodiodeOn');
                WaitSecs(blk_mat.stim_jit(tr));
            end
            
            if(key==RESTART_KEY)
                break
            end
        end  % End of trial loop
        
        % Save the data of this block:
        saveTable(blk_mat, task, blk);
        % Save the eyetracker data:
        if EYE_TRACKER
            saveEyetracker(task, blk);
        end
        
        % Append the block log to the overall log:
        if blk == 1 
            log_all = blk_mat;
        elseif ~blk_mat.is_practice
            log_all = [log_all; blk_mat];  % Not the most efficient but it is in a non critical part
        end
        
        % order of responses reminder (if needed)
        if warning_response_order == 1
            showMessage(RESP_ORDER_WARNING_MESSAGE);
            WaitSecs(3);
            warning_response_order = 0;
        end
        
        % Every 4 blocks, there is a longer break:
        if ~is_practice
            if mod(blk, 4) ==0
                block_message = sprintf(END_OF_BLOCK_MESSAGE, blk/4, trial_mat.block(end)/4);
            else
                block_message = sprintf(END_OF_MINIBLOCK_MESSAGE, blk, trial_mat.block(end));
            end
            showMessage(block_message);
            KbWait(compKbDevice,3);
        end

        if is_practice
            blk_continue = get_practice_feedback(blk_mat, practice_type);
            blk = blk + blk_continue;
        else
            blk = blk + 1;
        end

    end  % End of block loop
    
    %% End of experiment
    % Save the whole table:
    saveTable(log_all, task, "all");
    % Save the code:
    saveCode(task);
    % Letting the participant that it is over:
    showMessage(END_OF_EXPERIMENT_MESSAGE);
    WaitSecs(2);
    
    showMessage(SAVING_MESSAGE);
    % Mark the time of saving onset
    ttime = GetSecs;
    
    % compute performances of tasks
    [log_all, performance_struct] = compute_performance(log_all);
    
    % save everything from command window
    Str = CmdWinTool('getText');
    dlmwrite(dfile,Str,'delimiter','');
    
    % Terminating teh experiment:
    safeExit()
catch e
    % Save the data:
    try
        % Save the beh data:
        saveTable(blk_mat, task, blk);
        % Save the eyetracker data:
        if EYE_TRACKER
            saveEyetracker(task, blk);
        end
        % If the log all already exists, save it as well:
        if exist('log_all', 'var')
            [log_all, performance_struct] = compute_performance(log_all);
            saveTable(log_all, task, "all");
        end
        % Save the code:
        saveCode(task);
        safeExit()
    catch
        warning('-----  Data could not be saved!  ------')
        safeExit()
        rethrow(e);
    end
end
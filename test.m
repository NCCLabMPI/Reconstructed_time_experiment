%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear;

% Hardware parameters:
global TRUE FALSE refRate viewDistance compKbDevice
global EYE_TRACKER NO_PRACTICE introspec session LAB_ID subID
global TRIAL_DURATION RUN_PRACTICE DATA_FOLDER NUM_OF_TRIALS_CALIBRATION
global LOADING_MESSAGE RESTART_MESSAGE CLEAN_EXIT_MESSAGE CALIBRATION_START_MESSAGE SAVING_MESSAGE END_OF_EXPERIMENT_MESSAGE RESTARTBLOCK_OR_MINIBLOCK_MESSAGE
global END_OF_MINIBLOCK_MESSAGE END_OF_BLOCK_MESSAGE EXPERIMET_START_MESSAGE
global YesKey ABORTED RESTART_KEY NO_KEY ABORT_KEY VIS_TARGET_KEY LOW_PITCH_KEY HIGH_PITCH_KEY
global HIGH_PITCH_FREQ LOW_PITCH_FREQ PITCH_DURATION RESP_ORDER_WARNING_MESSAGE padhandle


% prompt user for information
subjectNum = input('Subject number [101-199, default 101]: '); if isempty(subjectNum); subjectNum = 101; end
session = input('Session number [1-6, default 1]: '); if isempty(session); session = 1; end
viewDistance = input('View Distance in cm [default 60]: '); if isempty(viewDistance); viewDistance = 60; end

%% check if participant and session exists already
if introspec
    session_type = 'Introspec';
else
    session_type = 'Bev';
end
SubSesFolder = fullfile(pwd,DATA_FOLDER,['sub-',num2str(subjectNum)],session_type,['ses-',num2str(session)]);
ExistFlag = exist(SubSesFolder,'dir');
if ExistFlag
    warning ('This participant number and session was already attributed!')
    proceedInput = questdlg({'This participant number and session was already attributed!', 'Are you sure you want to proceed?'},'RestartPrompt','yes','no','no');
    if strcmp(proceedInput,'no')
        error('Program aborted by user')
    end
end

% Add functions folder to path (when we separate all functions)
function_folder = [pwd,filesep,'functions\'];
addpath(function_folder)

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

%% Initializing experimental parameters and PTB:
initRuntimeParameters
initConstantsParameters(); % defines all constants and initilizes parameters of the program
initPsychtooblox(); % initializes psychtoolbox window at correct resolution and refresh rate

% Create the subject ID by combining the lab ID with the subject name:
subID = sprintf('%s%d', LAB_ID, subjectNum);

% Saves a copy of code to disk
saveCode()
%% Setup the trial matrix and log:
% open trial matrix (form Experiment 1) and add auditory conditions
MatFolderName = [pwd,filesep,'TrialMatrices\'];
TableName = [subID,'_TrialMatrix.csv'];
trial_mat = readtable(fullfile(MatFolderName, TableName));

% add auditory stimuli
trial_mat = addAudStim(trial_mat);

%-------------- Temporary solution with sesseion division ------------
trial_mat.session(1:length(trial_mat.trial)/6) = 1;
trial_mat.session((length(trial_mat.trial)/6)+1:end) = 2;
%---------------------------------------------------------------------
% cut trial mat to length of session
trial_mat = trial_mat((trial_mat.session == session),:);

%% Load and prepare the visual and audio stimuli:
showMessage(LOADING_MESSAGE);
loadStimuli() % visual
[high_pitch_buff, low_pitch_buff] = init_audio_pitches(PITCH_DURATION, HIGH_PITCH_FREQ,  LOW_PITCH_FREQ); % auditory

%% Instructions and practice:
% displays instructions
Instructions();
% calibration task
if introspec == TRUE
    showMessage(CALIBRATION_START_MESSAGE);
    KbWait(compKbDevice,3);
    handle = PsychPowerMate('Open'); % open dial
    cali_log = calibration(NUM_OF_TRIALS_CALIBRATION);
    saveTable(cali_log,'calibration_output')
end

%% Main experimental loop:
try
    
    ABORTED = 0;
    
    %% save everything from command window
    Str = CmdWinTool('getText');
    dlmwrite(dfile,Str,'delimiter','');
    
    %% Experiment Prep
    previous_miniblock = 0;
    warning_response_order = 0;
    
    %%  Experiment
    showFixation('PhotodiodeOff');
    showMessage(EXPERIMET_START_MESSAGE);
    KbWait(compKbDevice,3);
    
    %% Block loop:
    blks = unique(trial_mat.block);
    if NO_PRACTICE
        blk = 1;
    else
        blk = trial_mat.block(1);
    end
    while blk <= blks(end)
        
        % Initialize the eyetracker with the block number:
        if EYE_TRACKER
            initEyetracker(subjectNum, blk);
        end

        % Extract the trial and log of this block only:
        blk_mat = trial_mat(trial_mat.block == blk, :);
        
        % Add the columns for logging:
        blk_mat = prepare_log(blk_mat);
        log_hasInputs_vis = nan(1,length(trial_mat.trial));
        % calculate SOA from onset
        for tr = 1:length(blk_mat.trial)
            if strcmp(blk_mat.SOA_lock{tr}, 'offset')
                blk_mat.onset_SOA(tr) = blk_mat.SOA(tr) + blk_mat.duration(tr);
            else
                blk_mat.onset_SOA(tr) = blk_mat.SOA(tr);
            end
        end
        
        % Check whether this block is a practice or not:
        is_practice = blk_mat.is_practice(1);
        if is_practice
            % Extract from table the practice type:
            practice_type = blk_mat.practice_type(1);
            practice_start_msg = get_practice_instructions(practice_type);
            showMessage(practice_start_msg);
            KbWait(compKbDevice,3);
        else
            % Otherwise, show the target screen:
            practice_type = 'not_practice';
            % Show the target screen at the beginning of each block:
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
                blk_mat.vis_stim_time(tr) = showFixation('PhotodiodeOff'); % Do not show the 
            else
                blk_mat.vis_stim_time(tr) = showStimuli(texture_ptr);
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
            if introspec
                total_trial_duration = TRIAL_DURATION - (refRate*(2/3));
            else
                total_trial_duration = TRIAL_DURATION - (refRate*(2/3)) + blk_mat.stim_jit(tr);
            end
            
            while elapsedTime < total_trial_duration
                % In order to count the frames, I always convert the
                % time to frames by dividing it by the refresh rate:
                CurrentFrame = floor(elapsedTime/refRate);
                
                % If the current frame number is different from the
                % previous, then a new frame started so I send the new triggers:
                if CurrentFrame > PreviousFrame
                    FrameIndex = FrameIndex +1;
                    PreviousFrame = CurrentFrame;
                end
                %--------------------------------------------------------
                %% Repsonse assessment
                if hasInputs < 2
                    [key,Resp_Time,PauseTime] = getInput(PauseTime);
                    
                    % If the restart key was pressed
                    if(key == RESTART_KEY)
                        %  Ask the experiment whether he really wishes to restart
                        showMessage(RESTART_MESSAGE);
                        
                        % Wait for answer
                        [secs, keyCode, deltaSecs] =KbWait(compKbDevice,3);
                        
                        % Get the restart interval (the time it took
                        % the experimenter to say he/she wants to
                        % restart:
                        RestartInterval = (secs - Resp_Time) - PauseTime; % Need to take the pause time into account, otherwise, we would be counting it twice down the line!
                        
                        % If the experimenter wants to restart, log it:
                        if(keyCode(YesKey))
                            showMessage(RESTARTBLOCK_OR_MINIBLOCK_MESSAGE);
                            % Wait for answer
                            [~, BlkOrminiBlk_keyCode, ~] =KbWait(compKbDevice,3);
                            break
                            
                        else % Else, continue:
                            key=NO_KEY;
                        end
                    elseif (key == ABORT_KEY) % If the experiment was aborted:
                        ABORTED = 1;
                        
                        error(CLEAN_EXIT_MESSAGE);
                    end
                    
                    % -----------------------------------------------------
                    % Responses keys treatment (needs to be separated from
                    % above, because above can change the key input
                    % depending on what's pressed, i.e. pursuing after
                    % clicking restart)
                    
                    % If the participant pressed a key that is different to the one of the previous iteration:
                    if key ~= NO_KEY && key ~= blk_mat.trial_first_button_press(tr)
                        
                        
                        % Sending response trigger for the eyetracker
                        if EYE_TRACKER
                            Eyelink('Message',num2str(TRG_RESPONSE));
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
                
                %% audio stimulus
                
                % Play pitch
                if elapsedTime >= (blk_mat.onset_SOA(tr) - refRate*(2/3)) && ...
                        pitchPlayed == FALSE && ~strcmp(practice_type, 'visual')
                    pitch_buff = eval([blk_mat.pitch{tr},'_pitch_buff']);
                    PsychPortAudio('FillBuffer', padhandle, pitch_buff);
                    
                    % And then you play the buffer. The function returns a time stamp.
                    % Here I don't use it but for our purpose we will want to log it:
                    PsychPortAudio('Start',padhandle, 1, 0);
                    blk_mat.aud_stim_time(tr) = GetSecs;
                    blk_mat.aud_stim_buff(tr) = pitch_buff;
                    
                    pitchPlayed = TRUE;
                    
                end
                
                %% Inter stimulus interval
                % Present fixation
                if elapsedTime >= (blk_mat.duration(tr) - refRate*(2/3)) && fixShown == FALSE
                    fix_time = showFixation('PhotodiodeOn');
                    % log fixation in journal
                    blk_mat.fix_time(tr) = fix_time;
                    fixShown = TRUE;
                end
                
                % Present jitter
                if elapsedTime > TRIAL_DURATION  - refRate*(2/3) && jitterLogged == FALSE
                    JitOnset = showFixation('PhotodiodeOn');
                    % log jitter started
                    blk_mat.JitOnset(tr) = JitOnset;
                    jitterLogged = TRUE;
                end
                
                % Updating clock:
                % update time since iteration begun. Subtract the time
                % of the pause to the elapsed time, because we don't
                % want to have it in there. If there was no pause, then
                % pause time = 0
                elapsedTime = GetSecs - blk_mat.vis_stim_time(tr);
            end
            blk_mat.trial_end(tr) = GetSecs;
            
            %% End of trial
            
            % check order of responses
            if blk_mat.trial_first_button_press(tr) >= 1000 && blk_mat.trial_second_button_press(tr) == 1
                warning_response_order = 1;
            end
            
            if introspec == TRUE
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
        saveTable(blk_mat, blk);   
        % Save the eyetracker data:
        if EYE_TRACKER
            save_eyetracker(blk);
        end
        
        if is_practice
            blk_continue = get_practice_feedback(blk_mat, practice_type);
            blk = blk + blk_continue;
        else
            blk = blk + 1;
        end
        
        % Append the block log to the overall log:
        if blk == 1
            log_all = blk_mat;
        else
            log_all = [log_all; blk_mat];  % Not the most efficient but it is in a non critical part
        end
        
        % order of responses reminder (if needed)
        if warning_response_order == 1
            showMessage(RESP_ORDER_WARNING_MESSAGE);
            WaitSecs(3);
            warning_response_order = 0;
        end
        
        % Every 4 blocks, there is a longer break:
        if mod(blk, 4) ==0
            block_message = sprintf(END_OF_BLOCK_MESSAGE, blk/4, trial_mat.block(end)/4);
        else
            block_message = sprintf(END_OF_MINIBLOCK_MESSAGE, blk, trial_mat.block(end));
        end
        showMessage(block_message);
        KbWait(compKbDevice,3);        
    end  % End of block loop

    %% End of experiment
    % Save the whole table:
    saveTable(log_all, "all");
    
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
        saveTable(blk_mat, blk); 
        % If the log all already exists, save it as well:
        if exist('log_all', 'var')
            [log_all, performance_struct] = compute_performance(log_all);
            saveTable(log_all, "all"); 
        end
        safeExit()
    catch
        warning('-----  Data could not be saved!  ------')
        safeExit()
        rethrow(e);
    end
end
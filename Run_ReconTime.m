%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear all;

% Hardware parameters:
global subjectNum TRUE FALSE refRate compKbDevice RESTING_STATE RESTING_STATE_TIME
global el EYE_TRACKER MEG CalibrationKey ValidationKey EYETRACKER_CALIBRATION_MESSAGE session LAB_ID subID
global DATA_FOLDER FRAME_ANTICIPATION PHOTODIODE DIOD_DURATION SHOW_INSTRUCTIONS
global LOADING_MESSAGE CLEAN_EXIT_MESSAGE SAVING_MESSAGE END_OF_EXPERIMENT_MESSAGE
global END_OF_MINIBLOCK_MESSAGE END_OF_BLOCK_MESSAGE EXPERIMET_START_MESSAGE
global ABORTED abortKey VISUAL_TARGET HIGH_PITCH LOW_PITCH MEGbreakKey
global HIGH_PITCH_FREQ LOW_PITCH_FREQ PITCH_DURATION RESP_ORDER_WARNING_MESSAGE_AUDITORY_FIRST RESP_ORDER_WARNING_MESSAGE_VISUAL_FIRST padhandle


% Add functions folder to path (when we separate all functions)
function_folder = [pwd,filesep,'functions\'];
addpath(function_folder)

% prompt user for information
subjectNum = input('Subject number [101-199, default 101]: '); if isempty(subjectNum); subjectNum = 101; end
session = input('Session number [1-6, default 1]: '); if isempty(session); session = 1; end

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

%% check if participant and session exists alread
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

%% Initialization
initPsychtooblox(); % initializes psychtoolbox window at correct resolution and refresh rate
if MEG
    [LPT_Object, LPT_address] = init_LPT();
end
%% Setup the trial matrix and log:
% open trial matrix (form Experiment 1) and add auditory conditions
MatRoot = [pwd,filesep,'TrialMatricesMEG\'];
NamingConv = sprintf("%ssub-%s_ses-%d_task-*.csv", MatRoot, subID, session);
% Get trials matrices from this session:
session_matrices_files = dir(NamingConv);
for task_file_i=1:length(session_matrices_files)
    if task_file_i == 1
        session_trial_mat = readtable(fullfile(session_matrices_files(task_file_i).folder, session_matrices_files(task_file_i).name));
    else
        session_trial_mat = [session_trial_mat; readtable(fullfile(session_matrices_files(task_file_i).folder, session_matrices_files(task_file_i).name))];
    end
end

% Order the session trial mat:
session_trial_mat = sortrows(session_trial_mat, "tasks_order");

%% Load and prepare the visual and audio stimuli:
showMessage(LOADING_MESSAGE);
loadStimuli() % visual
[high_pitch_buff, low_pitch_buff] = init_audio_pitches(PITCH_DURATION, HIGH_PITCH_FREQ,  LOW_PITCH_FREQ); % auditory

% make jitter multiple of refresh rate
for tr_jit = 1:length(session_trial_mat.trial)
    jit_multiplicator = round(session_trial_mat.stim_jit(tr_jit)/refRate);
    session_trial_mat.stim_jit(tr_jit) = refRate*jit_multiplicator;
end

%% Task loop:
session_tasks = unique(session_trial_mat.task,'stable');
for task_i=1:length(session_tasks)
    % Get current task:
    task = session_tasks{task_i};
    disp(task)
    tic;  % Start the timer
    % Present the instructions for the current task:
    if SHOW_INSTRUCTIONS
        Instructions(task);
    end
    % Get the task matrix:
    task_trial_mat = session_trial_mat(strcmp(session_trial_mat.task, task), :);
    
    % Prepare a few task dependent variables:
    if contains(task, "only")
       n_responses = 1;
       switch task
           case "auditory_only"
               hasInput_vis_dflt = TRUE;
               hasInput_aud_dflt = FALSE;
           case "visual_only"
               hasInput_vis_dflt = FALSE;
               hasInput_aud_dflt = TRUE;
       end
    else
        n_responses = 2;
        hasInput_vis_dflt = FALSE;
        hasInput_aud_dflt = FALSE;
    end
    
    %% Main experimental loop:
    try
        % Experiment Prep
        previous_miniblock = 0;
        warning_response_order = 0;
        start_message_flag = FALSE;
        showFixation('PhotodiodeOff');
        blk = 1;
        
        %% Block loop:
        blks = unique(task_trial_mat.block);
        while blk <= blks(end)
            % in the very first trial of the actual experiment show start message
            if blk == 1
                showMessage(EXPERIMET_START_MESSAGE);
                wait_resp = 0;
                while wait_resp == 0
                    [~, ~, wait_resp] = KbCheck();
                end
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
                    [~, CalibrationResp, ~] = KbWait(compKbDevice,3);
                    if CalibrationResp(CalibrationKey)
                        % Run the calibration:
                        EyelinkDoTrackerSetup(el);
                        CorrectKey = 1;
                    elseif CalibrationResp(ValidationKey)
                        CorrectKey = 1;
                    end
                end
                % Starting the recording
                Eyelink('StartRecording');
                % Wait for the recording to have started:
                WaitSecs(0.1);
            end
            
            % Extract the trial and log of this block only:
            blk_mat = task_trial_mat(task_trial_mat.block == blk, :);
            % Extract the task from this block:
            task = char(blk_mat.task(1));
            
            % Add the columns for logging:
            blk_mat = prepare_log(blk_mat);
            log_hasInputs_vis = nan(1,length(task_trial_mat.trial));
                        
            % Show the target screen at the beginning of each block (expect if it is the auditory only task):
            if ~strcmp(task, 'auditory_only')
                blk_mat.TargetScreenOnset(1) = showMiniBlockBeginScreen(blk_mat, 1);
                WaitSecs(0.3);
                wait_resp = 0;
                while wait_resp == 0
                    [~, ~, wait_resp] = KbCheck();
                end
            end
            
            % Wait a random amount of time and show fixation:
            fixOnset = showFixation('PhotodiodeOff'); % 1
            WaitSecs(rand*2+0.5);
            
            %% Trials loop:
            for tr = 1:length(blk_mat.trial)
                % flags needs to be initialized
                fixShown = FALSE;
                pitchPlayed = FALSE;
                stimShowed = FALSE;
                jitterLogged = FALSE;
                hasInput_vis = hasInput_vis_dflt;
                hasInput_aud = hasInput_aud_dflt;
                
                % other variables that need to be reset for every trial
                hasInputs = 0; % input flag, marks if participant already replied
                PauseTime = 0; % If the experiment is paused, the duration of the pause is stored to account for it.
                
                %% Extract trial specific information
                vis_stim_id = blk_mat.identity{tr};
                orientation = blk_mat.orientation{tr};
                soa = blk_mat.onset_SOA(tr);
                soa_raw = blk_mat.SOA(tr);
                trial_duration = blk_mat.trial_duration(tr);
                vis_stim_dur = blk_mat.duration(tr);
                jitter = blk_mat.stim_jit(tr);
                introspection = 0;
                % Get texture pointer:
                texture_ptr = getPointer(vis_stim_id, orientation);
                blk_mat.texture(tr) = texture_ptr; % Log the texture
                % Get pitch buffer:
                if blk_mat.pitch(tr) == 1000
                    pitch_buff = low_pitch_buff;
                elseif blk_mat.pitch(tr) == 1100
                    pitch_buff = high_pitch_buff;
                end
                % Adjust visual stimulus offset:
                if strcmp(task, 'auditory_first')
                    fixation_onset = vis_stim_dur + soa;
                else
                    fixation_onset = vis_stim_dur;
                end
                
                %% Start presentation:
                % show stimulus
                if contains(task, 'visual')
                    blk_mat.trial_start_time(tr) = showStimuli(texture_ptr);
                    blk_mat.vis_stim_time(tr) = blk_mat.trial_start_time(tr);
                    DiodFrame = 0;
                    % Sending the MEG trigger:
                    if MEG
                        trigCode = get_meg_trigger("visual");
                        LTP_State, megTrigOnset = sendMegTrig(trigCode,LPT_Object, LPT_address);
                    end
                    % Sending response trigger for the eyetracker
                    if EYE_TRACKER
                        trigger_str = get_et_trigger('vis_onset', blk_mat.task_relevance{tr}, ...
                            blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                            blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                        Eyelink('Message',trigger_str);
                    end
                elseif contains(task, 'auditory')
                    % Load the buffer
                    PsychPortAudio('FillBuffer', padhandle, pitch_buff);
                    % Play the buffer
                    PsychPortAudio('Start',padhandle, 1, 0);
                    % Get the buffer time stamp:
                    audio_start = GetSecs();
                    % Sending the MEG trigger:
                    if MEG
                        trigCode = get_meg_trigger("audio");
                        LTP_State, megTrigOnset = sendMegTrig(trigCode,LPT_Object, LPT_address);
                    end
                    % Sending response trigger for the eyetracker
                    if EYE_TRACKER
                        trigger_str = get_et_trigger('audio_onset', blk_mat.task_relevance{tr}, ...
                            blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                            blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                        Eyelink('Message',trigger_str);
                    end
                    % Log the audio buffer:
                    blk_mat.trial_start_time(tr) = audio_start;
                    blk_mat.aud_stim_time(tr) = audio_start;
                    blk_mat.aud_stim_buff(tr) = pitch_buff;
                end
                
                % I then set a frame counter. The flip of the stimulus
                % presentation is frame 0. It is already the previous frame because it already occured:
                PreviousFrame = 0;
                % I then set a frame index. It is the same as the previous
                % frame for now
                FrameIndex = PreviousFrame;
                
                %% TIME LOOP
                elapsedTime = 0;
                
                % define total trial duration
                total_trial_duration = trial_duration - (refRate*FRAME_ANTICIPATION) + jitter;
                
                while elapsedTime < total_trial_duration
                    %% Play audio stimulus
                    if elapsedTime >= soa && pitchPlayed == FALSE && contains(task, 'visual')
                        % Select the right buffer
                        if blk_mat.pitch(tr) == 1000
                            pitch_buff = low_pitch_buff;
                        elseif blk_mat.pitch(tr) == 1100
                            pitch_buff = high_pitch_buff;
                        end
                        % Load the buffer
                        PsychPortAudio('FillBuffer', padhandle, pitch_buff);
                        % Play the buffer
                        PsychPortAudio('Start',padhandle, 1, 0);
                        % Get the buffer time stamp:
                        audio_start = GetSecs();
                        % Sending the MEG trigger:
                        if MEG && soa_raw ~= 0
                            trigCode = get_meg_trigger("audio");
                            LTP_State, megTrigOnset = sendMegTrig(trigCode,LPT_Object, LPT_address);
                        end
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
                    %% Show visual stimulus
                    if elapsedTime >= soa && stimShowed == FALSE && contains(task, 'auditory')
                        blk_mat.vis_stim_time(tr) = showStimuli(texture_ptr);
                        DiodFrame = 0;
                        % Sending the MEG trigger:
                        if MEG && soa_raw ~= 0
                            trigCode = get_meg_trigger("visual");
                            LTP_State, megTrigOnset = sendMegTrig(trigCode,LPT_Object, LPT_address);
                        end
                        % Sending response trigger for the eyetracker
                        if EYE_TRACKER
                            trigger_str = get_et_trigger('vis_onset', blk_mat.task_relevance{tr}, ...
                                blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                                blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                            Eyelink('Message',trigger_str);
                        end
                        stimShowed = TRUE;
                    end
                    
                    %% Get response:
                    if hasInputs < n_responses
                        % Ge the response:
                        [KeyIsDown, Resp_Time, keyCode] = KbCheck();
                        
                        % Handling the response if any:
                        if KeyIsDown
                            % If the pressed key is the same as the
                            % previous one, continue to avoid double
                            % logging of the same response:
                            if hasInputs > 0 && keyCode(blk_mat.trial_first_button_press(tr))
                                continue                                
                            end
                            % Sending the MEG trigger. For the response, as it is user controlled, it can collide with other triggers:
                            if MEG
                                trigCode = get_meg_trigger("response");
                                try
                                    LTP_State, megTrigOnset = sendMegTrig(trigCode,LPT_Object, LPT_address);
                                catch ME
                                    if contains(ME.message, 'Port occupied!')
                                        disp("The response trigger could not be sent, because the LPT port was occupied!")
                                    else 
                                        rethrow ME
                                    end
                                end
                            end
                            % Sending response trigger for the eyetracker
                            if EYE_TRACKER
                                trigger_str = get_et_trigger('response', blk_mat.task_relevance{tr}, ...
                                    blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                                    blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                                Eyelink('Message',trigger_str);
                            end
                            
                            if keyCode(abortKey) % If the experiment was aborted:
                                ABORTED = 1;
                                error(CLEAN_EXIT_MESSAGE);
                            end
                            
                            % logging reaction
                            hasInputs = hasInputs + 1;
                            log_hasInputs_vis(tr) = hasInputs;
                            
                            % Log the response received:
                            if  hasInputs == 1
                                blk_mat.trial_first_button_press(tr) = find(keyCode);
                            else
                                blk_mat.trial_second_button_press(tr) = find(keyCode);
                            end
                            
                            % store RT for visual task
                            if keyCode(VISUAL_TARGET) && hasInput_vis == FALSE % taget key was pressed
                                blk_mat.time_of_resp_vis(tr) =  Resp_Time;
                                blk_mat.has_response_vis(tr) = 1;
                                hasInput_vis = TRUE;
                                % store RT for auditory task
                            elseif (keyCode(HIGH_PITCH) || keyCode(LOW_PITCH)) && hasInput_aud == FALSE % auditory key was pressed
                                blk_mat.time_of_resp_aud(tr) =  Resp_Time;
                                hasInput_aud = TRUE;
                            else
                                blk_mat.wrong_key(tr) =  find(keyCode);
                                blk_mat.wrong_key_timestemp(tr) =  Resp_Time;
                            end
                        end
                    end
                    
                    %% Inter stimulus interval
                    % Present fixation
                    if elapsedTime >= (fixation_onset - refRate*FRAME_ANTICIPATION) && fixShown == FALSE
                        fix_time = showFixation('PhotodiodeOn');
                        DiodFrame = CurrentFrame;
                        % Sending the MEG trigger:
                        if MEG
                            trigCode = get_meg_trigger("fixation");
                            LTP_State, megTrigOnset = sendMegTrig(trigCode,LPT_Object, LPT_address);
                        end
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
                    if elapsedTime > trial_duration  - refRate*FRAME_ANTICIPATION && jitterLogged == FALSE
                        JitOnset = showFixation('PhotodiodeOn');
                        DiodFrame = CurrentFrame;
                        % Sending the MEG trigger:
                        if MEG
                            trigCode = get_meg_trigger("jitter");
                            LTP_State, megTrigOnset = sendMegTrig(trigCode,LPT_Object, LPT_address);
                        end
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
                    elapsedTime = GetSecs - blk_mat.trial_start_time(tr);
                    
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
                    % Reset the LPT port to 0:
                    if MEG && LTP_State ~=0 && elapsedTime - megTrigOnset >= 0.01
                        LTP_State, megTrigOnset = sendMegTrig(0, LPT_Object, LPT_address);
                    end
                end
                blk_mat.trial_end(tr) = GetSecs;
                
                %% End of trial
                % check order of responses
                if strcmp(task, "auditory_first")
                    if blk_mat.trial_second_button_press(tr) == VISUAL_TARGET || blk_mat.trial_first_button_press(tr) == LOW_PITCH
                        warning_response_order = 1;
                    end
                elseif strcmp(task, "visual_first")
                    if blk_mat.trial_second_button_press(tr) == VISUAL_TARGET
                        warning_response_order = 1;
                    end
                end
                
                %% introspective questions
                if introspection
                    % introspective question 1 (RT visual task)
                    if EYE_TRACKER
                        trigger_str = get_et_trigger('vis_qn_onset', blk_mat.task_relevance{tr}, ...
                            blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                            blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                        Eyelink('Message',trigger_str);
                    end
                    % blk_mat.iRT_vis(tr) = run_dial('vis');
                    WaitSecs(4);

                    if EYE_TRACKER
                        trigger_str = get_et_trigger('vis_qn_resp', blk_mat.task_relevance{tr}, ...
                            blk_mat.duration(tr), blk_mat.category{tr}, orientation, vis_stim_id, ...
                            blk_mat.SOA(tr), blk_mat.SOA_lock(tr), blk_mat.pitch(tr));
                        Eyelink('Message',trigger_str);
                    end

                    showFixation('PhotodiodeOn');
                    WaitSecs(blk_mat.intro_jit(tr));             
                end
            end  % End of trial loop
            
            % Save the data of this block:
            saveTable(blk_mat, task, blk);
            % Save the eyetracker data:
            if EYE_TRACKER
                saveEyetracker(task, blk);
            end
            
            % Append the block log to the overall log:
            if ~exist('log_all', 'var')
                log_all = blk_mat;
            else
                log_all = [log_all; blk_mat];  % Not the most efficient but it is in a non critical part
            end
            
            % order of responses reminder (if needed)
            if warning_response_order == 1
                if strcmp(task, "auditory_first")
                    WARNING_MESSAGE = RESP_ORDER_WARNING_MESSAGE_AUDITORY_FIRST;
                elseif strcmp(task, "visual_first")
                    WARNING_MESSAGE = RESP_ORDER_WARNING_MESSAGE_VISUAL_FIRST;
                end
                showMessage(WARNING_MESSAGE);
                WaitSecs(3);
                warning_response_order = 0;
            end
            
            % Break after every 4 blocks in prp task and every 8 blocks in introspective task
            blk_break = 4;
            miniblk_break = 1;
            if mod(blk, blk_break) == 0
                last_block = log_all(log_all.block > blk - blk_break, :);
                [last_block, ~] = compute_performance(last_block);
                block_message = sprintf(END_OF_BLOCK_MESSAGE, round(blk/blk_break), round(task_trial_mat.block(end)/blk_break), round(mean(last_block.trial_accuracy_aud, 'omitnan')*100));
                showMessage(block_message);
                continue_ = 0;
                while continue_ == 0
                    [KeyIsDown, Resp_Time, keyCode] = KbCheck();
                    if KeyIsDown && keyCode(MEGbreakKey)
                        continue_ = 1;
                    end
                end
            elseif mod(blk, miniblk_break) == 0
                block_message = sprintf(END_OF_MINIBLOCK_MESSAGE, round(blk/miniblk_break), round(task_trial_mat.block(end)/miniblk_break));
                showMessage(block_message);
                [blk_mat, ~] = compute_performance(blk_mat);
                wait_resp = 0;
                while wait_resp == 0
                    [~, ~, wait_resp] = KbCheck();
                end
            end
            blk = blk + 1;
        end  % End of block loop
        elapsedTime = toc;  % Get the elapsed time in seconds
        disp("Task time: ")
        disp(elapsedTime)
        disp("")
        %% End of experiment
        % compute performances of tasks
        [log_all, performance_struct] = compute_performance(log_all);
        % Save the whole table:
        saveTable(log_all, task, "all");
        clear log_all
        
        %% Record resting state:
        if RESTING_STATE
            %% Eyes open resting state:
            showMessage("Welcome to the resting state recording! \nPlease look at the fixation cross \nWait for the experimenter to start the recording")
            % Display the resting state message to the participant:
            continue_ = 0;
            while continue_ == 0
                [KeyIsDown, Resp_Time, keyCode] = KbCheck();
                if KeyIsDown && keyCode(MEGbreakKey)
                    continue_ = 1;
                end
            end
            fixation_onset = showFixation('PhotodiodeOff'); % Show the fixation
            elapsed_time = 0;
            while elapsed_time < RESTING_STATE_TIME
                [KeyIsDown, Resp_Time, keyCode] = KbCheck();
                if KeyIsDown && keyCode(abortKey)
                    break
                end
                elapsed_time = GetSecs() - fixation_onset;
            end
            
            %% Eyes closed resting state:
            showMessage("Now close your eyes and wait for the experimenter to tell you otherwise \nWait for the experimenter to start the recording")
            % Display the resting state message to the participant:
            continue_ = 0;
            while continue_ == 0
                [KeyIsDown, Resp_Time, keyCode] = KbCheck();
                if KeyIsDown && keyCode(MEGbreakKey)
                    continue_ = 1;
                end
            end
            fixation_onset = showFixation('PhotodiodeOff'); % Show the fixation
            elapsed_time = 0;
            while elapsed_time < RESTING_STATE_TIME
                [KeyIsDown, Resp_Time, keyCode] = KbCheck();
                if KeyIsDown && keyCode(abortKey)
                    break
                end
                elapsed_time = GetSecs() - fixation_onset;
            end
        end
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
        end
        rethrow(e);
    end
end

% Save the code:
saveCode(task);
% Letting the participant that it is over:
showMessage(END_OF_EXPERIMENT_MESSAGE);
WaitSecs(2);

showMessage(SAVING_MESSAGE);
% Mark the time of saving onset
ttime = GetSecs;


% save everything from command window
Str = CmdWinTool('getText');
dlmwrite(dfile,Str,'delimiter','');

% Terminating teh experiment:
safeExit()
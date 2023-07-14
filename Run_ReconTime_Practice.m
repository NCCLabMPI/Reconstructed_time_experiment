%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear all;

% Hardware parameters:
global subjectNum TRUE FALSE refRate
global session LAB_ID subID
global DATA_FOLDER FRAME_ANTICIPATION PHOTODIODE DIOD_DURATION SHOW_INSTRUCTIONS
global CLEAN_EXIT_MESSAGE
global EXPERIMET_START_MESSAGE LOADING_MESSAGE
global ABORTED abortKey VISUAL_TARGET HIGH_PITCH LOW_PITCH PITCH_DURATION HIGH_PITCH_FREQ LOW_PITCH_FREQ
global padhandle


% Add functions folder to path (when we separate all functions)
function_folder = [pwd,filesep,'functions\'];
addpath(function_folder)

% prompt user for information
subjectNum = input('Subject number [101-199, default 101]: '); if isempty(subjectNum); subjectNum = 101; end

% initializing experimental parameters
initRuntimeParameters
initConstantsParameters(); % defines all constants and initilizes parameters of the program

subID = sprintf('%s%d', LAB_ID, subjectNum);
SubSesFolder = fullfile(pwd,DATA_FOLDER,['sub-',subID],['ses-',num2str(session)]);

%% Initialization
initPsychtooblox(); % initializes psychtoolbox window at correct resolution and refresh rate
showMessage(LOADING_MESSAGE);
loadStimuli() % visual
[high_pitch_buff, low_pitch_buff] = init_audio_pitches(PITCH_DURATION, HIGH_PITCH_FREQ,  LOW_PITCH_FREQ); % auditory
% Load the participant matrix:
MatRoot = [pwd,filesep,'TrialMatricesMEG\'];

% Set the list of pratices to perform:
practices = ["visual_first", "auditory_first", "visual_first", "auditory_first"];
for practice_i = 1:length(practices)
    practice_type = practices(practice_i);
    MatName = sprintf("%ssub-%s_ses-%d_task-%s.csv", MatRoot, subID, 1, practice_type);
    % Get trials matrices from this session:
    trial_matrix = readtable(MatName);
    % Grab a random trial number:
    blk_mat = trial_matrix(trial_matrix.block == datasample(trial_matrix.block, 1), :);
    
    % Show the instructions:
    if SHOW_INSTRUCTIONS
        if practice_i == 1
            Instructions("visual_only");
        elseif practice_i == 2
            Instructions("auditory_only");
        elseif practice_i == 3
            Instructions(practice_type);
        elseif practice_i == 4  
            Instructions(practice_type);
        end
    end
    
    % Prepare a few task dependent variables:
    if contains(practice_type, "only")
        n_responses = 1;
        switch practice_type
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
    
    % Repeat the practice until acceptable:
    repeat_practice = 1;
    
    while repeat_practice
        
        % Experiment start screen:
        showMessage(EXPERIMET_START_MESSAGE);
        wait_resp = 0;
        while wait_resp == 0
            [~, ~, wait_resp] = KbCheck();
        end
        start_message_flag = TRUE;
        
        % Add the columns for logging:
        blk_mat = prepare_log(blk_mat);
        log_hasInputs_vis = nan(1,length(blk_mat.trial));
        
        % Show the target screen at the beginning of each block (expect if it is the auditory only task):
        if ~strcmp(practice_type, 'auditory_only')
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
            trial_duration = blk_mat.trial_duration(tr);
            vis_stim_dur = blk_mat.duration(tr);
            jitter = blk_mat.stim_jit(tr);
            introspection = blk_mat.introspection(tr);
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
            if strcmp(practice_type, 'auditory_first')
                fixation_onset = vis_stim_dur + soa;
            else
                fixation_onset = vis_stim_dur;
            end
            
            %% Start presentation:
            % show stimulus
            if contains(practice_type, 'visual')
                blk_mat.trial_start_time(tr) = showStimuli(texture_ptr);
                blk_mat.vis_stim_time(tr) = blk_mat.trial_start_time(tr);
                DiodFrame = 0;
            elseif contains(practice_type, 'auditory')
                % Load the buffer
                PsychPortAudio('FillBuffer', padhandle, pitch_buff);
                % Play the buffer
                PsychPortAudio('Start',padhandle, 1, 0);
                % Get the buffer time stamp:
                audio_start = GetSecs();
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
                if elapsedTime >= soa && pitchPlayed == FALSE && contains(practice_type, 'visual')
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
                    blk_mat.aud_stim_time(tr) = audio_start;
                    blk_mat.aud_stim_buff(tr) = pitch_buff;
                    pitchPlayed = TRUE;
                end
                %% Show visual stimulus
                if elapsedTime >= soa && stimShowed == FALSE && contains(practice_type, 'auditory')
                    blk_mat.vis_stim_time(tr) = showStimuli(texture_ptr);
                    DiodFrame = 0;
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
                        if keyCode(abortKey) % If the experiment was aborted:
                            ABORTED = 1;
                            sca
                            clear
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
                    % log fixation in journal
                    blk_mat.fix_time(tr) = fix_time;
                    fixShown = TRUE;
                end
                
                % Present jitter
                if elapsedTime > trial_duration  - refRate*FRAME_ANTICIPATION && jitterLogged == FALSE
                    JitOnset = showFixation('PhotodiodeOn');
                    DiodFrame = CurrentFrame;                    
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
            end
            blk_mat.trial_end(tr) = GetSecs;
            
            %% End of trial
            % check order of responses
            if strcmp(practice_type, "auditory_first")
                if blk_mat.trial_first_button_press(tr) == VISUAL_TARGET
                    warning_response_order = 1;
                end
            elseif strcmp(practice_type, "visual_first")
                if blk_mat.trial_first_button_press(tr) == HIGH_PITCH || blk_mat.trial_first_button_press(tr) == LOW_PITCH
                    warning_response_order = 1;
                end
            end
            if blk_mat.trial_first_button_press(tr) >= 1000 && blk_mat.trial_second_button_press(tr) == 1
                warning_response_order = 1;
            end
            
            %% introspective questions
            if introspection && practice_i > 2
                % introspective question 1 (RT visual task)
                blk_mat.iRT_vis(tr) = run_dial('vis');              
                showFixation('PhotodiodeOn');
                WaitSecs(blk_mat.intro_jit(tr));
            end
        end  % End of trial loop
        
        % Display the practice feedback:
        if practice_i == 1
            feedback_type = "visual";
        elseif practice_i == 2
            feedback_type = "auditory";
        elseif practice_i > 2
            feedback_type = "auditory_and_visual";
        end
        continue_practice = get_practice_feedback(blk_mat, feedback_type);
        repeat_practice = ~continue_practice;
    end    
end





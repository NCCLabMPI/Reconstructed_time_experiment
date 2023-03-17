%RUNPRACTICE
% This runs the practice mini block. This function does not recieve any
% input besided ESCAPE. It does not record any information regarding this
% block. It takes the practice trial list practice.mat (which is always constant) and the first two
% pictures in the practice folder in the stimuli folder as targets.
function [ ] = runPractice(practice_type)

disp(['WELCOME TO runPractice. Practice type: ', practice_type])

global compKbDevice FALSE TRUE TRIAL_DURATION
global refRate NO_KEY VIS_TARGET_KEY LOW_PITCH_KEY HIGH_PITCH_KEY PITCH_DURATION HIGH_PITCH_FREQ LOW_PITCH_FREQ
global RESTART_KEY RESTART_MESSAGE ABORT_KEY YesKey ABORTED CLEAN_EXIT_MESSAGE practice_log
global STIM_DURATION practice_mat practice_aud_score warning_response_order
global RUN_PRACTICE PracticeHits PracticeFalseAlarms PracticeFalseAlarms_Irrelevant MinPracticeHits MaxPracticeHits MaxPracticeFalseAlarms MaxPracticeFalseAlarms_Irrelevant Practice_aud_accuracy_cutoff
global TotalScore FEEDBACK_MESSAGES_PRACTICE PRACTICE_FEEDBACK_MESSAGES

practice_mat = readtable([pwd,filesep,'TrialMatrices\practice_mat.csv']); % <- loads the practice matrix
if ~strcmp(practice_type, 'visual')
    [high_pitch_buff, low_pitch_buff, aud_pahandle] = init_audio_pitches(PITCH_DURATION, HIGH_PITCH_FREQ, LOW_PITCH_FREQ); % auditory
end

% for every partice new targets are selected and order of the stimuli is shuffled
target_1_num = randi(6);
target_2_num = randi(6)+6;
for tr = 1:length(practice_mat.trial)
    practice_mat.target_1{tr} = {['practice_0', num2str(target_1_num)]}; % random false font
    if target_2_num < 10
        practice_mat.target_2{tr} = ['practice_0', num2str(target_2_num)]; % random letter
    else
        practice_mat.target_2{tr} = ['practice_', num2str(target_2_num)]; % random letter
    end
    if strcmp(practice_mat.task_relevance{tr}, 'target') && strcmp(practice_mat.category{tr}, 'false_font')
        practice_mat.identity{tr} = practice_mat.target_1{tr};
    elseif strcmp(practice_mat.task_relevance{tr}, 'target') && strcmp(practice_mat.category{tr}, 'letter')
        practice_mat.identity{tr} = practice_mat.target_2{tr};
    end
end
practice_mat = ShuffleRows(practice_mat);

% initiate practice lot table
practice_log = practice_mat;
practice_log.trial_button_press(1,1) = 0;
practice_log.trial_button_press(1,2) = 0;

% calculate SOA from onset
for tr = 1:length(practice_log.trial)
    if strcmp(practice_log.SOA_lock{tr}, 'offset')
        practice_log.onset_SOA(tr) = practice_log.SOA(tr) + practice_log.duration(tr);
    else
        practice_log.onset_SOA(tr) = practice_log.SOA(tr);
    end
end

% Initializing number of hits and false alarms
PracticeHits=0;
PracticeFalseAlarms=0;
PracticeFalseAlarms_Irrelevant=0;
TotalScore=0;
warning_response_order = 0;

% loop through all trials; trials start from 0, so that trial 0 is
% actually trial 1, 1 is 2 etc.
for tr = 1:length(practice_log.trial)

    %get some random values for practice
    jitter = getJitter(1);
    trial_time = STIM_DURATION(ceil(rand()*length(STIM_DURATION)));

    % flags needs to be initialized
    fixShown = FALSE;
    pitchPlayed = FALSE;
    jitterLogged = FALSE;
    hasInput_vis = FALSE;
    hasInput_aud = FALSE;

    % other variables that need to be reset for every trial
    hasInputs = 0; % input flag, marks if participant already replied
    PauseTime = 0; % If the experiment is paused, the duration of the pause is stored to account for it.

    if tr == 1
        if ~strcmp(practice_type, 'auditory')
        showMiniBlockBeginScreen(practice_mat, tr);
        KbWait(compKbDevice,3);
        end
        % Sending the first fixation with jitter of each mini-block. Here the participant cannot respond
        fixOnset = showFixation('PhotodiodeOff');
        WaitSecs(TRIAL_DURATION - trial_time - refRate/2); % the fixation wait
        JitOnset = showFixation('PhotodiodeOff');
        WaitSecs(jitter - refRate/2); % the jitter wait
    end

    trial_start = GetSecs;

    if ~strcmp(practice_type, 'auditory')
        % get texture pointer
        vis_stim_id = practice_mat.identity{tr};
        orientation = practice_mat.orientation{tr};
        texture_ptr = getPointer(vis_stim_id, orientation);

        % show stimulus
        practice_log.vis_stim_time(tr) = showStimuli(texture_ptr);
    end

    % I then set a frame counter. The flip of the stimulus
    % presentation is frame 0. It is already the previous frame because it already occured:
    PreviousFrame = 0;
    % I then set a frame index. It is the same as the previous
    % frame for now
    FrameIndex = PreviousFrame;

    %% TIME LOOP
    elapsedTime = 0;

    % for introspective trial the jitter is moved out of the time loop
    % and comes after the questions
    if strcmp(practice_type, 'introspection')
        total_trial_duration = TRIAL_DURATION - (refRate*(2/3));
    else
        total_trial_duration = TRIAL_DURATION - (refRate*(2/3)) + practice_mat.stim_jit(tr);
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
            [key,~,PauseTime] = getInput(PauseTime);

            % If the restart key was pressed
            if(key == RESTART_KEY)
                %  Ask the experiment whether he really wishes to restart
                showMessage(RESTART_MESSAGE);

                % Wait for answer
                [~, keyCode, ~] =KbWait(compKbDevice,3);

                % If the experimenter wants to restart, log it:
                if(keyCode(YesKey))
                    tr = 0;
                    break
                else % Else, continue:
                    key=NO_KEY;
                end
            elseif (key == ABORT_KEY) % If the experiment was aborted:
                ABORTED = 1;
                error(CLEAN_EXIT_MESSAGE);
            end

            % -----------------------------------------------------
            % Responses keys treatment

            % If the participant pressed a key that is different to the one of the previous iteration:
            if key ~= NO_KEY && key ~= practice_log.trial_button_press(tr,1)

                % logging reaction
                hasInputs = hasInputs + 1;

                % Log the response received:
                practice_log.trial_button_press(tr,hasInputs) = key;

                % store RT for visual task
                if key == VIS_TARGET_KEY && hasInput_vis == FALSE % taget key was pressed
                    hasInput_vis = TRUE;

                    % store RT for auditory task
                elseif (key == LOW_PITCH_KEY || key == HIGH_PITCH_KEY) && hasInput_aud == FALSE % auditory key was pressed
                    hasInput_aud = TRUE;
                end
            end
        end

        %% audio stimulus

        % Play pitch
        if elapsedTime >= (practice_log.onset_SOA(tr) - refRate*(2/3)) && pitchPlayed == FALSE && ~strcmp(practice_type, 'visual')

            pitch_buff = eval([practice_mat.pitch{tr},'_pitch_buff']);
            PsychPortAudio('FillBuffer', aud_pahandle, pitch_buff);

            % And then you play the buffer. The function returns a time stamp.
            % Here I don't use it but for our purpose we will want to log it:
            PsychPortAudio('Start',aud_pahandle, 1, 0);
            practice_log.aud_stim_time(tr) = GetSecs;
            pitchPlayed = TRUE;

        end

        %% Inter stimulus interval
        % Present fixation
        if elapsedTime >= (practice_mat.duration(tr) - refRate*(2/3)) && fixShown == FALSE
            fix_time = showFixation('PhotodiodeOn');

            % log fixation in journal
            practice_log.fix_time(tr) = fix_time;
            fixShown = TRUE;
        end

        % Present jitter
        if elapsedTime > TRIAL_DURATION  - refRate*(2/3) && jitterLogged == FALSE
            JitOnset = showFixation('PhotodiodeOn');

            % log jitter started
            practice_log.JitOnset(tr) = JitOnset;
        end

        % Updating clock:
        elapsedTime = GetSecs - trial_start;
    end
    %% Introspective questions

    if strcmp(practice_type, 'introspection')
        WaitSecs(0.2);

        % introspective question 1 (RT visual task)
        introspec_question = 'vis';
        practice_log.iRT_vis(tr) = run_dial(introspec_question);

        showFixation('PhotodiodeOff');
        WaitSecs(0.1);

        % introspective question 2 (RT auditory task)
        introspec_question = 'aud';
        practice_log.iRT_aud(tr) = run_dial(introspec_question);

        showFixation('PhotodiodeOn');
        WaitSecs(practice_mat.stim_jit(tr));
    end

    %% End of trial

    % compute correctness visual task
    if ~strcmp(practice_type, 'auditory')
        if strcmp(practice_mat.task_relevance{tr}, 'target') && hasInput_vis == TRUE
            PracticeHits = PracticeHits + 1;
        elseif ~strcmp(practice_mat.task_relevance{tr}, 'target') && hasInput_vis == TRUE
            PracticeFalseAlarms = PracticeFalseAlarms + 1;
            if strcmp(practice_mat.task_relevance{tr}, 'irrelevant')
                PracticeFalseAlarms_Irrelevant = PracticeFalseAlarms_Irrelevant + 1;
            end
        end
    end

    % extract auditory response
    if ~strcmp(practice_type, 'visual')
        if practice_log.trial_button_press(tr,1) >= 1000
            practice_log.aud_resp(tr) = practice_log.trial_button_press(tr,1);
        elseif practice_log.trial_button_press(tr,2) >= 1000
            practice_log.aud_resp(tr) = practice_log.trial_button_press(tr,2);
        else
            practice_log.aud_resp(tr) = 0; % No auditory response was provided
        end

        % compute correctness auditory task
        if (practice_log.aud_resp(tr) == LOW_PITCH_KEY && strcmp(practice_mat.pitch{tr},'low')) ||...
                (practice_log.aud_resp(tr) == HIGH_PITCH_KEY && strcmp(practice_mat.pitch{tr},'high'))
            practice_log.trial_accuracy_aud(tr) = 1;

        elseif (practice_log.aud_resp(tr) == HIGH_PITCH_KEY && strcmp(practice_mat.pitch{tr},'low')) ||...
                (practice_log.aud_resp(tr) == LOW_PITCH_KEY && strcmp(practice_mat.pitch{tr},'high'))
            practice_log.trial_accuracy_aud(tr) = 0;
        else
            practice_log.trial_accuracy_aud(tr) = nan;
        end
    end

    if strcmp(practice_type, 'auditory_and_visual') || strcmp(practice_type, 'introspection')
        % check order of responses
        if practice_log.trial_button_press(tr,1) >= 1000 && practice_log.trial_button_press(tr,2) == 1
            warning_response_order = 1;
        end
    end

    % If the restart key was pressed, we break
    if (key == RESTART_KEY) % If there was a restart, tr = 0
        tr = 0;
    else % else, we simply continue
        tr =  tr + 1;
    end
end

% check whether wished performances are reached
auditory_failed = 0;
visual_failed = 0;

% for all expect auditory only check visual performance
if ~strcmp(practice_type, 'auditory')
    if PracticeHits < MinPracticeHits || PracticeFalseAlarms > MaxPracticeFalseAlarms || PracticeFalseAlarms_Irrelevant > MaxPracticeFalseAlarms_Irrelevant
    visual_failed = 1;
    end 
end 
    
% for all expect visual only check visual performance
if ~strcmp(practice_type, 'visual')

    % calculate auditory accuracy
    practice_aud_score = mean(practice_log.trial_accuracy_aud,'omitnan');
    if practice_aud_score < Practice_aud_accuracy_cutoff
        auditory_failed = 1;
    end
end

if auditory_failed || visual_failed 
    RUN_PRACTICE=1;
else
    RUN_PRACTICE=0;
end

% generate visual feedback message
if ~strcmp(practice_type, 'auditory')
    HitsScore = (4/MaxPracticeHits)*PracticeHits;
    FAScore = (-3/MaxPracticeHits)*PracticeFalseAlarms+3;
    FAScore(find(FAScore<0)) = 0;
    BlockIrrelevantCategoryFA = PracticeFalseAlarms_Irrelevant;

    if(BlockIrrelevantCategoryFA==0)
        IrrelevantCategoryFAScore=3;
    else
        IrrelevantCategoryFAScore=0;
    end

    TotalScore = (HitsScore+FAScore+IrrelevantCategoryFAScore)*10;
    feedback_message_flag1 = not(HitsScore/4 <= 0.5 || FAScore/3 <= 0.5 || IrrelevantCategoryFAScore < 3 || auditory_failed);
    feedback_message_flag2 = HitsScore/4 <= 0.5;
    feedback_message_flag3 = FAScore/3 <= 0.5;
    feedback_message_flag4 = IrrelevantCategoryFAScore < 3;

    PRACTICE_FEEDBACK_MESSAGES=FEEDBACK_MESSAGES_PRACTICE(find([feedback_message_flag1 feedback_message_flag2 (feedback_message_flag3 || feedback_message_flag4)]));

else
    PRACTICE_FEEDBACK_MESSAGES = [];
end

end % end function RunPractice
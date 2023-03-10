%RUNPRACTICE
% This runs the practice mini block. This function does not recieve any
% input besided ESCAPE. It does not record any information regarding this
% block. It takes the practice trial list practice.mat (which is always constant) and the first two
% pictures in the practice folder in the stimuli folder as targets.
function [ ] = runPractice()

disp('WELCOME TO runPractice')

global compKbDevice FALSE TRUE TRIAL_DURATION
global refRate NO_KEY VIS_TARGET_KEY LOW_PITCH_KEY HIGH_PITCH_KEY PITCH_DURATION HIGH_PITCH_FREQ LOW_PITCH_FREQ
global RESTART_KEY RESTART_MESSAGE ABORT_KEY YesKey ABORTED CLEAN_EXIT_MESSAGE practice_log
global STIM_DURATION practice_mat practice_aud_score warning_response_order EXTRA_PRACTICE
global RUN_PRACTICE PracticeHits PracticeFalseAlarms PracticeFalseAlarms_Irrelevant MinPracticeHits MaxPracticeHits MaxPracticeFalseAlarms MaxPracticeFalseAlarms_Irrelevant Practice_aud_accuracy_cutoff
global TotalScore FEEDBACK_MESSAGES_PRACTICE PRACTICE_FEEDBACK_MESSAGES

practice_mat = readtable([pwd,filesep,'TrialMatrices\practice_mat.csv']); % <- loads the practice matrix
[high_pitch_buff, low_pitch_buff, aud_pahandle] = init_audio_pitches(PITCH_DURATION, HIGH_PITCH_FREQ, LOW_PITCH_FREQ); % auditory

miniBlockNum = size(practice_mat,1);

% if practice is repeaded the order of the stimuli is shuffled 
if EXTRA_PRACTICE == 1
    practice_mat = ShuffleRows(practice_mat);
end

% Initializing trial:
tr = 1;
% Initializing number of hits and false alarms
PracticeHits=0;
PracticeFalseAlarms=0;
PracticeFalseAlarms_Irrelevant=0;
TotalScore=0;
warning_response_order = 0;


% initiate practice lot table
practice_log = table;
practice_log.trial_button_press(1,1) = nan;
practice_log.trial_button_press(1,2) = nan;

% loop through all trials; trials start from 0, so that trial 0 is
% actually trial 1, 1 is 2 etc.
while tr <= miniBlockNum

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

    if strcmp(practice_mat.SOA_lock{tr}, 'offset')
        trial_SOA = practice_mat.SOA(tr) + practice_mat.duration(tr);
    else
        trial_SOA = practice_mat.SOA(tr);
    end
    practice_log.trial_button_press(tr,:) = 0;

    RestartInterval = 0;

    if tr == 1
        showMiniBlockBeginScreen(practice_mat, tr);
        KbWait(compKbDevice,3);
        % Sending the first fixation with jitter of each mini-block. Here the participant cannot respond
        fixOnset = showFixation('PhotodiodeOff');
        WaitSecs(TRIAL_DURATION - trial_time - refRate/2); % the fixation wait
        JitOnset = showFixation('PhotodiodeOff');
        WaitSecs(jitter - refRate/2); % the jitter wait
    end

    % get texture pointer
    vis_stim_id = practice_mat.identity{tr};
    orientation = practice_mat.orientation{tr};
    texture_ptr = getPointer(vis_stim_id, orientation);

    % show stimulus
    practice_log.vis_stim_time(tr) = showStimuli(texture_ptr);

    % I then set a frame counter. The flip of the stimulus
    % presentation is frame 0. It is already the previous frame because it already occured:
    PreviousFrame = 0;
    % I then set a frame index. It is the same as the previous
    % frame for now
    FrameIndex = PreviousFrame;

    %% TIME LOOP
    elapsedTime = 0;
    while elapsedTime < TRIAL_DURATION - (refRate*(2/3)) + practice_mat.stim_jit(tr)
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
                [secs, keyCode, ~] =KbWait(compKbDevice,3);

                % Get the restart interval (the time it took
                % the experimenter to say he/she wants to
                % restart:
                RestartInterval = (secs - Resp_Time) - PauseTime; % Need to take the pause time into account, otherwise, we would be counting it twice down the line!

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
        if elapsedTime >= (trial_SOA - refRate*(2/3)) && pitchPlayed == FALSE

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
            fixShown = TRUE;
        end

        % Present jitter
        if elapsedTime > TRIAL_DURATION  - refRate*(2/3) && jitterLogged == FALSE
            jitterLogged = TRUE;
        end

        % Updating clock:
         elapsedTime = GetSecs - practice_log.vis_stim_time(tr);
    end
    
    %% End of trial

    % compute correctness visual task
    if strcmp(practice_mat.task_relevance{tr}, 'target') && hasInput_vis == TRUE
        PracticeHits = PracticeHits + 1;
    elseif ~strcmp(practice_mat.task_relevance{tr}, 'target') && hasInput_vis == TRUE
        PracticeFalseAlarms = PracticeFalseAlarms + 1;
        if strcmp(practice_mat.task_relevance, 'irrelevant')
            PracticeFalseAlarms_Irrelevant = PracticeFalseAlarms_Irrelevant + 1;
        end
    end

    % extract auditory response
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

    % check order of responses
    if practice_log.trial_button_press(tr,1) >= 1000 && practice_log.trial_button_press(tr,2) == 1
        warning_response_order = 1;
    end 

    % If the restart key was pressed, we break
    if (key == RESTART_KEY) % If there was a restart, tr = 0
        tr = 0;
    else % else, we simply continue
        tr =  tr + 1;
    end   
end

% calculate auditory accuracy
practice_aud_score = mean(practice_log.trial_accuracy_aud,'omitnan');

if(PracticeHits>=MinPracticeHits && PracticeFalseAlarms<=MaxPracticeFalseAlarms &&...
        PracticeFalseAlarms_Irrelevant==MaxPracticeFalseAlarms_Irrelevant && practice_aud_score>=Practice_aud_accuracy_cutoff)
    RUN_PRACTICE=0;
else
    RUN_PRACTICE=1;
end

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
feedback_message_flag1 = not(HitsScore/4 <= 0.5 || FAScore/3 <= 0.5 || IrrelevantCategoryFAScore < 3 || Practice_aud_accuracy_cutoff > practice_aud_score);
feedback_message_flag2 = HitsScore/4 <= 0.5;
feedback_message_flag3 = FAScore/3 <= 0.5;
feedback_message_flag4 = IrrelevantCategoryFAScore < 3;

PRACTICE_FEEDBACK_MESSAGES=FEEDBACK_MESSAGES_PRACTICE(find([feedback_message_flag1 feedback_message_flag2 (feedback_message_flag3 || feedback_message_flag4)]));


end % end function RunPractice
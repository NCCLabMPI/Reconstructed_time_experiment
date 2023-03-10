%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear;

% Hardware parameters:
global TRUE FALSE refRate w viewDistance compKbDevice practice_mat practice_log
global MEEG EYE_TRACKER NO_PRACTICE subjectNum introspec
global NUMBER_OF_TOTAL_TRIALS TRIAL_DURATION RUN_PRACTICE
global LOADING_MESSAGE RESTART_MESSAGE CLEAN_EXIT_MESSAGE PRACTICE_START_MESSAGE SAVING_MESSAGE END_OF_EXPERIMENT_MESSAGE RESTARTBLOCK_OR_MINIBLOCK_MESSAGE
global YesKey ABORTED RESTART_KEY NO_KEY ABORT_KEY VIS_TARGET_KEY LOW_PITCH_KEY HIGH_PITCH_KEY
global HIGH_PITCH_FREQ LOW_PITCH_FREQ PITCH_DURATION RESP_ORDER_WARNING_MESSAGE RESOLUTION_FORCE

subjectNum = 119;

viewDistance = 60;
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
initConstantsParameters(subjectNum); % defines all constants and initilizes parameters of the program
screenError = initPsychtooblox(); % initializes psychtoolbox window at correct resolution and refresh rate
if introspec == TRUE
    handle = PsychPowerMate('Open'); % open dial
    calibration(10)
end

% if refresh rate is not as intended
if screenError && RESOLUTION_FORCE
    showError('WARNING: screen refresh rate is not optimal !');
end

%% Initialize experimental design
try
    ABORTED = 0;

    % load stimuli
    showMessage(LOADING_MESSAGE);
    loadStimuli() % visual
    [high_pitch_buff, low_pitch_buff, aud_pahandle] = init_audio_pitches(PITCH_DURATION, HIGH_PITCH_FREQ,  LOW_PITCH_FREQ); % auditory
    
    % Saves a copy of code to disk
    saveCode()

    % open trial matrix (form Experiment 1) and add auditory conditions
    MatFolderName = [pwd,filesep,'TrialMatrices\'];
    TableName = ['SX',num2str(subjectNum),'_TrialMatrix.csv'];
    trial_mat = readtable(fullfile(MatFolderName, TableName));
    trial_mat = addAudStim(trial_mat);

    %% Instructions and practice:
    % displays instructions
    Instructions();
    if ~NO_PRACTICE
        % Show the practice messages:
        showMessage(PRACTICE_START_MESSAGE);
        KbWait(compKbDevice,3);
        RUN_PRACTICE = 1;
        % Launching the practice loop:
        getPracticeFeedback();

    end


    %% save everything from command window
    Str = CmdWinTool('getText');
    dlmwrite(dfile,Str,'delimiter','');

    %% Experiment Prep

    % initiate log table in desired order of columns
    log_table = trial_mat;
    log_table.onset_SOA(:) = nan;
    log_table.texture(:) = nan;
    log_table.vis_stim_time(:) = nan;
    log_table.time_of_resp_vis(:) = nan;
    log_table.has_repsonse_vis(:) = 0;
    log_table.trial_repsonse_vis{1} = 'empty';
    log_table.aud_stim_buff(:) = nan;
    log_table.aud_stim_time(:) = nan;
    log_table.aud_resp(:) = nan;
    log_table.trial_accuracy_aud(:) = nan;
    log_table.time_of_resp_aud(:) = nan;
    log_table.trial_first_button_press(:) = 0;
    log_table.trial_second_button_press(:) = 0;
    log_table.fix_time(:) = nan;
    log_table.JitOnset(:) = nan; 
    log_table.trial_end(:) = nan;

    log_hasInputs_vis = nan(1,length(trial_mat.trial));

    % calculate SOA from onset
    for tr = 1:length(trial_mat.trial)
        if strcmp(trial_mat.SOA_lock{tr}, 'offset')
            log_table.onset_SOA(tr) = trial_mat.SOA(tr) + trial_mat.duration(tr);
        else
            log_table.onset_SOA(tr) = trial_mat.SOA(tr);
        end
    end

    %
    previous_miniblock = 0;
    warning_response_order = 0;

  %%  Experiment

    showFixation('PhotodiodeOff')
    for tr = 1:length(trial_mat.trial)
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.

        %% Start of miniblock

        % For every new miniblock, show target screen and send out triggers
        current_miniblock = trial_mat.block(tr);
        if current_miniblock > previous_miniblock
            previous_miniblock = current_miniblock;

            % check order of responses
            if warning_response_order == 1
                showMessage(RESP_ORDER_WARNING_MESSAGE)
                WaitSecs(2)
                warning_response_order = 0;
            end

            % Showing the miniblock begin screen. This is the target screen
            log_table.TargetScreenOnset(tr) = showMiniBlockBeginScreen(trial_mat, tr);
%             if MEEG %for MEEG, wait 5 seconds max
                 KbWait(compKbDevice,3,WaitSecs(0)+5);
%             end
% 
%             % Just before we really get started, the MB number is sent to
%             % via the LPT trigger:
%             if MEEG
%                 sendTrig(TRG_MB_ADD+miniBlockNum, LPT_OBJECT,LPT_ADDRESS);
%                 WaitSecs(refRate);
%                 sendTrig(0, LPT_OBJECT,LPT_ADDRESS);
%                 WaitSecs(refRate);
%             end
% 
%             if EYE_TRACKER
%                 if ~TOBII_EYETRACKER
%                     Eyelink('Message',num2str(TRG_MB_ADD+miniBlockNum));
%                 else
%                     tobii_TimeCell(end+1,:) = {tobii.get_system_time_stamp,num2str(TRG_MB_ADD+miniBlockNum)};
%                 end
%             end


              fixOnset = showFixation('PhotodiodeOff'); % 1
              WaitSecs(rand*2)

        end

        %%

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
        vis_stim_id = trial_mat.identity{tr};
        orientation = trial_mat.orientation{tr};
        texture_ptr = getPointer(vis_stim_id, orientation);
        log_table.texture(tr) = texture_ptr;

        % show stimulus
        log_table.vis_stim_time(tr) = showStimuli(texture_ptr);

        % I then set a frame counter. The flip of the stimulus
        % presentation is frame 0. It is already the previous frame because it already occured:
        PreviousFrame = 0;
        % I then set a frame index. It is the same as the previous
        % frame for now
        FrameIndex = PreviousFrame;

         %--------------------------------------------------------
        
        %% TIME LOOP
        elapsedTime = 0;
        while elapsedTime < TRIAL_DURATION - (refRate*(2/3)) + trial_mat.stim_jit(tr)
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

                % Restarting and interruption keys treatment
                % If there was a pause, log it in the output table:
                %         if PauseTime > 0 &&  PauseTimeLogged == FALSE
                %             setOutputTable ('Pause', miniBlocks, miniBlockNum, tr, RT, PauseTime)
                %             PauseTimeLogged = TRUE;
                %         end

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
                        showMessage(RESTARTBLOCK_OR_MINIBLOCK_MESSAGE)
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
                if key ~= NO_KEY && key ~= log_table.trial_first_button_press(tr)

                    % Sending the response triggers first to get best
                    % timing:
                    % Sending response trigger for MEEG:
                    if MEEG sendResponseTrig(); end

                    % Sending response trigger for the eyetracker
                    if EYE_TRACKER
                        if ~TOBII_EYETRACKER
                            Eyelink('Message',num2str(TRG_RESPONSE));
                        else
                            tobii_TimeCell(end+1,:) = {tobii.get_system_time_stamp,num2str(TRG_RESPONSE)};
                        end
                    end

                    % logging reaction
                    hasInputs = hasInputs + 1;
                    log_hasInputs_vis(tr) = hasInputs;

                    % Log the response received:
                    if  hasInputs == 0
                        log_table.trial_first_button_press(tr) = key;
                    else
                        log_table.trial_second_button_press(tr) = key;
                    end

                    % store RT for visual task
                    if key == VIS_TARGET_KEY && hasInput_vis == FALSE % taget key was pressed
                        log_table.time_of_resp_vis(tr) =  Resp_Time;
                        log_table.has_repsonse_vis(tr) = 1;
                        hasInput_vis = TRUE;
                   
                    % store RT for auditory task
                    elseif (key == LOW_PITCH_KEY || key == HIGH_PITCH_KEY) && hasInput_aud == FALSE % auditory key was pressed
                        log_table.time_of_resp_aud(tr) =  Resp_Time;
                        hasInput_aud = TRUE;

                    elseif  ~ismember(key,[VIS_TARGET_KEY, LOW_PITCH_KEY, HIGH_PITCH_KEY])
                        log_table.wrong_key(tr) =  key;
                        log_table.wrong_key_timestemp(tr) =  Resp_Time;

                    end
                end
            end

            %% audio stimulus

            % Play pitch
            if elapsedTime >= (log_table.onset_SOA(tr) - refRate*(2/3)) && pitchPlayed == FALSE

                pitch_buff = eval([trial_mat.pitch{tr},'_pitch_buff']);
                PsychPortAudio('FillBuffer', aud_pahandle, pitch_buff);

                % And then you play the buffer. The function returns a time stamp.
                % Here I don't use it but for our purpose we will want to log it:
                PsychPortAudio('Start',aud_pahandle, 1, 0);
                log_table.aud_stim_time(tr) = GetSecs;
                log_table.aud_stim_buff(tr) = pitch_buff;

                pitchPlayed = TRUE;

            end

            %% Inter stimulus interval 
            % Present fixation
            if elapsedTime >= (trial_mat.duration(tr) - refRate*(2/3)) && fixShown == FALSE
                fix_time = showFixation('PhotodiodeOn');

                % log fixation in journal
                log_table.fix_time(tr) = fix_time;
                fixShown = TRUE;
            end

            % Present jitter
            if elapsedTime > TRIAL_DURATION  - refRate*(2/3) && jitterLogged == FALSE
                JitOnset = showFixation('PhotodiodeOn');

                % log jitter started
                log_table.JitOnset(tr) = JitOnset;
                jitterLogged = TRUE;
            end

            % Updating clock:
            % update time since iteration begun. Subtract the time
            % of the pause to the elapsed time, because we don't
            % want to have it in there. If there was no pause, then
            % pause time = 0
            elapsedTime = GetSecs - log_table.vis_stim_time(tr);
        end
        log_table.trial_end(tr) = GetSecs;

        %% End of trial

        % check order of responses
        if log_table.trial_first_button_press(tr) >= 1000 && log_table.trial_second_button_press(tr) == 1
            warning_response_order = 1;
        end

        if introspec == TRUE
           % introspective question 1 (RT visual task)
           introspec_question = 'vis';
           log_table.iRT_vis(tr) = run_dial(introspec_question);

           showFixation()
           WaitSecs(1)

           % introspective question 2 (RT auditory task)
           introspec_question = 'aud';
           log_table.iRT_aud(tr) = run_dial(introspec_question);
        end

        % If the restart key was pressed, we break
 
        % miniblock and block ctr accordingly:
%         if(key==RESTART_KEY)
%             % Set the interrupt flag to 1
%             InterruptFlag=1;
%             
%            if BlkOrminiBlk_keyCode(MINIBLOCK_RESTART_KEY) % If the experimenter only wants to go back to the miniBlock:
%                 if mod(miniBlockNum,4) == 1
%                     Block_ctr=floor((miniBlockNum)/4);
%                 end
%             else BlkOrminiBlk_keyCode(BLOCK_RESTART_KEY) % If the experimenter only wants to go back to the miniBlock:
%                 miniBlockNum=1+4*(floor((miniBlockNum-1)/4));
%                 Block_ctr=floor(miniBlockNum/4);
%             end
%         else% Resetting the restarting flag (in case it wasn't already)
%             InterruptFlag=0;
%             % Actualizing the miniBlock counter
%             miniBlockNum=miniBlockNum+1;
%         end
       
        if(key==RESTART_KEY)
            break
        end

    end

    %% End of experiment 

    % Letting the participant that it is over:
    showMessage(END_OF_EXPERIMENT_MESSAGE);
    WaitSecs(2)

    showMessage(SAVING_MESSAGE);
    % Mark the time of saving onset
    ttime = GetSecs;

    % compute performances of tasks
    [log_table, performance_struct] = compute_performance(log_table);

    % save everything from command window
    Str = CmdWinTool('getText');
    dlmwrite(dfile,Str,'delimiter','');

    % save log_table
    saveLog_table(log_table);

    if DEBUG
        disp(sprintf('Saving took : %f \n',GetSecs - ttime));
    end

    safeExit()
catch e

    try
        try
            % try calculating performances
            [log_table, performance_struct] = compute_performance(log_table);

            % save log_table
            saveLog_table(log_table);
            ttime = GetSecs;
            if DEBUG disp(sprintf('Saving took : %f \n',GetSecs - ttime)); end

        catch
            % save log_table without calculated performances
            saveLog_table(log_table);
            ttime = GetSecs;
            if DEBUG disp(sprintf('Saving took : %f \n',GetSecs - ttime)); end

        end

    catch
        warning('-----  Data could not be saved!  ------')
        safeExit()
        rethrow(e);
    end
    safeExit()
    rethrow(e);

end
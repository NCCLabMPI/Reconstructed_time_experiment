%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear;

subNum = 1;

% Hardware parameters:
global TRUE FALSE refRate w viewDistance compKbDevice
global MEEG EYE_TRACKER
global NUMBER_OF_TOTAL_TRIALS TRIAL_DURATION
global LOADING_MESSAGE RESTART_MESSAGE CLEAN_EXIT_MESSAGE
global ABORTED RESTART_KEY NO_KEY ABORT_KEY VIS_TARGET_KEY
global HIGH_PITCH_FREQ LOW_PITCH_FREQ PITCH_DURATION

viewDistance = 60;
% Add functions folder to path (when we separate all functions)
function_folder = [pwd,filesep,'functions\'];
addpath(function_folder)

%% Initializing experimental parameters and PTB:
initRuntimeParameters
initConstantsParameters(subNum); % defines all constants and initilizes parameters of the program
screenError = initPsychtooblox(); % initializes psychtoolbox window at correct resolution and refresh rate

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

    % open trial matrix (form Experiment 1) and add auditory conditions
    MatFolderName = [pwd,filesep,'TrialMatrices\'];
    TableName = 'SX103_TrialMatrix.csv';
    trial_mat = readtable(fullfile(MatFolderName, TableName));
    trial_mat = addAudStim(trial_mat);

    % initialise log table
    log_table = table;

    %% Main loop

    %
    misses = 0;
    hits = 0;
    fa = 0;
    cr = 0; % correct rejection
    previous_miniblock = 0;

    showFixation('PhotodiodeOff')
    for tr = 1:length(trial_mat.block)
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.

        %% Start of miniblock

        % For every new miniblock, show target screen and send out triggers
        current_miniblock = trial_mat.block(tr);
        if current_miniblock > previous_miniblock
            previous_miniblock = current_miniblock;

            % Showing the miniblock begin screen. This is the target screen
            TargetScreenOnset = showMiniBlockBeginScreen(trial_mat, tr);
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
              WaitSecs(rand*5)

        end

        %%

        % flags needs to be initialized
        fixShown = FALSE;
        pitchPlayed = FALSE;
        jitterLogged = FALSE;
        hasInput = FALSE; % input flag, marks if participant already replied
        PauseTime = 0; % If the experiment is paused, the duration of the pause is stored to account for it.

        % get texture pointer
        vis_stim_id = trial_mat.identity{tr};
        orientation = trial_mat.orientation{tr};
        texture_ptr = getPointer(vis_stim_id, orientation);
        log_table.texture(tr) = texture_ptr;

        % show stimulus
        vis_stim_time = showStimuli(texture_ptr);
        log_table.vis_stim_time(tr) = vis_stim_time;


        % I then set a frame counter. The flip of the stimulus
        % presentation is frame 0. It is already the previous frame because it already occured:
        PreviousFrame = 0;
        % I then set a frame index. It is the same as the previous
        % frame for now
        FrameIndex = PreviousFrame;

        % Log the stimulus presentation in the output table
        %     setOutputTable('Stimulus', miniBlocks, miniBlockNum, tr, miniBlocks{miniBlockNum,TRIAL1_START_TIME_COL + tr}); %setting all the trial values in the output table

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

            if hasInput == FALSE
                [key,RT,PauseTime] = getInput(PauseTime);

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
                    RestartInterval = (secs - RT) - PauseTime; % Need to take the pause time into account, otherwise, we would be counting it twice down the line!

                    % If the experimenter wants to restart, log it:
                    if(keyCode(YesKey))
%                 setOutputTable ('Interruption', miniBlocks, miniBlockNum, tr, secs)
                        break

                    else % Else, continue:
                        key=NO_KEY;
                    end
                elseif (key == ABORT_KEY) % If the experiment was aborted:
%             setOutputTable ('Abortion', miniBlocks, miniBlockNum, tr, RT, PauseTime)
                    ABORTED = 1;
                    error(CLEAN_EXIT_MESSAGE);
                end

                % -----------------------------------------------------
                % Responses keys treatment (needs to be separated from
                % above, because above can change the key input
                % depending on what's pressed, i.e. pursuing after
                % clicking restart)

                % Log the response received:
                log_table.trial_button_press{tr} = key;

                % If the participant pressed a key:
                if key ~= NO_KEY

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

                    % Logging the reaction time:
                    log_table.trial_RT(tr) =  RT - log_table.vis_stim_time(tr);
                    hasInput = TRUE; % Flagging the input

                    % Logging whether the response was correct:
                    if key == VIS_TARGET_KEY % taget key was pressed
                        log_table.trial_answer_vis(tr) = strcmp(trial_mat.trial_type{tr}, 'target');
                        if log_table.trial_answer_vis(tr)
                            hits = hits + 1;
                            log_table.trial_repsonse_vis{tr} ='hit';
                        else
                            fa = fa + 1;
                            log_table.trial_repsonse_vis{tr} ='fa';
                        end
                     end
                    % log response in journal
%                     setOutputTable('Response', miniBlocks, miniBlockNum, tr, RT);
                else % no key was pressed
%                     log_table.trial_answer_vis(tr) = ~strcmp(trial_mat.trial_type{tr}, 'target');
                end


            end

            % Play pitch
            if elapsedTime >= (trial_mat.SOA(tr) - refRate*(2/3)) && pitchPlayed == FALSE

                before_pitch = GetSecs;
                pitch_buff = eval([trial_mat.pitch{tr},'_pitch_buff']);
                PsychPortAudio('FillBuffer', aud_pahandle, pitch_buff);

                % And then you play the buffer. The function returns a time stamp.
                % Here I don't use it but for our purpose we will want to log it:
                log_table.aud_stim_time(tr) = PsychPortAudio('Start',aud_pahandle, 1, 0);
                log_table.aud_stim_time2(tr) = GetSecs;
                log_table.aud_stim_buff(tr) = pitch_buff;

                % potentially log apitch in journal
%             setOutputTable('Fixation', miniBlocks, miniBlockNum, tr, miniBlocks{miniBlockNum,TRIAL1_STIM_END_TIME_COL + tr}); %setting all the trial values in the output table
 
                pitchPlayed = TRUE;

                after_pitch = GetSecs;
                pitch_dur(tr) = after_pitch - before_pitch;
            end

            % Present fixation
            if elapsedTime >= (trial_mat.duration(tr) - refRate*(2/3)) && fixShown == FALSE
                fix_time = showFixation('PhotodiodeOn');

                % log fixation in journal
%             setOutputTable('Fixation', miniBlocks, miniBlockNum, tr, miniBlocks{miniBlockNum,TRIAL1_STIM_END_TIME_COL + tr}); %setting all the trial values in the output table
                log_table.fix_time(tr) = fix_time;
                fixShown = TRUE;
            end

            % Present jitter
            if elapsedTime > TRIAL_DURATION  - refRate*(2/3) && jitterLogged == FALSE
                JitOnset = showFixation('PhotodiodeOn');

                % log jitter started
                %             setOutputTable('Jitter', miniBlocks, miniBlockNum, tr, JitOnset);
                log_table.JitOnset(tr) = JitOnset;
                jitterLogged = TRUE;
            end

            % Updating clock:
            % update time since iteration begun. Subtract the time
            % of the pause to the elapsed time, because we don't
            % want to have it in there. If there was no pause, then
            % pause time = 0
            elapsedTime = GetSecs - vis_stim_time;
        end
        log_table.trial_end(tr) = GetSecs;

        %% End of trial
        % If the restart key was pressed, we break
        if(key==RESTART_KEY)
            break
        end

        % if trial ended and no input, logs as CR or miss
        if ~strcmp(trial_mat.trial_type{tr}, 'target') && hasInput == FALSE
            cr = cr + 1;
            log_table.trial_repsonse_vis{tr} ='cr';
        elseif strcmp(trial_mat.trial_type{tr}, 'target') && hasInput == FALSE
            misses = misses + 1;
            log_table.trial_repsonse_vis{tr} ='miss';
        end

        % write some stuff in log table
        log_table.trial_type{tr} = trial_mat.trial_type{tr};
    end

    % save trial_mat table
    writetable(trial_mat,fullfile(MatFolderName, 'reconstructed_time_trial_mat.csv'))

catch e
    %     try

    ttime = GetSecs;
    %         saveTrialBackupToHD(miniBlocks,1,'Backup');
    %         saveBlockToHD(OUTPUT_TABLE,miniBlockNum,'Results',tr);
    %         % Save the different data to excel:
    %         saveBlockToExcel(OUTPUT_TABLE,miniBlockNum,tr);
    %         saveSummaryToExcel(OUTPUT_TABLE, 1);
    %         if VERBOSE disp('saving because user quit'); end
    %         if DEBUG disp(sprintf('Saving took : %f \n',GetSecs - ttime)); end
    %     catch
    %     end
    safeExit()
    rethrow(e);

end


%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear;

subNum = 1;

% Hardware parameters:
global  TRUE FALSE refRate w viewDistance 
global MEEG EYE_TRACKER 
global NUMBER_OF_TOTAL_TRIALS TRIAL_DURATION
global LOADING_MESSAGE RESTART_MESSAGE CLEAN_EXIT_MESSAGE
global ABORTED RESTART_KEY NO_KEY ABORT_KEY

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

%% Loading stimuli
try
    ABORTED = 0;
    showMessage(LOADING_MESSAGE);

    % path to stimuli folder
    PreFolderName = [pwd,filesep,'stimuli\'];
    cat_names = {'char', 'face', 'false', 'object'};
    ori_names = {'center', 'left', 'right'};
    gender_names = {'male', 'female'};
    % stimulus_id = {"face_1", "face_2"}

    cat_struct = struct('center', 1:20, 'left', 1:20, 'right', 1:20);
    texture_struct = struct('char', cat_struct, 'face', cat_struct, 'false', cat_struct, 'object', cat_struct);


    % loops through the folders an loads all stimuli
    for j = 1:length(cat_names)
        for jj = 1:length(ori_names)
            if j == 2 % 3rd for loop only for faces
                for jjj = 1:length(gender_names)
                    FolderName = fullfile(PreFolderName, cat_names{j},ori_names{jj}, gender_names{jjj});
                    new_textures = getTexturesFromHD(FolderName, w);
                    texture_struct.(cat_names{j}).(ori_names{jj})(10*jjj-9:10*jjj) = new_textures;
                end
            else
                FolderName = fullfile(PreFolderName, cat_names{j}, ori_names{jj});
                new_textures = getTexturesFromHD(FolderName, w);
                texture_struct.(cat_names{j}).(ori_names{jj})(1:20) = new_textures;
            end
        end
    end

    % open trial matrix
    MatFolderName = [pwd,filesep,'TrialMatrices\'];
    trial_mat = readtable(fullfile(MatFolderName, 'reconstructed_time_trial_mat.csv'));

    % get jitter
    jitter = getJitter(NUMBER_OF_TOTAL_TRIALS);

    % initialise log table
    log_table = table;

    %% Main loop

    showFixation('PhotodiodeOff')
    for tr = 1:length(trial_mat.trial)
        % Draw the image to the screen, unless otherwise specified PTB will draw
        % the texture full size in the center of the screen. We first draw the
        % image in its correct orientation.

        % flags needs to be initialized
        fixShown = FALSE;
        jitterLogged = FALSE;
        hasInput = FALSE; % input flag, marks if participant already replied
        PauseTime = 0; % If the experiment is paused, the duration of the pause is stored to account for it.

        % get texture
        vis_stim_id = trial_mat.vis_stim_id{tr};
        vis_stim_num = str2double(extractBetween(vis_stim_id,strlength(vis_stim_id)-1,strlength(vis_stim_id)));
        texture = texture_struct.(trial_mat.vis_stim_cate{tr}).(trial_mat.vis_stim_orientation{tr})(vis_stim_num);
        log_table.texture(tr) = texture;

        % show stimulus
        vis_stim_time = showStimuli(texture);
        log_table.vis_stim_time(tr) = vis_stim_time;

        % I then set a frame counter. The flip of the stimulus
        % presentation is frame 0. It is already the previous frame because it already occured:
        PreviousFrame = 0;
        % I then set a frame index. It is the same as the previous
        % frame for now
        FrameIndex = PreviousFrame;

        % Log the stimulus presentation in the output table
        %     setOutputTable('Stimulus', miniBlocks, miniBlockNum, tr, miniBlocks{miniBlockNum,TRIAL1_START_TIME_COL + tr}); %setting all the trial values in the output table

        elapsedTime = 0;
        while elapsedTime < TRIAL_DURATION - (refRate*(2/3)) + jitter(tr)
            % In order to count the frames, I always convert the
            % time to frames by dividing it by the refresh rate:
            CurrentFrame = floor(elapsedTime/refRate);

            % If the current frame number is different from the
            % previous, then a new frame started so I send the new triggers:
            if CurrentFrame > PreviousFrame
                FrameIndex = FrameIndex +1;
                PreviousFrame = CurrentFrame;
            end


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
                log_table.trial_button_press(tr) = key;

                % If the participant pressed a key:
                if key ~= NO_KEY

                    % -------------------------------------------------
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

%                     % Logging whether the response was correct:
%                     if key == TARGET_KEY % taget key was pressed
%                         miniBlocks{miniBlockNum,TRIAL1_ANSWER_COL + tr} = isTarget(miniBlocks,miniBlockNum,tr);
%                         if miniBlocks{miniBlockNum,TRIAL1_ANSWER_COL + tr}
%                             hits = hits + 1;
%                         else
%                             fa = fa + 1;
%                         end
%                     else % other key was pressed
%                         % I take any wrong key as a legitimate button press
%                         miniBlocks{miniBlockNum,TRIAL1_ANSWER_COL + tr} = isTarget(miniBlocks,miniBlockNum,tr);
%                         if miniBlocks{miniBlockNum,TRIAL1_ANSWER_COL + tr}
%                             hits = hits + 1;
%                         else
%                             fa = fa + 1;
%                         end
%                         miniBlocks{miniBlockNum,TRIAL1_ANSWER_COL + tr} = WRONG_KEY;
%                     end
%                     % log response in journal
%                     setOutputTable('Response', miniBlocks, miniBlockNum, tr, RT);
%                 else % no key was pressed
%                     miniBlocks{miniBlockNum,TRIAL1_ANSWER_COL + tr} = ~isTarget(miniBlocks,miniBlockNum,tr);
                end


            end

            % Present fixation
            if elapsedTime >= (trial_mat.vis_stim_dur(tr) - refRate*(2/3)) && fixShown == FALSE
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

            % f. Updating clock:
            % update time since iteration begun. Subtract the time
            % of the pause to the elapsed time, because we don't
            % want to have it in there. If there was no pause, then
            % pause time = 0
            elapsedTime = GetSecs - vis_stim_time;

        end
        log_table.trial_end(tr) = GetSecs;
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


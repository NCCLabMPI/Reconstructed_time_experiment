%% Housekeeping:
% Clearing the command window before we start saving it
sca;
close all;
clear;

subNum = 1;

% Hardware parameters:
global LOADING_MESSAGE refRate w gray viewDistance  TRUE FALSE 
global NUMBER_OF_TOTAL_TRIALS TRIAL_DURATION

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


%% Main loop

showFixation('PhotodiodeOff')
for k = 1:length(trial_mat.trial)
    % Draw the image to the screen, unless otherwise specified PTB will draw
    % the texture full size in the center of the screen. We first draw the
    % image in its correct orientation.

    % flags needs to be initialized
    fixShown = FALSE;
    jitterLogged = FALSE;

    % get texture
    vis_stim_id = trial_mat.vis_stim_id{k};
    vis_stim_num = str2double(extractBetween(vis_stim_id,strlength(vis_stim_id)-1,strlength(vis_stim_id)));
    texture = texture_struct.(trial_mat.vis_stim_cate{k}).(trial_mat.vis_stim_orientation{k})(vis_stim_num);
    log_struct.texture(k) = texture;

    % show stimulus
    stim_time = showStimuli(texture);
    log_struct.stim_time(k) = stim_time;

    % I then set a frame counter. The flip of the stimulus
    % presentation is frame 0. It is already the previous frame because it already occured:
    PreviousFrame = 0;
    % I then set a frame index. It is the same as the previous
    % frame for now
    FrameIndex = PreviousFrame;

    % Log the stimulus presentation in the output table
%     setOutputTable('Stimulus', miniBlocks, miniBlockNum, tr, miniBlocks{miniBlockNum,TRIAL1_START_TIME_COL + tr}); %setting all the trial values in the output table

    elapsedTime = 0;
    while elapsedTime < TRIAL_DURATION - (refRate*(2/3)) + jitter(k)
        % In order to count the frames, I always convert the
        % time to frames by dividing it by the refresh rate:
        CurrentFrame = floor(elapsedTime/refRate);

        % If the current frame number is different from the
        % previous, then a new frame started so I send the new triggers:
        if CurrentFrame > PreviousFrame
            FrameIndex = FrameIndex +1;
            PreviousFrame = CurrentFrame;
        end


        % Here the getInput function might be placed later


        % Present fixation
        if elapsedTime >= (trial_mat.vis_stim_dur(k) - refRate*(2/3)) && fixShown == FALSE
           fix_time = showFixation('PhotodiodeOn');

            % log fixation in journal
%             setOutputTable('Fixation', miniBlocks, miniBlockNum, tr, miniBlocks{miniBlockNum,TRIAL1_STIM_END_TIME_COL + tr}); %setting all the trial values in the output table
            log_struct.fix_time(k) = fix_time;
            fixShown = TRUE;
        end

        % Present jitter
        if elapsedTime > TRIAL_DURATION  - refRate*(2/3) && jitterLogged == FALSE
            JitOnset = showFixation('PhotodiodeOn');

            % log jitter started
            %             setOutputTable('Jitter', miniBlocks, miniBlockNum, tr, JitOnset);
            log_struct.JitOnset(k) = JitOnset;
            jitterLogged = TRUE;
        end

        % f. Updating clock:
        % update time since iteration begun. Subtract the time
        % of the pause to the elapsed time, because we don't
        % want to have it in there. If there was no pause, then
        % pause time = 0
        elapsedTime = GetSecs - stim_time;

    end
    log_struct.trial_end(k) = GetSecs;
end

% save trial_mat table
writetable(trial_mat,fullfile(MatFolderName, 'reconstructed_time_trial_mat.csv'))  

sca;


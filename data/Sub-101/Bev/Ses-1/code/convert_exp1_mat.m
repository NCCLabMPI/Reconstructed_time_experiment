%% Set fixed parameters
matrices_root = "C:\Users\alexander.lepauvre\Seafile\TWCF_Project\Experiment1Development\TrialMatrices\SX";
trial_n_col = 7;
target_1_col = 5;
target_2_col = 6;
stim_id_col = 13;
trial_dur_col = 51;
jitter_dur_col = 203;
save_root = fullfile(pwd, 'TrialMatrices');
sub_prefix = 'SX';

%% Loop through each generated file:
trial_mat_files = dir(matrices_root);
sub_ctr = 1;
for i=1:length(trial_mat_files)
    if ~contains(trial_mat_files(i).name, 'TrialMatrix.mat')
        continue
    end
    sub_id = 100 + sub_ctr;
    sub_ctr = sub_ctr + 1;
    % Load current matrix:
    load(fullfile(matrices_root, trial_mat_files(i).name));
    % Get the number of blocks:
    n_blocks = size(data, 1);
    trials_table = cell2table(cell(0,8), 'VariableNames', ...
        {'block', 'target_1', 'target_2', 'category', 'orientation', 'identity', ...
        'duration', 'stim_jit'});
    % looping through each mini block:
    for ii=1:n_blocks
        % Get the number of trials:
        n_trials = data{ii, trial_n_col};
        % Extract the targets:
        tar_1 = string(data{ii, target_1_col});
        tar_2 = string(data{ii, target_2_col});
        % Get the ID of each:
        if tar_1{1}(1) == '1'
            tar_1_cate = 'face';
        elseif tar_1{1}(1) == '2'
            tar_1_cate = 'object';
        elseif tar_1{1}(1) == '3'
            tar_1_cate = 'letter';
        elseif tar_1{1}(1) == '4'
            tar_1_cate = 'false_font';
        end
        if tar_2{1}(1) == '1'
            tar_2_cate = 'face';
        elseif tar_2{1}(1) == '2'
            tar_2_cate = 'object';
        elseif tar_2{1}(1) == '3'
            tar_2_cate = 'letter';
        elseif tar_2{1}(1) == '4'
            tar_2_cate = 'false_font';
        end
        tar_1 = char(join([tar_1_cate, string(tar_1{1}(3:4))], '_'));
        tar_2 = char(join([tar_2_cate, string(tar_2{1}(3:4))], '_'));
        
        % Extract all trials_ids, jitters and durations:
        trials_ids = data(ii, stim_id_col:stim_id_col+n_trials-1)';
        trials_dur = data(ii, trial_dur_col:trial_dur_col+n_trials-1)';
        trials_jit = data(ii, jitter_dur_col:jitter_dur_col+n_trials-1)';
        
        % Converting the trial ID numbers back to interpretable
        % descriptions:
        cate = cell(size(trials_ids, 1), 1);
        ori = cell(size(trials_ids, 1), 1);
        identity = cell(size(trials_ids, 1), 1);
        for iii=1:size(trials_ids, 1)
            % Get the numbers:
            trial_id = string(trials_ids{iii});
            % Extract the category:
            if trial_id{1}(1) == '1'
                cate{iii} = 'face';
            elseif trial_id{1}(1) == '2'
                cate{iii} = 'object';
            elseif trial_id{1}(1) == '3'
                cate{iii} = 'letter';
            elseif trial_id{1}(1) == '4'
                cate{iii} = 'false_font';
            end
            % Extract orientation:
            if trial_id{1}(2) == '1'
                ori{iii} = 'center';
            elseif trial_id{1}(2) == '2'
                ori{iii} = 'left';
            elseif trial_id{1}(2) == '3'
                ori{iii} = 'right';
            end
            % Finally, the identity:
            identity{iii} = char(join([cate{iii}, string(trial_id{1}(3:4))], '_'));
        end
        % Convert to long format:
        block_table = cell2table([num2cell(repmat(ii, size(trials_ids, 1), 1)) ...
            repmat({tar_1}, size(trials_ids, 1), 1) ...
            repmat({tar_2}, size(trials_ids, 1), 1) ...
            cate ori identity trials_dur trials_jit], ...
            'VariableNames', {'block', 'target_1', 'target_2', 'category', ...
            'orientation', 'identity', 'duration', 'stim_jit'});
        trials_table = [trials_table; block_table];
    end
    % Save the table to a csv file:
    writetable(trials_table, fullfile(save_root, sprintf('%s%d_TrialMatrix.csv', sub_prefix, sub_id)))
end

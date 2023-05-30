%% Set constant parameters:
n_subjects = 50;
lab_id = "SX";
task = "introspection";
% List the tasks. Only the introspection requires randomization:
tasks = ["auditory", "visual", "auditory_and_visual", "introspection"];

% Set all the conditions:
conditions = ['task_relevance', 'duration', 'category', 'orientation', ...
    'identity', 'pitch', 'SOA', 'SOA_lock'];
% Create a structure storing the levels of each of these conditions:
conditions_levels = struct(...
    'task_relevance', ["non-target", "irrelevant"],...
    'duration', [0.500, 1.000, 1.500], ...
    'category', ["face", "object", "letter", "false_font"], ...
    'orientation', ["center", "left", "right"], ...
    'identity', ["_01", "_02", "_03", "_04", "_05", "_06", ...
    "_07", "_08", "_09", "_10", "_11", "_12", "_13", "_14",...
    "_15", "_16", "_17", "_18", "_19", "_20"], ...
    'pitch', [1000, 1100],...
    'SOA', [0,0.232,0.466], ...
    'SOA_lock', ["onset", "offset"]);

% Create the jitter array:
jitter_mean = 1;
jitter_min = 0.7;
jitter_max = 2;
exp_dist = makedist("Exponential", "mu", jitter_mean);
jitter_distribution = truncate(exp_dist, jitter_min, jitter_max);
% Counter balancing perfectly within the following conditions:
counter_balance_conditions = ["task_relevance", "duration", "SOA", "SOA_lock"];
% 24 trials within each of the counter balanced conditions:
n_trials_each = 24;
% Experiment is divided in runs, each has 18 18 task relevant trials and 18
% task irrelevant trials:
n_trials_per_blk = 36;

% One last detail is that we should have twice as many trials for the
% center orientation as the left and right:
orientation_prop = [1/2, 1/4, 1/4];

%% Creating the trials table:
for sub=1:n_subjects
    % Count how many trials there will be given the condition nesting we
    % have:
    total_n_trials = (2 * length(conditions_levels.duration) *...
        length(conditions_levels.SOA) * length(conditions_levels.SOA_lock))...
        * n_trials_each;
    
    % Determine how many blocks that is:
    n_blocks = total_n_trials / 32;
    
    % Creating the pool of trials counter balanced for the conditions of
    % interest:
    pitch = repmat([1000; 1100], total_n_trials / 2, 1);
    soa_lock_tmp = [repmat("onset", length(unique(pitch)), 1); repmat("offset", length(unique(pitch)), 1)];
    soa_lock = repmat(soa_lock_tmp, total_n_trials / length(soa_lock_tmp), 1);
    soa_tmp = [zeros(length(unique(pitch)) * length(unique(soa_lock)), 1); ...
        repmat(0.232, length(unique(pitch)) * length(unique(soa_lock)), 1); ...
        repmat(0.466, length(unique(pitch)) * length(unique(soa_lock)), 1)];
    soa = repmat(soa_tmp, total_n_trials / length(soa_tmp), 1);
    duration_tmp = [repmat(0.500, length(unique(pitch)) * length(unique(soa_lock)) * length(unique(soa)), 1); ...
        repmat(1.000, length(unique(pitch)) * length(unique(soa_lock)) * length(unique(soa)), 1); ...
        repmat(1.500, length(unique(pitch)) * length(unique(soa_lock)) * length(unique(soa)), 1)];
    duration = repmat(duration_tmp, total_n_trials / length(duration_tmp), 1);
    task_relevance_tmp = [repmat("non-target", length(unique(pitch)) * length(unique(soa_lock)) * length(unique(soa)) * length(unique(duration)), 1); ...
        repmat("irrelevant", length(unique(pitch)) * length(unique(soa_lock)) * length(unique(soa)) * length(unique(duration)), 1)];
    task_relevance = repmat(task_relevance_tmp, total_n_trials / length(task_relevance_tmp), 1);
    
    % Combine all these in a table:
    trial_matrix = table(task_relevance(:, 1), duration(:, 1), soa(:, 1), soa_lock(:, 1), pitch(:, 1), ...
        'VariableNames', ["task_relevance", "duration", "soa", "soa_lock", "pitch"]);
    
    %% Add additional conditions:
    % Loop through each single combination to add category and orientation:
    trial_matrix.category = repmat("", height(trial_matrix), 1);
    trial_matrix.orientation = repmat("", height(trial_matrix), 1);
    trial_matrix.block_type = repmat("", height(trial_matrix), 1);
    trial_matrix.target_01 = repmat("", height(trial_matrix), 1);
    trial_matrix.target_02 = repmat("", height(trial_matrix), 1);
    % There are 4 orientation combinations possible for the amount of
    % nesting we have. If they are added an equal amount of times, we have
    % balance:
    orientations_ctr = struct('center', [2, 2, 1, 1], 'left', [1, 0, 1, 1], 'right', [0, 1, 1, 1]);
    % Create a randomized vector dictating which we are using in each
    % iteration:
    orientation_vect = repmat([1; 2; 3; 4], (length(conditions_levels.task_relevance) *...
        length(conditions_levels.duration) * length(conditions_levels.SOA) * ...
        length(conditions_levels.SOA_lock) * length(conditions_levels.pitch)) / 4, 1);
    % orientation_vect = orientation_vect(randperm(length(orientation_vect)));
    ctr = 1;
    for tr_ind=1:length(conditions_levels.task_relevance)
        for dur_ind=1:length(conditions_levels.duration)
            for soa_ind=1:length(conditions_levels.SOA)
                for soa_lock=1:length(conditions_levels.SOA_lock)
                    for pitch=1:length(conditions_levels.pitch)
                        indices = find(trial_matrix.task_relevance == conditions_levels.task_relevance(tr_ind) & ...
                            trial_matrix.duration == conditions_levels.duration(dur_ind) & ...
                            trial_matrix.soa == conditions_levels.SOA(soa_ind) & ...
                            trial_matrix.soa_lock == conditions_levels.SOA_lock(soa_lock) & ...
                            trial_matrix.pitch == conditions_levels.pitch(pitch));
                        n_trials = length(indices);
                        % Now that we have the indices, split them randomly in
                        % as many pools as we have category:
                        for category=1:length(conditions_levels.category)
                            [y, ind] = datasample(indices, n_trials / length(conditions_levels.category),'Replace',false);
                            trial_matrix.category(y) = conditions_levels.category(category);
                            % Add the block type, which is dictated by the task
                            % relevance:
                            switch conditions_levels.task_relevance(tr_ind)
                                case "non-target"
                                    if strcmp(conditions_levels.category(category), "face") ||...
                                            strcmp(conditions_levels.category(category), "object")
                                        trial_matrix.block_type(y) = "face_object";
                                        trial_matrix.target_01(y) = "face_";
                                        trial_matrix.target_02(y) = "object_";
                                    elseif strcmp(conditions_levels.category(category), "letter") ||...
                                            strcmp(conditions_levels.category(category), "false_font")
                                        trial_matrix.block_type(y) = "letter_false_font";
                                        trial_matrix.target_01(y) = "letter_";
                                        trial_matrix.target_02(y) = "false_font_";
                                    end
                                case "irrelevant"
                                    if strcmp(conditions_levels.category(category), "face") ||...
                                            strcmp(conditions_levels.category(category), "object")
                                        trial_matrix.block_type(y) = "letter_false_font";
                                        trial_matrix.target_01(y) = "letter_";
                                        trial_matrix.target_02(y) = "false_font_";
                                    elseif strcmp(conditions_levels.category(category), "letter") ||...
                                            strcmp(conditions_levels.category(category), "false_font")
                                        trial_matrix.block_type(y) = "face_object";
                                        trial_matrix.target_01(y) = "face_";
                                        trial_matrix.target_02(y) = "object_";
                                    end
                            end
                            
                            % Looping through each orientation:
                            indices_orientations = y;
                            for ori_ind=1:length(orientations_ctr)
                                % Randomly sampling n for each orientation:
                                n_center = orientations_ctr.center(orientation_vect(ctr));
                                n_left = orientations_ctr.left(orientation_vect(ctr));
                                n_right = orientations_ctr.right(orientation_vect(ctr));
                                % Grab n for each orientation:
                                [y_cent, ind_cent] = datasample(indices_orientations, n_center,'Replace',false);
                                indices_orientations(ind_cent) = [];
                                [y_left, ind_left] = datasample(indices_orientations, n_left,'Replace',false);
                                indices_orientations(ind_left) = [];
                                [y_right, ind_right] = datasample(indices_orientations, n_right,'Replace',false);
                                indices_orientations(ind_right) = [];
                                trial_matrix.orientation(y_cent) = "center";
                                trial_matrix.orientation(y_left) = "left";
                                trial_matrix.orientation(y_right) = "right";
                            end
                            indices(ind) = [];
                        end
                        ctr = ctr + 1;
                    end
                end
            end
        end
    end
    not_pass = 1;
    while not_pass
        try
            %% Adding stimuli identity.
            trial_matrix.identity = repmat("", height(trial_matrix), 1);
            % Identity is a bit more complicated, as it depends on the targets:
            % Create each identities:
            face_identities = ["face_01", "face_02", "face_03", "face_04", "face_05", ...
                "face_06", "face_07", "face_08", "face_09", "face_10",...
                "face_11", "face_12", "face_13", "face_14", "face_15", "face_16",...
                "face_17", "face_18", "face_19", "face_20"];
            object_identities = ["object_01", "object_02", "object_03", "object_04", "object_05", ...
                "object_06", "object_07", "object_08", "object_09", "object_10",...
                "object_11", "object_12", "object_13", "object_14", "object_15", "object_16",...
                "object_17", "object_18", "object_19", "object_20"];
            letter_identities = ["letter_01", "letter_02", "letter_03", "letter_04", "letter_05", ...
                "letter_06", "letter_07", "letter_08", "letter_09", "letter_10",...
                "letter_11", "letter_12", "letter_13", "letter_14", "letter_15", "letter_16",...
                "letter_17", "letter_18", "letter_19", "letter_20"];
            false_font_identities = ["false_font_01", "false_font_02", "false_font_03", "false_font_04", "false_font_05", ...
                "false_font_06", "false_font_07", "false_font_08", "false_font_09", "false_font_10",...
                "false_font_11", "false_font_12", "false_font_13", "false_font_14", "false_font_15", "false_font_16",...
                "false_font_17", "false_font_18", "false_font_19", "false_font_20"];
            
            % Create counter matrices for faces identities, to ensure that they are
            % balanced across task relevance, duration and orientation:
            %% Faces counters:
            % Face task relevant 500ms:
            face_identities_counter_tr_500_center = struct("face_01", 2, "face_02", 2, "face_03", 2, "face_04", 2,...
                "face_05", 2, "face_06", 2, "face_07", 2, "face_08", 2,...
                "face_09", 2, "face_10", 2, "face_11", 2, "face_12", 2,...
                "face_13", 2, "face_14", 2, "face_15", 2, "face_16", 2,...
                "face_17", 2, "face_18", 2, "face_19", 2, "face_20", 2);
            face_identities_counter_tr_500_left = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            face_identities_counter_tr_500_right = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            % Face task relevant 1000ms:
            face_identities_counter_tr_1000_center = struct("face_01", 2, "face_02", 2, "face_03", 2, "face_04", 2,...
                "face_05", 2, "face_06", 2, "face_07", 2, "face_08", 2,...
                "face_09", 2, "face_10", 2, "face_11", 2, "face_12", 2,...
                "face_13", 2, "face_14", 2, "face_15", 2, "face_16", 2,...
                "face_17", 2, "face_18", 2, "face_19", 2, "face_20", 2);
            face_identities_counter_tr_1000_left = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            face_identities_counter_tr_1000_right = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            % Face task relevant 1500ms:
            face_identities_counter_tr_1500_center = struct("face_01", 2, "face_02", 2, "face_03", 2, "face_04", 2,...
                "face_05", 2, "face_06", 2, "face_07", 2, "face_08", 2,...
                "face_09", 2, "face_10", 2, "face_11", 2, "face_12", 2,...
                "face_13", 2, "face_14", 2, "face_15", 2, "face_16", 2,...
                "face_17", 2, "face_18", 2, "face_19", 2, "face_20", 2);
            face_identities_counter_tr_1500_left = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            face_identities_counter_tr_1500_right = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            
            % Face task irrelevant 500ms:
            face_identities_counter_ti_500_center = struct("face_01", 2, "face_02", 2, "face_03", 2, "face_04", 2,...
                "face_05", 2, "face_06", 2, "face_07", 2, "face_08", 2,...
                "face_09", 2, "face_10", 2, "face_11", 2, "face_12", 2,...
                "face_13", 2, "face_14", 2, "face_15", 2, "face_16", 2,...
                "face_17", 2, "face_18", 2, "face_19", 2, "face_20", 2);
            face_identities_counter_ti_500_left = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            face_identities_counter_ti_500_right = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            % Face task irrelevant 1000ms:
            face_identities_counter_ti_1000_center = struct("face_01", 2, "face_02", 2, "face_03", 2, "face_04", 2,...
                "face_05", 2, "face_06", 2, "face_07", 2, "face_08", 2,...
                "face_09", 2, "face_10", 2, "face_11", 2, "face_12", 2,...
                "face_13", 2, "face_14", 2, "face_15", 2, "face_16", 2,...
                "face_17", 2, "face_18", 2, "face_19", 2, "face_20", 2);
            face_identities_counter_ti_1000_left = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            face_identities_counter_ti_1000_right = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            % Face task irrelevant 1500ms:
            face_identities_counter_ti_1500_center = struct("face_01", 2, "face_02", 2, "face_03", 2, "face_04", 2,...
                "face_05", 2, "face_06", 2, "face_07", 2, "face_08", 2,...
                "face_09", 2, "face_10", 2, "face_11", 2, "face_12", 2,...
                "face_13", 2, "face_14", 2, "face_15", 2, "face_16", 2,...
                "face_17", 2, "face_18", 2, "face_19", 2, "face_20", 2);
            face_identities_counter_ti_1500_left = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            face_identities_counter_ti_1500_right = struct("face_01", 1, "face_02", 1, "face_03", 1, "face_04", 1,...
                "face_05", 1, "face_06", 1, "face_07", 1, "face_08", 1,...
                "face_09", 1, "face_10", 1, "face_11", 1, "face_12", 1,...
                "face_13", 1, "face_14", 1, "face_15", 1, "face_16", 1,...
                "face_17", 1, "face_18", 1, "face_19", 1, "face_20", 1);
            
            %% Objects counters:
            % Object task relevant 500ms:
            object_identities_counter_tr_500_center = struct("object_01", 2, "object_02", 2, "object_03", 2, "object_04", 2,...
                "object_05", 2, "object_06", 2, "object_07", 2, "object_08", 2,...
                "object_09", 2, "object_10", 2, "object_11", 2, "object_12", 2,...
                "object_13", 2, "object_14", 2, "object_15", 2, "object_16", 2,...
                "object_17", 2, "object_18", 2, "object_19", 2, "object_20", 2);
            object_identities_counter_tr_500_left = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            object_identities_counter_tr_500_right = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            
            % Object task relevant 1000ms:
            object_identities_counter_tr_1000_center = struct("object_01", 2, "object_02", 2, "object_03", 2, "object_04", 2,...
                "object_05", 2, "object_06", 2, "object_07", 2, "object_08", 2,...
                "object_09", 2, "object_10", 2, "object_11", 2, "object_12", 2,...
                "object_13", 2, "object_14", 2, "object_15", 2, "object_16", 2,...
                "object_17", 2, "object_18", 2, "object_19", 2, "object_20", 2);
            object_identities_counter_tr_1000_left = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            object_identities_counter_tr_1000_right = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            
            % Object task relevant 1500ms:
            object_identities_counter_tr_1500_center = struct("object_01", 2, "object_02", 2, "object_03", 2, "object_04", 2,...
                "object_05", 2, "object_06", 2, "object_07", 2, "object_08", 2,...
                "object_09", 2, "object_10", 2, "object_11", 2, "object_12", 2,...
                "object_13", 2, "object_14", 2, "object_15", 2, "object_16", 2,...
                "object_17", 2, "object_18", 2, "object_19", 2, "object_20", 2);
            object_identities_counter_tr_1500_left = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            object_identities_counter_tr_1500_right = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            
            % Object task irrelevant 500ms:
            object_identities_counter_ti_500_center = struct("object_01", 2, "object_02", 2, "object_03", 2, "object_04", 2,...
                "object_05", 2, "object_06", 2, "object_07", 2, "object_08", 2,...
                "object_09", 2, "object_10", 2, "object_11", 2, "object_12", 2,...
                "object_13", 2, "object_14", 2, "object_15", 2, "object_16", 2,...
                "object_17", 2, "object_18", 2, "object_19", 2, "object_20", 2);
            object_identities_counter_ti_500_left = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            object_identities_counter_ti_500_right = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            
            % Object task irrelevant 1000ms:
            object_identities_counter_ti_1000_center = struct("object_01", 2, "object_02", 2, "object_03", 2, "object_04", 2,...
                "object_05", 2, "object_06", 2, "object_07", 2, "object_08", 2,...
                "object_09", 2, "object_10", 2, "object_11", 2, "object_12", 2,...
                "object_13", 2, "object_14", 2, "object_15", 2, "object_16", 2,...
                "object_17", 2, "object_18", 2, "object_19", 2, "object_20", 2);
            object_identities_counter_ti_1000_left = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            object_identities_counter_ti_1000_right = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            
            % Object task irrelevant 1500ms:
            object_identities_counter_ti_1500_center = struct("object_01", 2, "object_02", 2, "object_03", 2, "object_04", 2,...
                "object_05", 2, "object_06", 2, "object_07", 2, "object_08", 2,...
                "object_09", 2, "object_10", 2, "object_11", 2, "object_12", 2,...
                "object_13", 2, "object_14", 2, "object_15", 2, "object_16", 2,...
                "object_17", 2, "object_18", 2, "object_19", 2, "object_20", 2);
            object_identities_counter_ti_1500_left = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            object_identities_counter_ti_1500_right = struct("object_01", 1, "object_02", 1, "object_03", 1, "object_04", 1,...
                "object_05", 1, "object_06", 1, "object_07", 1, "object_08", 1,...
                "object_09", 1, "object_10", 1, "object_11", 1, "object_12", 1,...
                "object_13", 1, "object_14", 1, "object_15", 1, "object_16", 1,...
                "object_17", 1, "object_18", 1, "object_19", 1, "object_20", 1);
            
            %% Letters counters:
            % letter task relevant 500ms:
            letter_identities_counter_tr_500_center = struct("letter_01", 2, "letter_02", 2, "letter_03", 2, "letter_04", 2,...
                "letter_05", 2, "letter_06", 2, "letter_07", 2, "letter_08", 2,...
                "letter_09", 2, "letter_10", 2, "letter_11", 2, "letter_12", 2,...
                "letter_13", 2, "letter_14", 2, "letter_15", 2, "letter_16", 2,...
                "letter_17", 2, "letter_18", 2, "letter_19", 2, "letter_20", 2);
            letter_identities_counter_tr_500_left = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            letter_identities_counter_tr_500_right = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            
            % letter task relevant 1000ms:
            letter_identities_counter_tr_1000_center = struct("letter_01", 2, "letter_02", 2, "letter_03", 2, "letter_04", 2,...
                "letter_05", 2, "letter_06", 2, "letter_07", 2, "letter_08", 2,...
                "letter_09", 2, "letter_10", 2, "letter_11", 2, "letter_12", 2,...
                "letter_13", 2, "letter_14", 2, "letter_15", 2, "letter_16", 2,...
                "letter_17", 2, "letter_18", 2, "letter_19", 2, "letter_20", 2);
            letter_identities_counter_tr_1000_left = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            letter_identities_counter_tr_1000_right = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            
            % letter task relevant 1500ms:
            letter_identities_counter_tr_1500_center = struct("letter_01", 2, "letter_02", 2, "letter_03", 2, "letter_04", 2,...
                "letter_05", 2, "letter_06", 2, "letter_07", 2, "letter_08", 2,...
                "letter_09", 2, "letter_10", 2, "letter_11", 2, "letter_12", 2,...
                "letter_13", 2, "letter_14", 2, "letter_15", 2, "letter_16", 2,...
                "letter_17", 2, "letter_18", 2, "letter_19", 2, "letter_20", 2);
            letter_identities_counter_tr_1500_left = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            letter_identities_counter_tr_1500_right = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            
            
            % letter task irrelevant 500ms:
            letter_identities_counter_ti_500_center = struct("letter_01", 2, "letter_02", 2, "letter_03", 2, "letter_04", 2,...
                "letter_05", 2, "letter_06", 2, "letter_07", 2, "letter_08", 2,...
                "letter_09", 2, "letter_10", 2, "letter_11", 2, "letter_12", 2,...
                "letter_13", 2, "letter_14", 2, "letter_15", 2, "letter_16", 2,...
                "letter_17", 2, "letter_18", 2, "letter_19", 2, "letter_20", 2);
            letter_identities_counter_ti_500_left = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            letter_identities_counter_ti_500_right = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            
            % letter task irrelevant 1000ms:
            letter_identities_counter_ti_1000_center = struct("letter_01", 2, "letter_02", 2, "letter_03", 2, "letter_04", 2,...
                "letter_05", 2, "letter_06", 2, "letter_07", 2, "letter_08", 2,...
                "letter_09", 2, "letter_10", 2, "letter_11", 2, "letter_12", 2,...
                "letter_13", 2, "letter_14", 2, "letter_15", 2, "letter_16", 2,...
                "letter_17", 2, "letter_18", 2, "letter_19", 2, "letter_20", 2);
            letter_identities_counter_ti_1000_left = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            letter_identities_counter_ti_1000_right = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            
            % letter task irrelevant 1500ms:
            letter_identities_counter_ti_1500_center = struct("letter_01", 2, "letter_02", 2, "letter_03", 2, "letter_04", 2,...
                "letter_05", 2, "letter_06", 2, "letter_07", 2, "letter_08", 2,...
                "letter_09", 2, "letter_10", 2, "letter_11", 2, "letter_12", 2,...
                "letter_13", 2, "letter_14", 2, "letter_15", 2, "letter_16", 2,...
                "letter_17", 2, "letter_18", 2, "letter_19", 2, "letter_20", 2);
            letter_identities_counter_ti_1500_left = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            letter_identities_counter_ti_1500_right = struct("letter_01", 1, "letter_02", 1, "letter_03", 1, "letter_04", 1,...
                "letter_05", 1, "letter_06", 1, "letter_07", 1, "letter_08", 1,...
                "letter_09", 1, "letter_10", 1, "letter_11", 1, "letter_12", 1,...
                "letter_13", 1, "letter_14", 1, "letter_15", 1, "letter_16", 1,...
                "letter_17", 1, "letter_18", 1, "letter_19", 1, "letter_20", 1);
            
            
            %% False font:
            % false_font task relevant 500ms:
            false_font_identities_counter_tr_500_center = struct("false_font_01", 2, "false_font_02", 2, "false_font_03", 2, "false_font_04", 2,...
                "false_font_05", 2, "false_font_06", 2, "false_font_07", 2, "false_font_08", 2,...
                "false_font_09", 2, "false_font_10", 2, "false_font_11", 2, "false_font_12", 2,...
                "false_font_13", 2, "false_font_14", 2, "false_font_15", 2, "false_font_16", 2,...
                "false_font_17", 2, "false_font_18", 2, "false_font_19", 2, "false_font_20", 2);
            false_font_identities_counter_tr_500_left = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            false_font_identities_counter_tr_500_right = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            
            % false_font task relevant 1000ms:
            false_font_identities_counter_tr_1000_center = struct("false_font_01", 2, "false_font_02", 2, "false_font_03", 2, "false_font_04", 2,...
                "false_font_05", 2, "false_font_06", 2, "false_font_07", 2, "false_font_08", 2,...
                "false_font_09", 2, "false_font_10", 2, "false_font_11", 2, "false_font_12", 2,...
                "false_font_13", 2, "false_font_14", 2, "false_font_15", 2, "false_font_16", 2,...
                "false_font_17", 2, "false_font_18", 2, "false_font_19", 2, "false_font_20", 2);
            false_font_identities_counter_tr_1000_left = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            false_font_identities_counter_tr_1000_right = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            
            % false_font task relevant 1500ms:
            false_font_identities_counter_tr_1500_center = struct("false_font_01", 2, "false_font_02", 2, "false_font_03", 2, "false_font_04", 2,...
                "false_font_05", 2, "false_font_06", 2, "false_font_07", 2, "false_font_08", 2,...
                "false_font_09", 2, "false_font_10", 2, "false_font_11", 2, "false_font_12", 2,...
                "false_font_13", 2, "false_font_14", 2, "false_font_15", 2, "false_font_16", 2,...
                "false_font_17", 2, "false_font_18", 2, "false_font_19", 2, "false_font_20", 2);
            false_font_identities_counter_tr_1500_left = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            false_font_identities_counter_tr_1500_right = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            
            % false_font task irrelevant 500ms:
            false_font_identities_counter_ti_500_center = struct("false_font_01", 2, "false_font_02", 2, "false_font_03", 2, "false_font_04", 2,...
                "false_font_05", 2, "false_font_06", 2, "false_font_07", 2, "false_font_08", 2,...
                "false_font_09", 2, "false_font_10", 2, "false_font_11", 2, "false_font_12", 2,...
                "false_font_13", 2, "false_font_14", 2, "false_font_15", 2, "false_font_16", 2,...
                "false_font_17", 2, "false_font_18", 2, "false_font_19", 2, "false_font_20", 2);
            false_font_identities_counter_ti_500_left = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            false_font_identities_counter_ti_500_right = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            
            % false_font task irrelevant 1000ms:
            false_font_identities_counter_ti_1000_center = struct("false_font_01", 2, "false_font_02", 2, "false_font_03", 2, "false_font_04", 2,...
                "false_font_05", 2, "false_font_06", 2, "false_font_07", 2, "false_font_08", 2,...
                "false_font_09", 2, "false_font_10", 2, "false_font_11", 2, "false_font_12", 2,...
                "false_font_13", 2, "false_font_14", 2, "false_font_15", 2, "false_font_16", 2,...
                "false_font_17", 2, "false_font_18", 2, "false_font_19", 2, "false_font_20", 2);
            false_font_identities_counter_ti_1000_left = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            false_font_identities_counter_ti_1000_right = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            
            % false_font task irrelevant 1500ms:
            false_font_identities_counter_ti_1500_center = struct("false_font_01", 2, "false_font_02", 2, "false_font_03", 2, "false_font_04", 2,...
                "false_font_05", 2, "false_font_06", 2, "false_font_07", 2, "false_font_08", 2,...
                "false_font_09", 2, "false_font_10", 2, "false_font_11", 2, "false_font_12", 2,...
                "false_font_13", 2, "false_font_14", 2, "false_font_15", 2, "false_font_16", 2,...
                "false_font_17", 2, "false_font_18", 2, "false_font_19", 2, "false_font_20", 2);
            false_font_identities_counter_ti_1500_left = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            false_font_identities_counter_ti_1500_right = struct("false_font_01", 1, "false_font_02", 1, "false_font_03", 1, "false_font_04", 1,...
                "false_font_05", 1, "false_font_06", 1, "false_font_07", 1, "false_font_08", 1,...
                "false_font_09", 1, "false_font_10", 1, "false_font_11", 1, "false_font_12", 1,...
                "false_font_13", 1, "false_font_14", 1, "false_font_15", 1, "false_font_16", 1,...
                "false_font_17", 1, "false_font_18", 1, "false_font_19", 1, "false_font_20", 1);
            
            %% Set the targets:
            % Setting the numbers for the target:
            n_targets_per_blk = 4.5;
            min_n_targets = 2;
            max_n_targets = 6;
            % Determnine the total number of trials:
            n_target_trials = (height(trial_matrix) / 32) * n_targets_per_blk;
            % Determine the number of trials per category
            n_target_per_cate = n_target_trials / 4;
            % Set counters for orientation of the targets:
            face_orientation_ctr = struct("center", n_target_per_cate * 1/2, "left", n_target_per_cate * 0.25, "right", n_target_per_cate * 0.25);
            object_orientation_ctr = struct("center", n_target_per_cate * 1/2, "left", n_target_per_cate * 0.25, "right", n_target_per_cate * 0.25);
            letter_orientation_ctr = struct("center", n_target_per_cate * 1/2, "left", n_target_per_cate * 0.25, "right", n_target_per_cate * 0.25);
            false_font_orientation_ctr = struct("center", n_target_per_cate * 1/2, "left", n_target_per_cate * 0.25, "right", n_target_per_cate * 0.25);
            % Set counters for the duration of the targets:
            face_duration_ctr = struct("short", n_target_per_cate * 0.5, "intermediate", n_target_per_cate * 0.5, "long", n_target_per_cate * 0.5);
            object_duration_ctr = struct("short", n_target_per_cate * 0.5, "intermediate", n_target_per_cate * 0.5, "long", n_target_per_cate * 0.5);
            letter_duration_ctr = struct("short", n_target_per_cate * 0.5, "intermediate", n_target_per_cate * 0.5, "long", n_target_per_cate * 0.5);
            false_font_duration_ctr = struct("short", n_target_per_cate * 0.5, "intermediate", n_target_per_cate * 0.5, "long", n_target_per_cate * 0.5);
            
            % We need n target trials per category. We need between 2 and 6 target
            % trials per block. Generating vectors that go from 1 to 3 (2 to 6 when
            % combining two target categories) and randomizing them:
            face_targets_ctr = repmat((1:3)', ceil(((height(trial_matrix) / 32) / 2) / 3), 1);
            face_targets_ctr = face_targets_ctr(randperm(length(face_targets_ctr)));
            object_targets_ctr = repmat((1:3)', ceil(((height(trial_matrix) / 32) / 2) / 3), 1);
            object_targets_ctr = object_targets_ctr(randperm(length(object_targets_ctr)));
            letter_targets_ctr = repmat((1:3)', ceil(((height(trial_matrix) / 32) / 2) / 3), 1);
            letter_targets_ctr = letter_targets_ctr(randperm(length(letter_targets_ctr)));
            false_font_targets_ctr = repmat((1:3)', ceil(((height(trial_matrix) / 32) / 2) / 3), 1);
            false_font_targets_ctr = false_font_targets_ctr(randperm(length(false_font_targets_ctr)));
            % Split the data per block types:
            block_types = unique(trial_matrix.block_type);
            trial_mat_new = [];
            blk_ctr = 1;
            for ind=1:length(block_types)
                block_type_mat = trial_matrix(strcmp(trial_matrix.block_type, block_types(ind)), :);
                
                % Add indices to the matrix to be able to remove what we picked:
                block_type_mat.trials = (1:height(block_type_mat))';
                % Randomly sample n trials for each block, as the targets are nested
                % within block:
                n_blocks = (height(block_type_mat) / n_trials_per_blk) ;
                
                % Create the list of targets:
                if strcmp(block_types(ind), "face_object")
                    target_01 = repmat(face_identities, ceil(n_blocks / length(face_identities)));
                    target_02 = repmat(object_identities, ceil(n_blocks / length(object_identities)));
                    target_01_ctr = face_targets_ctr;
                    target_02_ctr = object_targets_ctr;
                    target_01_category = "face";
                    target_02_category = "object";
                elseif strcmp(block_types(ind), "letter_false_font")
                    target_01 = repmat(letter_identities, ceil(n_blocks / length(letter_identities)));
                    target_02 = repmat(false_font_identities, ceil(n_blocks / length(false_font_identities)));
                    target_01_ctr = letter_targets_ctr;
                    target_02_ctr = false_font_targets_ctr;
                    target_01_category = "letter";
                    target_02_category = "false_font";
                end
                % Randomize the target arrays, ensuring that the pairing and count of
                % targets is not biased:
                target_01 = target_01(randperm(length(target_01)));
                target_02 = target_02(randperm(length(target_02)));
                
                % TODO: Add the identity selection to be counter balanced!!!
                
                for blk=1:n_blocks
                    % We need to have half of the trials for that block to be task
                    % relevant, the other half to be task irrelevant:
                    task_rel_u = unique(block_type_mat.task_relevance);
                    for tr_ind=1:length(task_rel_u)
                        % Get the trials of the task relevance of interest:
                        task_relevance_mat = block_type_mat(strcmp(block_type_mat.task_relevance, task_rel_u(tr_ind)), :);
                        [y, ind_rmv] = datasample(1:height(task_relevance_mat), n_trials_per_blk / 2,'Replace',false);
                        % Extract that info:
                        blk_mat = task_relevance_mat(y, :);
                        % Add the  targets:
                        blk_mat.target_01(:) = target_01(blk);
                        blk_mat.target_02(:) = target_02(blk);
                        % Add the identity:
                        cat_u = unique(blk_mat.category);
                        % TODO: identity is not balanced with respect to the other
                        % experimental conditions. Can be improved
                        for cat=1:length(cat_u)
                            % Get the trials of the current category:
                            tr_inds = find(blk_mat.category == cat_u(cat));
                            % Get the trials orientations and durations:
                            trs_ori = blk_mat.orientation(tr_inds);
                            trs_dur = blk_mat.duration(tr_inds);
                            % Append the trials:
                            trial_ids = [];
                            % Looping through each trial:
                            for i=1:length(tr_inds)
                                switch cat_u(cat)
                                    case "face"
                                        if strcmp(trs_ori(i), "center")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_500_center,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity
                                                    % and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_500_center.(sel_id) = face_identities_counter_tr_500_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_500_center,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_500_center.(sel_id) = face_identities_counter_ti_500_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_1000_center,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_1000_center.(sel_id) = face_identities_counter_tr_1000_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_1000_center,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_1000_center.(sel_id) = face_identities_counter_ti_1000_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_1500_center,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_1500_center.(sel_id) = face_identities_counter_tr_1500_center.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_1500_center,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_1500_center.(sel_id) = face_identities_counter_ti_1500_center.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "left")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_500_left,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_500_left.(sel_id) = face_identities_counter_tr_500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_500_left,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_500_left.(sel_id) = face_identities_counter_ti_500_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_1000_left,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_1000_left.(sel_id) = face_identities_counter_tr_1000_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_1000_left,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_1000_left.(sel_id) = face_identities_counter_ti_1000_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_1500_left,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_1500_left.(sel_id) = face_identities_counter_tr_1500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_1500_left,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_1500_left.(sel_id) = face_identities_counter_ti_1500_left.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "right")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_500_right,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_500_right.(sel_id) = face_identities_counter_tr_500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_500_right,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_500_right.(sel_id) = face_identities_counter_ti_500_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_1000_right,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_1000_right.(sel_id) = face_identities_counter_tr_1000_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_1000_right,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_1000_right.(sel_id) = face_identities_counter_ti_1000_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_tr_1500_right,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_tr_1500_right.(sel_id) = face_identities_counter_tr_1500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(face_identities_counter_ti_1500_right,...
                                                        face_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    face_identities_counter_ti_1500_right.(sel_id) = face_identities_counter_ti_1500_right.(sel_id) -  1;
                                                end
                                            end
                                        end
                                    case "object"
                                        if strcmp(trs_ori(i), "center")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_500_center,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_500_center.(sel_id) = object_identities_counter_tr_500_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_500_center,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_500_center.(sel_id) = object_identities_counter_ti_500_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_1000_center,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_1000_center.(sel_id) = object_identities_counter_tr_1000_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_1000_center,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_1000_center.(sel_id) = object_identities_counter_ti_1000_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_1500_center,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_1500_center.(sel_id) = object_identities_counter_tr_1500_center.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_1500_center,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_1500_center.(sel_id) = object_identities_counter_ti_1500_center.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "left")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_500_left,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_500_left.(sel_id) = object_identities_counter_tr_500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_500_left,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_500_left.(sel_id) = object_identities_counter_ti_500_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_1000_left,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_1000_left.(sel_id) = object_identities_counter_tr_1000_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_1000_left,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_1000_left.(sel_id) = object_identities_counter_ti_1000_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_1500_left,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_1500_left.(sel_id) = object_identities_counter_tr_1500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_1500_left,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_1500_left.(sel_id) = object_identities_counter_ti_1500_left.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "right")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_500_right,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_500_right.(sel_id) = object_identities_counter_tr_500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_500_right,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_500_right.(sel_id) = object_identities_counter_ti_500_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_1000_right,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_1000_right.(sel_id) = object_identities_counter_tr_1000_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_1000_right,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_1000_right.(sel_id) = object_identities_counter_ti_1000_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_tr_1500_right,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_tr_1500_right.(sel_id) = object_identities_counter_tr_1500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(object_identities_counter_ti_1500_right,...
                                                        object_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    object_identities_counter_ti_1500_right.(sel_id) = object_identities_counter_ti_1500_right.(sel_id) -  1;
                                                end
                                            end
                                        end
                                    case "letter"
                                        if strcmp(trs_ori(i), "center")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_500_center,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_500_center.(sel_id) = letter_identities_counter_tr_500_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_500_center,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_500_center.(sel_id) = letter_identities_counter_ti_500_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_1000_center,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_1000_center.(sel_id) = letter_identities_counter_tr_1000_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_1000_center,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_1000_center.(sel_id) = letter_identities_counter_ti_1000_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_1500_center,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_1500_center.(sel_id) = letter_identities_counter_tr_1500_center.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_1500_center,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_1500_center.(sel_id) = letter_identities_counter_ti_1500_center.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "left")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_500_left,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_500_left.(sel_id) = letter_identities_counter_tr_500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_500_left,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_500_left.(sel_id) = letter_identities_counter_ti_500_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_1000_left,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_1000_left.(sel_id) = letter_identities_counter_tr_1000_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_1000_left,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_1000_left.(sel_id) = letter_identities_counter_ti_1000_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_1500_left,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_1500_left.(sel_id) = letter_identities_counter_tr_1500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_1500_left,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_1500_left.(sel_id) = letter_identities_counter_ti_1500_left.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "right")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_500_right,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_500_right.(sel_id) = letter_identities_counter_tr_500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_500_right,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_500_right.(sel_id) = letter_identities_counter_ti_500_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_1000_right,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_1000_right.(sel_id) = letter_identities_counter_tr_1000_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_1000_right,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_1000_right.(sel_id) = letter_identities_counter_ti_1000_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_tr_1500_right,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_tr_1500_right.(sel_id) = letter_identities_counter_tr_1500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(letter_identities_counter_ti_1500_right,...
                                                        letter_identities, target_01(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    letter_identities_counter_ti_1500_right.(sel_id) = letter_identities_counter_ti_1500_right.(sel_id) -  1;
                                                end
                                            end
                                        end
                                    case "false_font"
                                        if strcmp(trs_ori(i), "center")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_500_center,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_500_center.(sel_id) = false_font_identities_counter_tr_500_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_500_center,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_500_center.(sel_id) = false_font_identities_counter_ti_500_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_1000_center,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_1000_center.(sel_id) = false_font_identities_counter_tr_1000_center.(sel_id) - 1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_1000_center,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_1000_center.(sel_id) = false_font_identities_counter_ti_1000_center.(sel_id) - 1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_1500_center,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_1500_center.(sel_id) = false_font_identities_counter_tr_1500_center.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_1500_center,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_1500_center.(sel_id) = false_font_identities_counter_ti_1500_center.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "left")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_500_left,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_500_left.(sel_id) = false_font_identities_counter_tr_500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_500_left,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_500_left.(sel_id) = false_font_identities_counter_ti_500_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_1000_left,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_1000_left.(sel_id) = false_font_identities_counter_tr_1000_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_1000_left,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_1000_left.(sel_id) = false_font_identities_counter_ti_1000_left.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_1500_left,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_1500_left.(sel_id) = false_font_identities_counter_tr_1500_left.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_1500_left,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_1500_left.(sel_id) = false_font_identities_counter_ti_1500_left.(sel_id) -  1;
                                                end
                                            end
                                        elseif strcmp(trs_ori(i), "right")
                                            if trs_dur(i) == 0.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_500_right,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_500_right.(sel_id) = false_font_identities_counter_tr_500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_500_right,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_500_right.(sel_id) = false_font_identities_counter_ti_500_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.000
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_1000_right,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_1000_right.(sel_id) = false_font_identities_counter_tr_1000_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_1000_right,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_1000_right.(sel_id) = false_font_identities_counter_ti_1000_right.(sel_id) -  1;
                                                end
                                            elseif trs_dur(i) == 1.500
                                                if strcmp(task_rel_u(tr_ind), "non-target")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_tr_1500_right,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_tr_1500_right.(sel_id) = false_font_identities_counter_tr_1500_right.(sel_id) -  1;
                                                elseif strcmp(task_rel_u(tr_ind), "irrelevant")
                                                    % Update the counter to keep
                                                    % only available identities:
                                                    avail_ids = update_identities(false_font_identities_counter_ti_1500_right,...
                                                        false_font_identities, target_02(blk));
                                                    % Randomly sample one identity and add to the list:
                                                    sel_id = randsample(avail_ids, 1);
                                                    trial_ids = [trial_ids; sel_id];
                                                    % Update the counter:
                                                    false_font_identities_counter_ti_1500_right.(sel_id) = false_font_identities_counter_ti_1500_right.(sel_id) -  1;
                                                end
                                            end
                                        end
                                end
                            end
                            % Add the identities to the matrix:
                            blk_mat.identity(tr_inds) = trial_ids;
                        end
                        
                        % Add the block number. This will all be shuffled down the
                        % line, but necessary to keep blocks grouped:
                        blk_mat.block(:) = blk_ctr;
                        if isempty(trial_mat_new)
                            trial_mat_new = blk_mat;
                        else
                            trial_mat_new = [trial_mat_new; blk_mat];
                        end
                        % Same for the block type mat for the higher level loop:
                        [sharedvals,ind_rmv] = intersect(block_type_mat.trials, blk_mat.trials);
                        block_type_mat(ind_rmv, :) = [];
                    end
                    %% Add the target trials:
                    % How many of each depends on the ctr vector:
                    n_target_01 = target_01_ctr(blk);
                    n_target_02 = target_02_ctr(blk);
                    % Figure out the duration and orientation of each, depending what
                    % we have left in the counters:
                    tar_1_orientations = [];
                    tar_1_durations = [];
                    tar_1_soa = [];
                    tar_1_soa_lock = [];
                    tar_1_pitch = [];
                    for tars=1:n_target_01
                        % Using a while loop to ensure we are not selecting something
                        % that isn't available anymore
                        not_avail = 1;
                        while not_avail
                            tar_ori = randsample(["center", "left", "right"], 1);
                            if target_01_category == "face"
                                if face_orientation_ctr.(tar_ori) > 0
                                    tar_1_orientations = strvcat(tar_1_orientations,tar_ori);
                                    face_orientation_ctr.(tar_ori) = face_orientation_ctr.(tar_ori) - 1;
                                    not_avail = 0;
                                end
                            else
                                if letter_orientation_ctr.(tar_ori) > 0
                                    tar_1_orientations = strvcat(tar_1_orientations,tar_ori);
                                    letter_orientation_ctr.(tar_ori) = letter_orientation_ctr.(tar_ori) - 1;
                                    not_avail = 0;
                                end
                            end
                        end
                        % Same for duration:
                        not_avail = 1;
                        while not_avail
                            tar_dur = randsample(["short", "intermediate", "long"], 1);
                            switch tar_dur
                                case "short"
                                    dur = 0.500;
                                case "intermediate"
                                    dur = 1.000;
                                case "long"
                                    dur = 1.500;
                            end
                            if target_01_category == "face"
                                if face_duration_ctr.(tar_dur) > 0
                                    tar_1_durations = [tar_1_durations;dur];
                                    face_duration_ctr.(tar_dur) = face_duration_ctr.(tar_dur) - 1;
                                    not_avail = 0;
                                end
                            else
                                if letter_duration_ctr.(tar_dur) > 0
                                    tar_1_durations = [tar_1_durations;dur];
                                    letter_duration_ctr.(tar_dur) = letter_duration_ctr.(tar_dur) - 1;
                                    not_avail = 0;
                                end
                            end
                        end
                        % Randomly select soa and soa loc:
                        tar_1_soa = [tar_1_soa; randsample([0, 0.232, 0.466], 1)];
                        tar_1_soa_lock = [tar_1_soa_lock; randsample(["onset"; "offset"], 1)];
                        tar_1_pitch = [tar_1_pitch; randsample([1000, 1100], 1)];
                    end
                    
                    % Same for the second targets:
                    tar_2_orientations = [];
                    tar_2_durations = [];
                    tar_2_soa = [];
                    tar_2_soa_lock = [];
                    tar_2_pitch = [];
                    for tars=1:n_target_02
                        % Using a while loop to ensure we are not selecting something
                        % that isn't available anymore
                        not_avail = 1;
                        while not_avail
                            tar_ori = randsample(["center", "left", "right"], 1);
                            if target_01_category == "face"
                                if object_orientation_ctr.(tar_ori) > 0
                                    tar_2_orientations = strvcat(tar_2_orientations,tar_ori);
                                    object_orientation_ctr.(tar_ori) = object_orientation_ctr.(tar_ori) - 1;
                                    not_avail = 0;
                                end
                            else
                                if false_font_orientation_ctr.(tar_ori) > 0
                                    tar_2_orientations = strvcat(tar_2_orientations,tar_ori);
                                    false_font_orientation_ctr.(tar_ori) = false_font_orientation_ctr.(tar_ori) - 1;
                                    not_avail = 0;
                                end
                            end
                        end
                        % Same for duration:
                        not_avail = 1;
                        while not_avail
                            tar_dur = randsample(["short", "intermediate", "long"], 1);
                            switch tar_dur
                                case "short"
                                    dur = 0.500;
                                case "intermediate"
                                    dur = 1.000;
                                case "long"
                                    dur = 1.500;
                            end
                            if target_01_category == "face"
                                if object_duration_ctr.(tar_dur) > 0
                                    tar_2_durations = [tar_2_durations; dur];
                                    object_duration_ctr.(tar_dur) = object_duration_ctr.(tar_dur) - 1;
                                    not_avail = 0;
                                end
                            else
                                if false_font_duration_ctr.(tar_dur) > 0
                                    tar_2_durations = [tar_2_durations; dur];
                                    false_font_duration_ctr.(tar_dur) = false_font_duration_ctr.(tar_dur) - 1;
                                    not_avail = 0;
                                end
                            end
                        end
                        % Randomly select soa and soa loc:
                        tar_2_soa = [tar_2_soa; randsample([0, 0.232, 0.466], 1)];
                        tar_2_soa_lock = [tar_2_soa_lock; randsample(["onset"; "offset"], 1)];
                        tar_2_pitch = [tar_2_pitch; randsample([1000, 1100], 1)];
                    end
                    
                    % Add the targets at the end of the block:
                    target_01_mat = table(repmat("target", n_target_01, 1), ...
                        tar_1_durations, ...
                        tar_1_soa, tar_1_soa_lock, ...
                        tar_1_pitch, repmat(target_01_category, n_target_01, 1), ...
                        cellstr(tar_1_orientations), repmat(block_types(ind), n_target_01, 1), ...
                        repmat(target_01(blk), n_target_01, 1), repmat(target_02(blk), n_target_01, 1), ...
                        repmat(target_01(blk), n_target_01, 1), zeros(n_target_01, 1), repmat(blk_ctr, n_target_01, 1),...
                        'VariableNames', ["task_relevance", "duration", "soa", "soa_lock", "pitch", "category", "orientation", "block_type", "target_01", "target_02", "identity", "trials", "block"]);
                    % Add the targets at the end of the block:
                    target_02_mat = table(repmat("target", n_target_02, 1), ...
                        tar_2_durations,...
                        tar_2_soa, tar_2_soa_lock, ...
                        tar_2_pitch, repmat(target_02_category, n_target_02, 1), ...
                        cellstr(tar_2_orientations), repmat(block_types(ind), n_target_02, 1), ...
                        repmat(target_01(blk), n_target_02, 1), repmat(target_02(blk), n_target_02, 1), ...
                        repmat(target_02(blk), n_target_02, 1), zeros(n_target_02, 1), repmat(blk_ctr, n_target_02, 1),...
                        'VariableNames', ["task_relevance", "duration", "soa", "soa_lock", "pitch", "category", "orientation", "block_type", "target_01", "target_02", "identity", "trials", "block"]);
                    trial_mat_new = [trial_mat_new; target_01_mat; target_02_mat];
                    blk_ctr = blk_ctr + 1;
                end
            end
            not_pass = 0;
        catch e
            disp("Fail to converge at:")
            disp(blk)            
            not_pass = 1;
        end
    end
    
    
    %% Randomize block and trial order within blocks:
    blocks = unique(trial_mat_new.block);
    trial_mat_final = [];
    % One more constraint: there should be two face object block followed
    % by two letter and symbol blocks. Furthermore, for half of the
    % subjects we should start with faces object blocks and the other half
    % should start with letter symbols:
    blk_order_version = mod(sub, 2);
    switch blk_order_version
        case 0
            blk_type_order = repmat([...
                "face_object"; "face_object"; ...
                "letter_false_font"; "letter_false_font";...
                "letter_false_font"; "letter_false_font"; ...
                "face_object"; "face_object";...
                ], ceil(length(blocks) / 8), 1);
        case 1
            blk_type_order = repmat([...
                "letter_false_font"; "letter_false_font"; ...
                "face_object"; "face_object";...
                "face_object"; "face_object";...
                "letter_false_font"; "letter_false_font";...
                ], ceil(length(blocks) / 8), 1);
    end
    
    % Loop through each block:
    for block=1:length(blocks)
        % Getting the block type:
        blk_type = blk_type_order(block);
        % Get all blocks of this type:
        blk_type_mat = trial_mat_new(strcmp(trial_mat_new.block_type, blk_type), :);
        blk_type_num = unique(blk_type_mat.block);
        % Randomly pick one:
        sel_block_num = datasample(blk_type_num, 1,'Replace',false);
        % Get the block data:
        block_mat = trial_mat_new(trial_mat_new.block == sel_block_num, :);
        % Randomize the order of the block:
        block_mat = block_mat(randperm(height(block_mat)), :);
        block_mat.block(:) = block;
        block_mat.trial = (1:height(block_mat))';

        if isempty(trial_mat_final)
            trial_mat_final = block_mat;
        else
            trial_mat_final = [trial_mat_final; block_mat];
        end
        % Remove the block from the table:
        trial_mat_new(find(trial_mat_new.block == sel_block_num), :) = [];
    end
    % Add columns and reorder:
    trial_mat_final.is_practice(:) = 0;
    trial_mat_final.task(:) = "introspection";
    trial_mat_final.trials = [];
    % Add the jitter:
    trial_mat_final.stim_jit = random(jitter_distribution, height(trial_mat_final), 1);
    % Reorder:
    trial_mat_final = table(trial_mat_final.task, trial_mat_final.is_practice, trial_mat_final.block, ...
        trial_mat_final.trial, trial_mat_final.target_01, trial_mat_final.target_02, trial_mat_final.task_relevance, ...
        trial_mat_final.category,trial_mat_final.orientation, trial_mat_final.identity, ...
        trial_mat_final.duration, trial_mat_final.stim_jit, trial_mat_final.soa, ...
        trial_mat_final.soa_lock, trial_mat_final.pitch, ...
        'VariableNames',["task", "is_practice", "block", "trial", "target_01", "target_02", "task_relevance", ...
        "category", "orientation","identity", "duration", "stim_jit", "SOA", "SOA_lock", "pitch"]);
    
    % Add the practice:
    auditory_practice = makePractice_mat("auditory");
    auditory_practice.block(:) = -2;
    auditory_practice.is_practice(:) = 1;
    visual_practice = makePractice_mat("visual");
    visual_practice.block(:) = -1;
    visual_practice.is_practice(:) = 1;
    auditory_visual_practice = makePractice_mat("auditory_and_visual");
    auditory_visual_practice.block(:) = 0;
    auditory_visual_practice.is_practice(:) = 1;
    % Concatenate the practices:
    practice_table = [auditory_practice; visual_practice; auditory_visual_practice];
    practice_table = table(practice_table.task, practice_table.is_practice, practice_table.block,...
        practice_table.trial, practice_table.target_1, practice_table.target_2,...
        practice_table.task_relevance, practice_table.category, practice_table.orientation,...
        practice_table.identity, practice_table.duration, practice_table.stim_jit,...
        practice_table.SOA, practice_table.SOA_lock, practice_table.pitch, ...
        'VariableNames',["task", "is_practice", "block", "trial", "target_01", "target_02", "task_relevance", ...
        "category", "orientation","identity", "duration", "stim_jit", "SOA", "SOA_lock", "pitch"]);
    % Add these to the table:
    trial_mat_final = [practice_table; trial_mat_final];

    % calculate SOA from onset
    for tr = 1:length(trial_mat_final.trial)
        if strcmp(trial_mat_final.SOA_lock{tr}, 'offset')
            trial_mat_final.onset_SOA(tr) = trial_mat_final.SOA(tr) + (trial_mat_final.duration(tr));
        else
            trial_mat_final.onset_SOA(tr) = trial_mat_final.SOA(tr);
        end
    end

    % add column with sub id
    trial_mat_final.sub_id(:) = sprintf("%s%d", lab_id, 100 + sub);
    
    % Reorder again:
    trial_mat_final = table( trial_mat_final.sub_id, trial_mat_final.task, trial_mat_final.is_practice, trial_mat_final.block, ...
        trial_mat_final.trial, trial_mat_final.target_01, trial_mat_final.target_02, trial_mat_final.task_relevance, ...
        trial_mat_final.category,trial_mat_final.orientation, trial_mat_final.identity, ...
        trial_mat_final.duration, trial_mat_final.stim_jit, trial_mat_final.SOA, trial_mat_final.onset_SOA,...
        trial_mat_final.SOA_lock, trial_mat_final.pitch, ...
        'VariableNames',["sub_id", "task", "is_practice", "block", "trial", "target_01", "target_02", "task_relevance", ...
        "category", "orientation","identity", "duration", "stim_jit", "SOA", "onset_SOA", "SOA_lock", "pitch"]);

% add introspective task jitter (500 ms shorter as stimulus jitter)
trial_mat_final.intro_jit = random(jitter_distribution, height(trial_mat_final), 1) - 0.5;

% split into two sessions 
trial_mat_ses2 = trial_mat_final(trial_mat_final.block <= 12,:);
trial_mat_ses3 = trial_mat_final(trial_mat_final.block > 12 | trial_mat_final.block < 1,:);

trial_mat_ses3.block(trial_mat_ses3.block > 12) = trial_mat_ses3.block(trial_mat_ses3.block > 12) - 12;
%% save
    % Save to file:
    % Create file name:
    % session 2
    file_name2 = fullfile(pwd, sprintf("sub-%s%d_task-%s2_trials.csv", lab_id, 100 + sub, task));
    writetable(trial_mat_ses2, file_name2);
    %session 3
    file_name3 = fullfile(pwd, sprintf("sub-%s%d_task-%s3_trials.csv", lab_id, 100 + sub, task));
    writetable(trial_mat_ses3, file_name3);
    
end

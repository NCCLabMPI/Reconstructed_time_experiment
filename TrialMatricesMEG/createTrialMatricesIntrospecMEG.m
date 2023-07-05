%% Set the parameters:
n_subjects = 20;
lab_id = "SX";
task = "introspection_meg";
% List the tasks. Only the introspection requires randomization:
tasks = ["auditory", "visual", "auditory_and_visual", "visual_first", "auditory_first"];

% Set all the conditions:
conditions = ['task_relevance', 'duration', 'category', 'orientation', ...
    'identity', 'pitch', 'SOA', 'SOA_lock'];
% Set all the conditions values:
task_relevance = ["non-target", "irrelevant"];
duration = [0.5, 1.000, 1.500];
category = ["face", "object", "letter", "false_font"];
orientation = ["center", "left", "right"];
pitch = [1000, 1100];
soa = [0, 0.4];
soa_lock = ["onset", "offset"];
identities = struct();
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
% Set trial counts information:
n_trials_each = 5;
n_trials_per_block = 40;

% Create jitter distribution:
% Stimulus jitter:
stim_jitter_mean = 0.4;
stim_jitter_min = 0.2;
stim_jitter_max = 2;
stim_exp_dist = makedist("Exponential", "mu", stim_jitter_mean);
stim_jitter_distribution = truncate(stim_exp_dist, stim_jitter_min, stim_jitter_max);
% Introspection jitter:
intro_jitter_mean = 0.4;
intro_jitter_min = 0.2;
intro_jitter_max = 0.8;
intro_exp_dist = makedist("Exponential", "mu", intro_jitter_mean);
intro_jitter_distribution = truncate(stim_exp_dist, intro_jitter_min, intro_jitter_max);

% Set the trial duration:
trial_duration_1task = 3.5;
trial_duration_2task = 3.0;

%% Create the trial pools:
% Create the trials pool for the visual first task:
ctr = 1;
task_rel = {};
dur = [];
cate = {};
pit = [];
so = [];
lock = {};
for task_i=1:length(task_relevance)
    for dur_i=1:length(duration)
        for soa_lock_i=1:length(soa_lock)
            for soa_i=1:length(soa)
                for pitch_i=1:length(pitch)
                    for cate_i=1:length(category)
                        task_rel{ctr} = task_relevance{task_i};
                        dur(ctr) = duration(dur_i);
                        so(ctr) = soa(soa_i);
                        lock{ctr} = soa_lock{soa_lock_i};
                        pit(ctr) = pitch(pitch_i);
                        cate{ctr} = category{cate_i};
                        ctr = ctr + 1;
                    end
                end
            end
        end
    end
end

% Add everything to a table:
trial_pool = table(task_rel', dur', so', lock', pit', cate', ...
    'VariableNames', ["task_relevance", "duration", "soa", "soa_lock", "pitch", "category"]);

% Extract the number of combinations we have:
n_combi = height(trial_pool);

% Compute the number of trials we should have:
n_trials_total = length(task_relevance) * length(duration) * length(soa) * ...
    length(soa_lock) * length(pitch) * length(category) * n_trials_each;
% Repeat the trial matrix n times:
trial_pool = repmat(trial_pool, n_trials_total/n_combi, 1);

%% Create single subject matrices:
% Loop through each subject:
for subject_i=1:n_subjects
    % Generate the subject ID:
    subject_id = sprintf("%s%d", lab_id, 100 + subject_i);
    
    % Create the visual first and the auditory first tables:
    tasks = ["visual_first", "auditory_first", "visual_only", "visual_only", "visual_only", "auditory_only", "auditory_only", "auditory_only"];
    visual_only_ctr = 1;
    audio_only_ctr = 1;
    
    for task_i=1:length(tasks)
        task = tasks(task_i);
        % Create a copy of the trials pool for this subject:
        switch task
            case "visual_first"
                subject_task_pool = trial_pool;
            case "auditory_first"
                subject_task_pool = trial_pool(find(trial_pool.soa_lock == "onset"), :);
            case "visual_only"
                subject_task_pool = trial_pool(find(trial_pool.soa_lock == "onset" & trial_pool.soa == 0 ), :);
            case "auditory_only"
                subject_task_pool = trial_pool(find(trial_pool.soa_lock == "onset" & trial_pool.soa == 0 ), :);
        end
        % Compute the number of blocks:
        n_blocks = height(subject_task_pool) / n_trials_per_block;
        % Get the number of blocks of each target type:
        n_block_types = n_blocks/2;
        % Randomly select the face targets:
        faces_targets = face_identities(randperm(length(face_identities)));
        object_targets = object_identities(randperm(length(object_identities)));
        letter_targets = letter_identities(randperm(length(letter_identities)));
        false_targets = false_font_identities(randperm(length(false_font_identities)));
        block_types = ["face_object", "letter_false_font"];
        blk_ctr = 1;
        for blk_type_i=1:length(block_types)
            blk_type = block_types(blk_type_i);
            for block_i=1:n_block_types
                % For this block, grab n trials of each:
                n_trials_per_cate = n_trials_per_block / 4;
                
                % Grab task relevant faces vs objects trials:
                switch blk_type
                    case "face_object"
                        taskrel_ind = find((subject_task_pool.category == "face" | subject_task_pool.category == "object") & subject_task_pool.task_relevance == "non-target");
                        taskirrel_ind = find((subject_task_pool.category == "letter" | subject_task_pool.category == "false_font") & subject_task_pool.task_relevance == "irrelevant");
                    case "letter_false_font"
                        taskrel_ind = find((subject_task_pool.category == "letter" | subject_task_pool.category == "false_font") & subject_task_pool.task_relevance == "non-target");
                        taskirrel_ind = find((subject_task_pool.category == "face" | subject_task_pool.category == "object") & subject_task_pool.task_relevance == "irrelevant");
                end
                % Randomly sample n out of this:
                taskrel_ind = datasample(taskrel_ind, n_trials_per_cate * 2, 1);
                taskirrel_ind = datasample(taskirrel_ind, n_trials_per_cate * 2, 1);
                
                % Grab those:
                non_tar_table = subject_task_pool([taskrel_ind; taskirrel_ind], :);
                % Remove these from the subject's pool:
                subject_task_pool([taskrel_ind; taskirrel_ind], :) = [];
                
                % Select the targets ids:
                switch blk_type
                    case "face_object"
                        target_1 = faces_targets(block_i);
                        target_2 = object_targets(block_i);
                    case "letter_false_font"
                        target_1 = letter_targets(block_i);
                        target_2 = false_targets(block_i);
                end
                
                
                % Add the targets identities:
                non_tar_table.target_01 = repmat(target_1, n_trials_per_block, 1);
                non_tar_table.target_02 = repmat(target_2, n_trials_per_block, 1);
                
                % For the task relevant category, the targets identity are
                % reserved for the targets:
                switch blk_type
                    case "face_object"
                        avail_faces = face_identities(~strcmp(face_identities, target_1));
                        avail_objects = object_identities(~strcmp(object_identities, target_2));
                        faces_ids = datasample(avail_faces', n_trials_per_cate, 1);
                        objects_ids = datasample(avail_objects', n_trials_per_cate, 1);
                        letters_ids = datasample(letter_identities', n_trials_per_cate, 1);
                        false_font_ids = datasample(false_font_identities', n_trials_per_cate, 1);
                        non_tar_table.identity = [faces_ids; objects_ids; letters_ids; false_font_ids];
                    case "letter_false_font"
                        faces_ids = datasample(face_identities', n_trials_per_cate, 1);
                        objects_ids = datasample(object_identities', n_trials_per_cate, 1);
                        avail_letters = face_identities(~strcmp(letter_identities, target_1));
                        avail_falses = object_identities(~strcmp(false_font_identities, target_2));
                        letters_ids = datasample(avail_letters', n_trials_per_cate, 1);
                        false_font_ids = datasample(avail_falses', n_trials_per_cate, 1);
                        non_tar_table.identity = [faces_ids; objects_ids; letters_ids; false_font_ids];
                end
                
                % Select the number of targets:
                n_targets = datasample([2; 3; 4; 5; 6], 1, 1);
                if rand > 0.5
                    n_target_1 = round(n_targets/2);
                    n_target_2 = n_targets - n_target_1;
                else
                    n_target_2 = round(n_targets/2);
                    n_target_1 = n_targets - n_target_2;
                end
                
                % Create vectors for each categories of the targets:
                tars_task = [repmat("target", n_target_1, 1); repmat("target", n_target_2, 1)];
                tars_dur = [datasample(duration', n_target_1, 1); datasample(duration', n_target_2, 1)];
                tars_soa = [datasample(soa', n_target_1, 1); datasample(soa', n_target_2, 1)];
                tars_lock = [datasample(lock', n_target_1, 1); datasample(lock', n_target_2, 1)];
                tars_pitch = [datasample(pitch', n_target_1, 1); datasample(pitch', n_target_2, 1)];
                switch blk_type
                    case "face_object"
                        tars_cate = [datasample("face", n_target_1, 1); datasample("object", n_target_2, 1)];
                    case "letter_false_font"
                        tars_cate = [datasample("letter", n_target_1, 1); datasample("false_font", n_target_2, 1)];
                end
                identity = [repmat(cellstr(target_1), n_target_2, 1); repmat(cellstr(target_2), n_target_1, 1)];
                
                % Create the target table:
                target_table = table(tars_task, tars_dur, tars_soa, tars_lock, ...
                    tars_pitch, tars_cate, identity, ...
                    'VariableNames', ["task_relevance", "duration", "soa", "soa_lock", "pitch", "category", "identity"]);
                
                target_table.target_01 = repmat(target_1, n_targets, 1);
                target_table.target_02 = repmat(target_2, n_targets, 1);
                
                % Concatenate the tables:
                blk_table = [non_tar_table; target_table];
                % Randomize the order:
                blk_table = blk_table(datasample((1:n_trials_per_block + n_targets)', n_trials_per_block + n_targets, 1, 'Replace', false), :);
                switch blk_type
                    case "face_object"
                        blk_table.block_type = repmat("face_object", n_trials_per_block + n_targets, 1);
                    case "letter_false_font"
                        blk_table.block_type = repmat("letter_false_font", n_trials_per_block + n_targets, 1);
                end
                blk_table.block(:) = blk_ctr;
                % Add the orientations:
                blk_table.orientation = datasample(orientation', height(blk_table), 1);
                
                % If we are in the "only" conditions, set the SOA to be of
                % 2.5 secs, such that we are always at 1 sec from the last
                % visual change:
                if contains(task, "only")
                    blk_table.soa(:) = 2.5;
                end
                blk_table.trial(:) = 1:height(blk_table);
                
                % Adjust the offset locked SOA by adding the stimulus
                % duration to the SOA:
                blk_table.onset_SOA(:) = blk_table.soa(:) + (blk_table.duration(:) .* strcmp(blk_table.soa_lock(:), "offset"));
                
                % Add the jitters:
                blk_table.stim_jit = random(stim_jitter_distribution, height(blk_table), 1);
                blk_table.intro_jit = random(intro_jitter_distribution, height(blk_table), 1);
                % And the trial duration:
                if contains(task, "only")
                    blk_table.trial_duration(:) = trial_duration_1task;
                else
                    blk_table.trial_duration(:) = trial_duration_2task;
                end
                % Appending to the rest of the table:
                if blk_ctr == 1
                    subject_trial_matrix = blk_table;
                else
                    subject_trial_matrix = [subject_trial_matrix; blk_table];
                end
                blk_ctr = blk_ctr + 1;
            end
        end
        
        % Add additional information to the table:
        % Add the task to the table:
        subject_trial_matrix.task(:) = task;
        subject_trial_matrix.sub_id(:) = subject_id;
        subject_trial_matrix.is_practice(:) = 0;
        
        % Rearange the column tables:
        subject_trial_matrix = subject_trial_matrix(:, ...
            ["sub_id", "task", "is_practice", "block", "trial", "block_type", "target_01", "target_02", ...
            "task_relevance", "category", "orientation", "identity", "duration", "trial_duration", "stim_jit", "soa", "onset_SOA", "soa_lock", "pitch", "intro_jit"]);
        
        % Reorder the table according to the visual block types constrains:
        blk_order_version = mod(subject_i, 2);
        blocks = unique(subject_trial_matrix.block);
        subject_trial_matrix_new = [];
        if contains(task, "only")
            switch blk_order_version
                case 0
                    blk_type_order = [...
                        "face_object"; "face_object"; ...
                        "letter_false_font"; "letter_false_font";...
                        "letter_false_font"; "face_object"
                        ];
                case 1
                    blk_type_order = [...
                        "letter_false_font"; "letter_false_font";...
                        "face_object"; "face_object"; ...
                        "face_object"; "letter_false_font"
                        ];
            end
        else
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
        end
        % Loop through each block to reorder:
        for blk = 1:length(blocks)
           % Get the block type this block should be:
           blk_type = blk_type_order(blk);
           % Get all the blocks of this type:
           blk_type_mat = subject_trial_matrix(strcmp(subject_trial_matrix.block_type, blk_type), :);
           blk_type_num = unique(blk_type_mat.block);
           % Randomly pick one:
           sel_block_num = datasample(blk_type_num, 1,'Replace',false);
           block_mat = subject_trial_matrix(subject_trial_matrix.block == sel_block_num, :);
           if isempty(subject_trial_matrix_new)
               subject_trial_matrix_new = block_mat;
           else
               subject_trial_matrix_new = [subject_trial_matrix_new; block_mat];
           end
           % Remove from the trial matrix to avoid picking it again:
           subject_trial_matrix(subject_trial_matrix.block==sel_block_num, :) = [];
        end
        
        subject_trial_matrix = subject_trial_matrix_new;
        % Save the table to a file, in specific ways depending on the task
        % and on the subject ID:
        switch task
            case "visual_first"
                % Add the introspection:
                subject_trial_matrix.introspection(:) = true;
                % The visual first is longer, so we split it in half:
                n_blocks = subject_trial_matrix.block(end);
                ses_a_blks = subject_trial_matrix(subject_trial_matrix.block <= n_blocks/2, :);
                ses_b_blks = subject_trial_matrix(subject_trial_matrix.block > n_blocks/2, :);
                % Depending on the subject number, we change the order of
                % each task:
                ver = mod(subject_i, 3);
                if ver == 1
                    % Create the file name:
                    file_name_1 = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 1, task);
                    file_name_2 = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 2, task);
                elseif ver == 2
                    file_name_1 = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 1, task);
                    file_name_2 = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 3, task);
                elseif ver == 3
                    file_name_1 = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 2, task);
                    file_name_2 = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 3, task);
                end
                writetable(ses_a_blks, file_name_1);
                writetable(ses_b_blks, file_name_2);
            case "auditory_first"
                % Add the introspection:
                subject_trial_matrix.introspection(:) = true;
                if ver == 1
                    % Create the file name:
                    file_name = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 3, task);
                elseif ver == 2
                    file_name = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 2, task);
                elseif ver == 3
                    file_name = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, 1, task);
                end
                writetable(subject_trial_matrix, file_name);
            case "visual_only"
                subject_trial_matrix.introspection(:) = false;
                file_name = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, visual_only_ctr, task);
                writetable(subject_trial_matrix, file_name);
                visual_only_ctr = visual_only_ctr + 1;
            case "auditory_only"
                subject_trial_matrix.introspection(:) = false;
                file_name = sprintf("sub-%s_ses-%d_task-%s.csv", subject_id, audio_only_ctr, task);
                writetable(subject_trial_matrix, file_name);
                audio_only_ctr = audio_only_ctr + 1;
        end
    end
end





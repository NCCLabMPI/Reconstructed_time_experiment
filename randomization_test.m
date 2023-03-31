%% Load the matrix:
global HIGH_PITCH LOW_PITCH
HIGH_PITCH = 1000;
LOW_PITCH = 1100;
subID = 'SX111';
task_type = 'prp';

MatFolderName = [pwd,filesep,'TrialMatrices\'];
TableName = ['sub-',subID,'_task-', task_type,'_trials.csv'];
trial_mat = readtable(fullfile(MatFolderName, TableName));

% Convert the numerical column to strings, then everything is easier to
% handle:
trial_mat.duration = string(trial_mat.duration);
trial_mat.SOA = string(trial_mat.SOA);
trial_mat.pitch = string(trial_mat.pitch);
% Remove the targets:
trial_mat = trial_mat(~strcmp(trial_mat.task_relevance, 'target'), :);

% List the conditions of interest:
conditions = ["duration", "task_relevance", "SOA_lock", "SOA", "pitch"];
thresh = 2;

%% Highest level check: counting trials for each level of each condition
% Counting how many trials we have for each of these conditions:
for cond_i=1:length(conditions)
    disp('==================================')
    disp(sprintf("%s counts", conditions{cond_i}))
    % Get each level of that condition:
    cond_lvls = unique(trial_mat.(conditions{cond_i}));
    % Storing the counts for this condition:
    cts = [];
    % For each level, count how many trial we have:
    for lvl_i = 1:length(cond_lvls)
        % Extract the trials that match this level:
        tbl = trial_mat(strcmp(trial_mat.(conditions{cond_i}), cond_lvls(lvl_i)), :);
        disp(sprintf("%s counts: %d", cond_lvls{lvl_i}, size(tbl, 1)));
        cts = [cts, size(tbl, 1)];
    end
    
    % Check what differences we have:
    max_diff = max(max(bsxfun(@minus, cts, cts')));
    if max_diff > thresh
        warning(sprintf("The trials are not balanced up to threshold for %s", conditions{cond_i}))
    end
end

%% Second level check: checking balancing across pairs of experimental conditions
% Conditions combinations:
pairs = nchoosek(conditions,2);
for pair_i=1:length(pairs)
    % Get the first and second condition:
    cond_1 = pairs{pair_i, 1};
    cond_2 = pairs{pair_i, 2};
    disp('==================================')
    disp(sprintf("%s-%s counts", cond_1, cond_2))
    % Get the levels of each condition:
    cond_1_lvl = unique(trial_mat.(cond_1));
    cond_2_lvl = unique(trial_mat.(cond_2));
    cts = [];
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl = trial_mat(strcmp(trial_mat.(cond_1), cond_1_lvl{lvl_1}), :);
        % Looping through the second condition:
        for lvl_2=1:length(cond_2_lvl)
            tbl_2 = tbl(strcmp(tbl.(cond_2), cond_2_lvl{lvl_2}), :);
            disp(sprintf("%s-%s counts: %d",  cond_1_lvl{lvl_1}, cond_2_lvl{lvl_2}, size(tbl_2, 1)));
            cts = [cts, size(tbl_2, 1)];
        end
    end
    
    % Check what differences we have:
    max_diff = max(max(bsxfun(@minus, cts, cts')));
    if max_diff > thresh
        warning(sprintf("The trials are not balanced up to threshold for %s-%s counts", cond_1, cond_2))
    end
end


%% Third level check: checking balancing across pairs of experimental conditions
% Conditions combinations:
triplets = nchoosek(conditions,3);
for triplet_i=1:length(triplets)
    % Get the first and second condition:
    cond_1 = triplets{triplet_i, 1};
    cond_2 = triplets{triplet_i, 2};
    cond_3 = triplets{triplet_i, 3};
    disp('==================================')
    disp(sprintf("%s-%s-%s counts", cond_1, cond_2, cond_3))
    % Get the levels of each condition:
    cond_1_lvl = unique(trial_mat.(cond_1));
    cond_2_lvl = unique(trial_mat.(cond_2));
    cond_3_lvl = unique(trial_mat.(cond_3));
    cts = [];
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl_1 = trial_mat(strcmp(trial_mat.(cond_1), cond_1_lvl{lvl_1}), :);
        % Looping through the second condition:
        for lvl_2=1:length(cond_2_lvl)
            tbl_2 = tbl_1(strcmp(tbl_1.(cond_2), cond_2_lvl{lvl_2}), :);
            % Finally, looping through the third level:
            for lvl_3=1:length(cond_3_lvl)
                tbl_3 = tbl_2(strcmp(tbl_2.(cond_3), cond_3_lvl{lvl_3}), :);
                disp(sprintf("%s-%s-%s counts: %d",  cond_1_lvl{lvl_1}, cond_2_lvl{lvl_2}, cond_3_lvl{lvl_3}, ...
                    size(tbl_3, 1)));
                cts = [cts, size(tbl_3, 1)];
            end
        end
    end
    % Check what differences we have:
    max_diff = max(max(bsxfun(@minus, cts, cts')));
    if max_diff > thresh
        warning(sprintf("The trials are not balanced up to threshold for %s-%s-%s", cond_1, cond_2, cond_3))
    end
end


%% Fourth level check: checking balancing across pairs of experimental conditions
% Conditions combinations:
quartet = nchoosek(conditions,4);
for quintet_i=1:size(quartet, 1)
    % Get the first and second condition:
    cond_1 = quartet{quintet_i, 1};
    cond_2 = quartet{quintet_i, 2};
    cond_3 = quartet{quintet_i, 3};
    cond_4 = quartet{quintet_i, 4};
    disp('==================================')
    disp(sprintf("%s-%s-%s-%s counts", cond_1, cond_2, cond_3, cond_4))
    % Get the levels of each condition:
    cond_1_lvl = unique(trial_mat.(cond_1));
    cond_2_lvl = unique(trial_mat.(cond_2));
    cond_3_lvl = unique(trial_mat.(cond_3));
    cond_4_lvl = unique(trial_mat.(cond_4));
    cts = [];
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl_1 = trial_mat(strcmp(trial_mat.(cond_1), cond_1_lvl{lvl_1}), :);
        % Looping through the second condition:
        for lvl_2=1:length(cond_2_lvl)
            tbl_2 = tbl_1(strcmp(tbl_1.(cond_2), cond_2_lvl{lvl_2}), :);
            % Looping through the third level:
            for lvl_3=1:length(cond_3_lvl)
                tbl_3 = tbl_2(strcmp(tbl_2.(cond_3), cond_3_lvl{lvl_3}), :);
                % Looping through the 4th level:
                for lvl_4=1:length(cond_4_lvl)
                    tbl_4 = tbl_3(strcmp(tbl_3.(cond_4), cond_4_lvl{lvl_4}), :);
                    disp(sprintf("%s-%s-%s-%s counts: %d",  cond_1_lvl{lvl_1}, cond_2_lvl{lvl_2}, cond_3_lvl{lvl_3}, ...
                            cond_4_lvl{lvl_4}, size(tbl_4, 1)));
                    cts = [cts, size(tbl_4, 1)];
                end
            end
        end
    end
    % Check what differences we have:
    max_diff = max(max(bsxfun(@minus, cts, cts')));
    if max_diff > thresh
        warning(sprintf("The trials are not balanced up to threshold for %s-%s-%s-%s", cond_1, cond_2, cond_3, cond_4))
    end
end


%% Fifth level check: checking balancing across pairs of experimental conditions
% Conditions combinations:
quintets = nchoosek(conditions,5);
for quintet_i=1:size(quintets, 1)
    % Get the first and second condition:
    cond_1 = quintets{quintet_i, 1};
    cond_2 = quintets{quintet_i, 2};
    cond_3 = quintets{quintet_i, 3};
    cond_4 = quintets{quintet_i, 4};
    cond_5 = quintets{quintet_i, 5};
    disp('==================================')
    disp(sprintf("%s-%s-%s-%s-%s counts", cond_1, cond_2, cond_3, cond_4, cond_5))
    % Get the levels of each condition:
    cond_1_lvl = unique(trial_mat.(cond_1));
    cond_2_lvl = unique(trial_mat.(cond_2));
    cond_3_lvl = unique(trial_mat.(cond_3));
    cond_4_lvl = unique(trial_mat.(cond_4));
    cond_5_lvl = unique(trial_mat.(cond_5));
    cts = [];
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl_1 = trial_mat(strcmp(trial_mat.(cond_1), cond_1_lvl{lvl_1}), :);
        % Looping through the second condition:
        for lvl_2=1:length(cond_2_lvl)
            tbl_2 = tbl_1(strcmp(tbl_1.(cond_2), cond_2_lvl{lvl_2}), :);
            % Looping through the third level:
            for lvl_3=1:length(cond_3_lvl)
                tbl_3 = tbl_2(strcmp(tbl_2.(cond_3), cond_3_lvl{lvl_3}), :);
                % Looping through the 4th level:
                for lvl_4=1:length(cond_4_lvl)
                    tbl_4 = tbl_3(strcmp(tbl_3.(cond_4), cond_4_lvl{lvl_4}), :);
                    % Finally, loop through the fifth lvl:
                    for lvl_5=1:length(cond_5_lvl)
                        tbl_5 = tbl_4(strcmp(tbl_4.(cond_5), cond_5_lvl{lvl_5}), :);
                        disp(sprintf("%s-%s-%s-%s-%s counts: %d",  cond_1_lvl{lvl_1}, cond_2_lvl{lvl_2}, cond_3_lvl{lvl_3}, ...
                            cond_4_lvl{lvl_4}, cond_5_lvl{lvl_5}, size(tbl_5, 1)));
                        cts = [cts, size(tbl_5, 1)];
                    end
                end
            end
        end
    end
    % Check what differences we have:
    max_diff = max(max(bsxfun(@minus, cts, cts')));
    if max_diff > thresh
        warning(sprintf("The trials are not balanced up to threshold for %s-%s-%s-%s-%s", cond_1, cond_2, cond_3, cond_4, cond_5))
    end
end

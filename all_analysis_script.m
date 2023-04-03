
% concert table content to be valid as field names in a structur
event_table.duration = event_table.duration*1000;
event_table.SOA = event_table.SOA*1000;

% Convert the numerical column to strings, then everything is easier to
% handle:
event_table.duration = string(event_table.duration);
event_table.SOA = string(event_table.SOA);

for tr = 1: length(event_table.trial)
    if strcmp(event_table.task_relevance{tr}, 'non-target')
        event_table.task_relevance{tr} = 'non_target';
    end 
  event_table.duration{tr} = ['dur_', event_table.duration{tr}];
  event_table.SOA{tr} = ['SOA_', event_table.SOA{tr}];
end


% List the conditions of interest:
conditions = ["duration", "task_relevance", "SOA", "SOA_lock"];
measured_variable = event_table.RT_aud;

%% Highest level check: getting mean RT aud split by each condition
% Counting how many trials we have for each of these conditions:
for cond_i=1:length(conditions)
    % Get each level of that condition:
    cond_lvls = unique(event_table.(conditions{cond_i}));
    % Storing themean RT aud for this condition:
    for lvl_i = 1:length(cond_lvls)
        % Extract the trials that match this level:
        mean_struct.(conditions{cond_i}).(cond_lvls{lvl_i}) = mean(measured_variable(strcmp(event_table.(conditions{cond_i}), cond_lvls{lvl_i})));
    end
end

%% Second level check: checking balancing across pairs of experimental conditions
% Conditions combinations:
pairs = nchoosek(conditions,2);
for pair_i=1:length(pairs)
    % Get the first and second condition:
    cond_1 = pairs{pair_i, 1};
    cond_2 = pairs{pair_i, 2};
    sub_folder = sprintf("%s_%s", cond_1, cond_2);
    % Get the levels of each condition:
    cond_1_lvl = unique(event_table.(cond_1));
    cond_2_lvl = unique(event_table.(cond_2));
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl = event_table(strcmp(event_table.(cond_1), cond_1_lvl{lvl_1}), :);
        % Looping through the second condition:
        for lvl_2=1:length(cond_2_lvl)
            mean_struct.(sub_folder).(cond_1_lvl{lvl_1}).(cond_2_lvl{lvl_2}) ...
                = mean(measured_variable(strcmp(event_table.(conditions{lvl_1}), (cond_1_lvl{lvl_1})) & ...
                strcmp(event_table.(conditions{lvl_2}), (cond_2_lvl{lvl_2}))));

% 
%             tbl_2 = tbl(strcmp(tbl.(cond_2), cond_2_lvl{lvl_2}), :);
%             disp(sprintf("%s-%s counts: %d",  cond_1_lvl{lvl_1}, cond_2_lvl{lvl_2}, size(tbl_2, 1)));
%             cts = [cts, size(tbl_2, 1)];
        end
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
    cond_1_lvl = unique(event_table.(cond_1));
    cond_2_lvl = unique(event_table.(cond_2));
    cond_3_lvl = unique(event_table.(cond_3));
    cts = [];
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl_1 = event_table(strcmp(event_table.(cond_1), cond_1_lvl{lvl_1}), :);
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
    cond_1_lvl = unique(event_table.(cond_1));
    cond_2_lvl = unique(event_table.(cond_2));
    cond_3_lvl = unique(event_table.(cond_3));
    cond_4_lvl = unique(event_table.(cond_4));
    cts = [];
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl_1 = event_table(strcmp(event_table.(cond_1), cond_1_lvl{lvl_1}), :);
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
    cond_1_lvl = unique(event_table.(cond_1));
    cond_2_lvl = unique(event_table.(cond_2));
    cond_3_lvl = unique(event_table.(cond_3));
    cond_4_lvl = unique(event_table.(cond_4));
    cond_5_lvl = unique(event_table.(cond_5));
    cts = [];
    % Looping through each level of the first condition:
    for lvl_1 = 1:length(cond_1_lvl)
        % Extract only this condition level from the table:
        tbl_1 = event_table(strcmp(event_table.(cond_1), cond_1_lvl{lvl_1}), :);
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

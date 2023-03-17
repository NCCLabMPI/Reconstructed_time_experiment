function [log_table, performance_struct] = compute_performance(log_table)

disp('WELCOME TO compute_performance')

global LOW_PITCH_KEY HIGH_PITCH_KEY

performance_struct.misses = 0;
performance_struct.hits = 0;
performance_struct.fa = 0;
performance_struct.cr = 0; % correct rejection

log_table = log_table(~isnan(log_table.texture), :);

for tr = 1:length(log_table.trial)


        % compute correctness visual task
        if strcmp(log_table.task_relevance{tr}, 'target') && log_table.has_repsonse_vis(tr) == 1
            performance_struct.hits = performance_struct.hits + 1;
            log_table.trial_repsonse_vis{tr} ='hit';
        elseif ~strcmp(log_table.task_relevance{tr}, 'target') && log_table.has_repsonse_vis(tr) == 1
            performance_struct.fa = performance_struct.fa + 1;
            log_table.trial_repsonse_vis{tr} ='fa';
        elseif ~strcmp(log_table.task_relevance{tr}, 'target') && log_table.has_repsonse_vis(tr) == 0
            performance_struct.cr = performance_struct.cr + 1;
            log_table.trial_repsonse_vis{tr} ='cr';
        else
            log_table.trial_repsonse_vis{tr} ='miss';
            performance_struct.misses = performance_struct.misses + 1;
        end

        % extract auditory response
        if log_table.trial_first_button_press(tr) >= 1000 
            log_table.aud_resp(tr) = log_table.trial_first_button_press(tr);
        elseif log_table.trial_second_button_press(tr) >= 1000
            log_table.aud_resp(tr) = log_table.trial_second_button_press(tr);
        else  
            log_table.aud_resp(tr) = 0; % No auditory response was provided
        end 

        % compute correctness auditory task
        if (log_table.aud_resp(tr) == LOW_PITCH_KEY && strcmp(log_table.pitch{tr},'low')) ||...
                (log_table.aud_resp(tr) == HIGH_PITCH_KEY && strcmp(log_table.pitch{tr},'high'))
            log_table.trial_accuracy_aud(tr) = 1;

        elseif (log_table.aud_resp(tr) == HIGH_PITCH_KEY && strcmp(log_table.pitch{tr},'low')) ||...
                (log_table.aud_resp(tr) == LOW_PITCH_KEY && strcmp(log_table.pitch{tr},'high'))
            log_table.trial_accuracy_aud(tr) = 0;
        else
            log_table.trial_accuracy_aud(tr) = nan;
        end


end
performance_struct.aud_mean_accuracy = mean(log_table.trial_accuracy_aud, 'omitnan');
end

% log_table.has_repsonse_vis(:) = 0;
% for tr = 1:length(log_table.trial)
%     if log_table.trial_first_button_press(tr) == 1 || log_table.trial_second_button_press(tr) == 1
%         log_table.has_repsonse_vis(tr) = 1;
%     end
% end
